import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/config.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/controller/engine/engine.dart';
import 'package:presentum/src/controller/engine/observer.dart';
import 'package:presentum/src/controller/guard.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

@internal
final class Presentum$EngineImpl<
  TResolved extends ResolvedPresentumVariant<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements Presentum<TResolved, S, V> {
  factory Presentum$EngineImpl({
    required PresentumStorage storage,
    Map<S, PresentumSlot<TResolved, S, V>>? slots,
    List<IPresentumGuard<TResolved, S, V>>? guards,
    PresentumState<TResolved, S, V>? initialState,
    List<PresentumHistoryEntry<TResolved, S, V>>? history,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final observer = PresentumStateObserver$EngineImpl(
      initialState?.freeze() ??
          PresentumState$Immutable<TResolved, S, V>(
            slots: slots ?? <S, PresentumSlot<TResolved, S, V>>{},
            intention: PresentumStateIntention.auto,
          ),
      history,
    );
    final engine = PresentumEngine$Impl(
      observer: observer,
      guards: guards,
      storage: storage,
      onError: onError,
    );
    final controller = Presentum$EngineImpl._(
      storage: storage,
      observer: observer,
      engine: engine,
    );
    engine.$presentum = WeakReference(controller);
    return controller;
  }

  Presentum$EngineImpl._({
    required PresentumStorage storage,
    required PresentumEngine$Impl<TResolved, S, V> engine,
    required PresentumStateObserver<TResolved, S, V> observer,
  }) : config = PresentumConfig<TResolved, S, V>(
         storage: storage,
         observer: observer,
         engine: engine,
       ),
       _engine = engine,
       _storage = storage;

  @override
  final PresentumConfig<TResolved, S, V> config;

  final PresentumEngine$Impl<TResolved, S, V> _engine;
  final PresentumStorage _storage;

  @override
  PresentumStateObserver<TResolved, S, V> get observer => config.observer;

  @override
  PresentumState$Immutable<TResolved, S, V> get state => observer.value;

  @override
  List<PresentumHistoryEntry<TResolved, S, V>> get history => observer.history;

  @override
  bool get isIdle => !isProcessing;

  @override
  bool get isProcessing => _engine.isProcessing;

  @override
  Future<void> get processingCompleted => _engine.processingCompleted;

  @override
  Future<void> setState(
    PresentumState<TResolved, S, V> Function(
      PresentumState$Mutable<TResolved, S, V> state,
    )
    change,
  ) => _engine.setNewPresentationState(
    change(state.mutate()..intention = PresentumStateIntention.auto),
  );

  @override
  Future<void> pushSlot(S surface, {required TResolved item}) =>
      setState((state) => state..add(surface, item));

  @override
  Future<void> pushAllSlots(List<({S surface, TResolved item})> items) =>
      setState((state) {
        for (final item in items) {
          state.add(item.surface, item.item);
        }
        return state;
      });

  Completer<void>? _txnCompleter;
  final Queue<
    (
      PresentumState<TResolved, S, V> Function(
        PresentumState$Mutable<TResolved, S, V>,
      ),
      int,
    )
  >
  _txnQueue =
      Queue<
        (
          PresentumState<TResolved, S, V> Function(
            PresentumState$Mutable<TResolved, S, V>,
          ),
          int,
        )
      >();

  @override
  Future<void> transaction(
    PresentumState<TResolved, S, V> Function(
      PresentumState$Mutable<TResolved, S, V>,
    )
    change, {
    int? priority,
  }) async {
    Completer<void> completer;
    if (_txnCompleter == null || _txnCompleter!.isCompleted) {
      completer = _txnCompleter = Completer<void>.sync();
      Future<void>.delayed(Duration.zero, () {
        var mutableState = state.mutate()
          ..intention = PresentumStateIntention.auto;
        final list = _txnQueue.toList(growable: false)
          ..sort((a, b) => b.$2.compareTo(a.$2));
        _txnQueue.clear();
        for (final fn in list) {
          try {
            mutableState = switch (fn.$1(mutableState)) {
              final PresentumState$Mutable<TResolved, S, V> state => state,
              final PresentumState$Immutable<TResolved, S, V> state =>
                state.mutate(),
            };
          } on Object {
            /* ignore */
          }
        }
        setState((_) => mutableState);
        if (completer.isCompleted) return;
        completer.complete();
      });
    } else {
      completer = _txnCompleter!;
    }
    priority ??= _txnQueue.fold<int>(0, (p, e) => math.min(p, e.$2)) - 1;
    _txnQueue.add((change, priority));
    return completer.future;
  }

  @override
  Future<void> markShown(TResolved item) async {
    final surface = item.surface;
    final variant = item.visualVariant;
    await _storage.recordShown(
      item.id,
      surface: surface,
      variant: variant,
      at: DateTime.now(),
    );
  }

  @override
  Future<void> markDismissed(TResolved item) async {
    final surface = item.surface;
    final variant = item.visualVariant;
    await _storage.recordDismissed(item.id, surface: surface, variant: variant);

    await setState(
      (state) =>
          state..removeFromSurface(surface, (entry) => entry.id == item.id),
    );
  }

  @override
  Future<void> markConverted(TResolved item) async {
    final surface = item.surface;
    final variant = item.visualVariant;
    await _storage.recordConverted(
      item.id,
      surface: surface,
      variant: variant,
      at: DateTime.now(),
    );
  }

  @override
  Future<void> removeById(String id, {S? surface}) =>
      setState((state) => state..removeById(id, surface: surface));
}
