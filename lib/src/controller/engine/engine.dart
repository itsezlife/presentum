import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/controller/engine.dart';
import 'package:presentum/src/controller/engine/observer.dart';
import 'package:presentum/src/controller/guard.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/controller/state_queue.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/controller/transitions.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/utils/diff_util_helpers.dart';
import 'package:presentum/src/widgets/inherited_presentum.dart';

/// Presentum engine.
@internal
final class PresentumEngine$Impl<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumEngine<TItem, S, V>
    with ChangeNotifier {
  PresentumEngine$Impl({
    required PresentumStateObserver$EngineImpl<TItem, S, V> observer,
    required PresentumStorage<S, V> storage,
    List<IPresentumGuard<TItem, S, V>>? guards,
    List<IPresentumTransitionObserver<TItem, S, V>>? transitionObservers,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _observer = observer,
       _storage = storage,
       _guards =
           guards?.toList(growable: false) ?? <IPresentumGuard<TItem, S, V>>[],
       _transitionObservers =
           transitionObservers?.toList(growable: false) ??
           <IPresentumTransitionObserver<TItem, S, V>>[],
       _onError = onError {
    // Subscribe to the guards.
    _guardsListener = Listenable.merge(_guards)..addListener(_onGuardsNotified);
    // Revalidate the initial state with the guards.
    _setState(observer.value);
  }

  /// State observer.
  final PresentumStateObserver$EngineImpl<TItem, S, V> _observer;

  /// The storage used by the presentum.
  final PresentumStorage<S, V> _storage;

  /// Error handler.
  final void Function(Object error, StackTrace stackTrace)? _onError;

  /// Current presentum instance.
  @internal
  late WeakReference<Presentum<TItem, S, V>> $presentum;

  /// Guards.
  final List<IPresentumGuard<TItem, S, V>> _guards;
  late final Listenable _guardsListener;

  /// Transition observers.
  final List<IPresentumTransitionObserver<TItem, S, V>> _transitionObservers;

  /// Candidates.
  List<TItem> _candidates = <TItem>[];

  @override
  List<TItem> get currentCandidates => List<TItem>.unmodifiable(_candidates);

  @override
  FutureOr<void> setCandidates(
    List<TItem> Function(
      PresentumState$Mutable<TItem, S, V> state,
      List<TItem> currentCandidates,
    )
    candidates,
  ) async {
    final mutableState = _observer.value.mutate()
      ..intention = PresentumStateIntention.auto;
    _candidates = candidates(mutableState, List.from(_candidates));
    await setNewPresentationState(mutableState);
  }

  @override
  FutureOr<void> setCandidatesWithDiff(
    List<TItem> Function(PresentumState$Mutable<TItem, S, V> state)
    newCandidates, {
    Object? Function(TItem item)? getId,
    bool Function(TItem oldItem, TItem newItem)? customContentsComparison,
    void Function(int position, List<TItem> newItems)? inserted,
    void Function(int position, int count)? removed,
    void Function(int position, int count, TItem? payload)? changed,
  }) async {
    final mutableState = _observer.value.mutate()
      ..intention = PresentumStateIntention.auto;
    final candidates = newCandidates(mutableState);

    final oldList = List<TItem>.from(_candidates);
    final updatedList = List<TItem>.from(_candidates);

    DiffUtils.calculateListDiffOperations(
      oldList,
      candidates,
      (item) {
        if (getId case final id?) {
          return id(item);
        }
        return item.id;
      },
      customContentsComparison: (oldItem, newItem) {
        if (customContentsComparison case final comparison?) {
          return comparison(oldItem, newItem);
        }

        final oldVariant = oldItem.option;
        final newVariant = newItem.option;

        // Return false if change was detected
        if (oldVariant.surface != newVariant.surface) return false;
        if (oldVariant.variant != newVariant.variant) return false;
        if (oldVariant.stage != newVariant.stage) return false;
        if (oldVariant.maxImpressions != newVariant.maxImpressions) {
          return false;
        }
        if (oldVariant.cooldownMinutes != newVariant.cooldownMinutes) {
          return false;
        }
        if (oldVariant.isDismissible != newVariant.isDismissible) {
          return false;
        }
        if (oldVariant.alwaysOnIfEligible != newVariant.alwaysOnIfEligible) {
          return false;
        }

        // No changes, return true
        return true;
      },
      detectMoves: false, // we don't care about moves
      inserted: (position, count) {
        final data = candidates.sublist(position, position + count);
        updatedList.insertAll(position, data);
        if (inserted case final inserted?) {
          inserted(position, data);
        }
      },
      removed: (position, count) {
        updatedList.removeRange(position, position + count);
        if (removed case final removed?) {
          removed(position, count);
        }
      },
      changed: (position, count, payload) {
        if (payload case final TItem payload?) {
          updatedList[position] = payload;
          if (changed case final changed?) {
            changed(position, count, payload);
          }
        }
      },
    ).clear();

    _candidates = updatedList;
    await setNewPresentationState(mutableState);
  }

  /// State change queue.
  late final PresentumStateQueue<TItem, S, V> _$stateChangeQueue =
      PresentumStateQueue<TItem, S, V>(processor: _setState);

  @override
  bool get isProcessing => _$stateChangeQueue.isProcessing;

  @override
  Future<void> get processingCompleted =>
      _$stateChangeQueue.processingCompleted;

  /// Current state.
  @override
  PresentumState$Immutable<TItem, S, V> get currentState => _observer.value;

  /// State observer,
  /// which can be used to listen to changes in the [PresentumState].
  PresentumStateObserver<TItem, S, V> get observer => _observer;

  @override
  Widget build(BuildContext context, Widget child) =>
      InheritedPresentum(presentum: $presentum.target!, child: child);

  Future<void> _onGuardsNotified() => setNewPresentationState(
    _observer.value.mutate()..intention = PresentumStateIntention.replace,
  );

  @override
  Future<void> setNewPresentationState(PresentumState<TItem, S, V> state) =>
      _$stateChangeQueue.add(state);

  Future<void> _setState(PresentumState<TItem, S, V> state) async {
    // Do nothing:
    if (state.intention == PresentumStateIntention.cancel) return;

    // Create a mutable copy of the state
    // to allow changing it in the guards
    var newState = state is PresentumState$Mutable<TItem, S, V>
        ? state
        : state.mutate();

    if (_guards.isNotEmpty) {
      // Get the history of the states
      final history = _observer.history;
      final candidates = List<TItem>.unmodifiable(_candidates);

      // Unsubscribe from the guards to avoid infinite loop.
      _guardsListener.removeListener(_onGuardsNotified);
      final context = <String, Object?>{};

      for (final guard in _guards) {
        try {
          final result = await guard(
            _storage,
            history,
            newState,
            candidates,
            context,
          );
          newState = result.mutate();
          if (newState.intention == PresentumStateIntention.cancel) return;
        } on Object catch (error, stackTrace) {
          dev.log(
            'Guard ${guard.runtimeType} failed',
            name: 'presentum',
            error: error,
            stackTrace: stackTrace,
            level: 1000,
          );
          _onError?.call(error, stackTrace);
          return; // Cancel evaluation if the guard failed.
        }
      }

      // Re‑subscribe to the guards.
      _guardsListener.addListener(_onGuardsNotified);
    }

    // Validate configuration: at least one slot must be present.
    // if (newState.slots.isEmpty) return;

    final result = newState.freeze();
    final oldStateSnapshot = _observer.value;

    if (_observer.changeState(result)) {
      // Fire transition observers AFTER state commits but BEFORE
      // notifyListeners
      if (_transitionObservers.isNotEmpty) {
        final transition = PresentumStateTransition<TItem, S, V>(
          oldState: oldStateSnapshot,
          newState: result,
          timestamp: DateTime.now(),
        );

        for (final observer in _transitionObservers) {
          try {
            await observer(transition);
          } on Object catch (error, stackTrace) {
            dev.log(
              'Transition observer ${observer.runtimeType} failed',
              name: 'presentum',
              error: error,
              stackTrace: stackTrace,
              level: 1000,
            );
            _onError?.call(error, stackTrace);
            // Continue with other observers even if one fails
          }
        }
      }

      notifyListeners();
    }
  }

  @override
  void dispose() {
    _guardsListener.removeListener(_onGuardsNotified);
    _$stateChangeQueue.close();
    super.dispose();
  }
}
