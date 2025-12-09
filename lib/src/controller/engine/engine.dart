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
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentation.dart';

/// Presentum engine.
@internal
final class PresentumEngine$Impl<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    extends PresentumEngine<TResolved, S>
    with ChangeNotifier {
  PresentumEngine$Impl({
    required PresentumStateObserver$EngineImpl<TResolved, S> observer,
    required PresentumStorage storage,
    List<IPresentumGuard<TResolved, S>>? guards,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _observer = observer,
       _storage = storage,
       _guards =
           guards?.toList(growable: false) ?? <IPresentumGuard<TResolved, S>>[],
       _onError = onError {
    // Subscribe to the guards.
    _guardsListener = Listenable.merge(_guards)..addListener(_onGuardsNotified);
    // Revalidate the initial state with the guards.
    _setState(observer.value);
  }

  /// State observer.
  final PresentumStateObserver$EngineImpl<TResolved, S> _observer;

  /// The storage used by the presentum.
  final PresentumStorage _storage;

  /// Error handler.
  final void Function(Object error, StackTrace stackTrace)? _onError;

  /// Current presentum instance.
  @internal
  late WeakReference<Presentum<TResolved, S>> $presentum;

  /// Guards.
  final List<IPresentumGuard<TResolved, S>> _guards;
  late final Listenable _guardsListener;

  /// Candidates.
  List<TResolved> _candidates = <TResolved>[];

  @override
  List<TResolved> get currentCandidates =>
      List<TResolved>.unmodifiable(_candidates);

  @override
  FutureOr<void> setCandidates(
    List<TResolved> Function(
      PresentumState$Mutable<TResolved, S> state,
      List<TResolved> currentCandidates,
    )
    candidates,
  ) async {
    final mutableState = _observer.value.mutate()
      ..intention = PresentumStateIntention.auto;
    _candidates = candidates(mutableState, _candidates);
    await setNewPresentationState(mutableState);
  }

  /// State change queue.
  late final PresentumStateQueue<TResolved, S> _$stateChangeQueue =
      PresentumStateQueue<TResolved, S>(processor: _setState);

  @override
  bool get isProcessing => _$stateChangeQueue.isProcessing;

  @override
  Future<void> get processingCompleted =>
      _$stateChangeQueue.processingCompleted;

  /// Current state.
  @override
  PresentumState$Immutable<TResolved, S> get currentState => _observer.value;

  /// State observer,
  /// which can be used to listen to changes in the [PresentumState].
  PresentumStateObserver<TResolved, S> get observer => _observer;

  /// The storage used by the presentation engine.
  PresentumStorage get storage => _storage;

  @override
  Widget build(BuildContext context, Widget child) =>
      InheritedPresentum(presentum: $presentum.target!, child: child);

  Future<void> _onGuardsNotified() => setNewPresentationState(
    _observer.value.mutate()..intention = PresentumStateIntention.replace,
  );

  @override
  Future<void> setNewPresentationState(PresentumState<TResolved, S> state) =>
      _$stateChangeQueue.add(state);

  Future<void> _setState(PresentumState<TResolved, S> state) async {
    // Do nothing:
    if (state.intention == PresentumStateIntention.cancel) return;

    // Create a mutable copy of the state
    // to allow changing it in the guards
    var newState = state is PresentumState$Mutable<TResolved, S>
        ? state
        : state.mutate();

    if (_guards.isNotEmpty) {
      // Get the history of the states
      final history = _observer.history;
      final candidates = List<TResolved>.unmodifiable(_candidates);

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
    if (_observer.changeState(result)) {
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
