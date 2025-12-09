import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/bindings.dart';
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
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    implements Presentum<TResolved, S> {
  factory Presentum$EngineImpl({
    required PresentumStorage storage,
    required PresentumBindings<TResolved, S> bindings,
    Map<S, PresentumSlot<TResolved, S>>? slots,
    List<IPresentumGuard<TResolved, S>>? guards,
    PresentumState<TResolved, S>? initialState,
    List<PresentumHistoryEntry<TResolved, S>>? history,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final observer = PresentumStateObserver$EngineImpl(
      initialState?.freeze() ??
          PresentumState$Immutable<TResolved, S>(
            slots: slots ?? <S, PresentumSlot<TResolved, S>>{},
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
      bindings: bindings,
      engine: engine,
    );
    engine.$presentum = WeakReference(controller);
    return controller;
  }

  Presentum$EngineImpl._({
    required PresentumStorage storage,
    required PresentumBindings<TResolved, S> bindings,
    required PresentumEngine$Impl<TResolved, S> engine,
    required PresentumStateObserver<TResolved, S> observer,
  }) : config = PresentumConfig<TResolved, S>(
         storage: storage,
         observer: observer,
         engine: engine,
       ),
       _engine = engine,
       _bindings = bindings,
       _storage = storage;

  @override
  final PresentumConfig<TResolved, S> config;

  final PresentumEngine$Impl<TResolved, S> _engine;
  final PresentumBindings<TResolved, S> _bindings;
  final PresentumStorage _storage;

  @override
  PresentumStateObserver<TResolved, S> get observer => config.observer;

  @override
  PresentumState$Immutable<TResolved, S> get state => observer.value;

  @override
  List<PresentumHistoryEntry<TResolved, S>> get history => observer.history;

  @override
  bool get isIdle => !isProcessing;

  @override
  bool get isProcessing => _engine.isProcessing;

  @override
  Future<void> get processingCompleted => _engine.processingCompleted;

  @override
  Future<void> setState(
    PresentumState<TResolved, S> Function(
      PresentumState$Mutable<TResolved, S> state,
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
      PresentumState<TResolved, S> Function(
        PresentumState$Mutable<TResolved, S>,
      ),
      int,
    )
  >
  _txnQueue =
      Queue<
        (
          PresentumState<TResolved, S> Function(
            PresentumState$Mutable<TResolved, S>,
          ),
          int,
        )
      >();

  @override
  Future<void> transaction(
    PresentumState<TResolved, S> Function(PresentumState$Mutable<TResolved, S>)
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
              final PresentumState$Mutable<TResolved, S> state => state,
              final PresentumState$Immutable<TResolved, S> state =>
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
    final surface = _bindings.surfaceOf(item);
    final variant = _bindings.variantOf(item);
    await _storage.recordShown(
      item.id,
      surface: surface,
      variant: variant,
      at: DateTime.now(),
    );
  }

  @override
  Future<void> markDismissed(TResolved item) async {
    final surface = _bindings.surfaceOf(item);
    final variant = _bindings.variantOf(item);
    final until =
        surface.dismissedUntilDuration(DateTime.now(), item) ??
        dismissUntilForever;
    await _storage.recordDismissed(
      item.id,
      surface: surface,
      variant: variant,
      // TODO(campaigns): find a way to provide per variant/surface dismiss until.
      until: until,
    );

    await setState(
      (state) =>
          state..removeFromSurface(surface, (entry) => entry.id == item.id),
    );
  }

  @override
  Future<void> markConverted(TResolved item) async {
    final surface = _bindings.surfaceOf(item);
    final variant = _bindings.variantOf(item);
    await _storage.recordConverted(
      item.id,
      surface: surface,
      variant: variant,
      at: DateTime.now(),
    );
  }

  TResolved? _findById(Object id) =>
      state.foldSlots<TResolved?>(null, (found, surface, slot) {
        if (found != null) return found;
        final active = slot.active;
        if (active != null && active.id == id) return active;
        for (final item in slot.queue) {
          if (item.id == id) return item;
        }
        return null;
      });

  @override
  Future<void> removeById(String id, {S? surface}) =>
      setState((state) => state..removeById(id, surface: surface));

  @override
  Future<void> markShownById(Object id) async {
    final item = _findById(id);
    if (item == null) return;
    await markShown(item);
  }

  @override
  Future<void> markDismissedById(Object id) async {
    final item = _findById(id);
    if (item == null) return;
    await markDismissed(item);
  }

  @override
  Future<void> markConvertedById(Object id) async {
    final item = _findById(id);
    if (item == null) return;
    await markConverted(item);
  }
}
