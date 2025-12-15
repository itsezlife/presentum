import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:presentum/src/controller/config.dart';
import 'package:presentum/src/controller/controller.dart';
import 'package:presentum/src/controller/engine/engine.dart';
import 'package:presentum/src/controller/engine/observer.dart';
import 'package:presentum/src/controller/events.dart';
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
    PresentumStorage<S, V>? storage,
    List<IPresentumEventHandler<TResolved, S, V>>? eventHandlers,
    Map<S, PresentumSlot<TResolved, S, V>>? slots,
    List<IPresentumGuard<TResolved, S, V>>? guards,
    PresentumState<TResolved, S, V>? initialState,
    List<PresentumHistoryEntry<TResolved, S, V>>? history,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final resolvedStorage = storage ?? NoOpPresentumStorage<S, V>();
    final resolvedEventHandlers =
        eventHandlers ?? <IPresentumEventHandler<TResolved, S, V>>[];
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
      storage: resolvedStorage,
      onError: onError,
    );
    final controller = Presentum$EngineImpl._(
      storage: resolvedStorage,
      eventHandlers: resolvedEventHandlers,
      observer: observer,
      engine: engine,
      onError: onError,
    );
    engine.$presentum = WeakReference(controller);
    return controller;
  }

  Presentum$EngineImpl._({
    required PresentumStorage<S, V> storage,
    required List<IPresentumEventHandler<TResolved, S, V>> eventHandlers,
    required PresentumEngine$Impl<TResolved, S, V> engine,
    required PresentumStateObserver<TResolved, S, V> observer,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : config = PresentumConfig<TResolved, S, V>(
         storage: storage,
         observer: observer,
         engine: engine,
       ),
       _engine = engine,
       _eventHandlers = eventHandlers,
       _onError = onError;

  @override
  final PresentumConfig<TResolved, S, V> config;

  final PresentumEngine$Impl<TResolved, S, V> _engine;
  final List<IPresentumEventHandler<TResolved, S, V>> _eventHandlers;
  final void Function(Object error, StackTrace stackTrace)? _onError;

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
  Future<void> addEvent(PresentumEvent<TResolved, S, V> event) async {
    // If the event was added, but no event handlers are registered,
    // log a warning.
    if (_eventHandlers.isEmpty) {
      dev.log(
        'Event $event was added but no event handlers are registered',
        name: 'presentum',
        level: 500,
        stackTrace: StackTrace.current,
      );
    }

    // Handle the event with all registered event handlers.
    for (final handler in _eventHandlers) {
      try {
        await handler(event);
      } on Object catch (error, stackTrace) {
        dev.log(
          'Event handler ${handler.runtimeType} failed to handle event: $event',
          name: 'presentum',
          error: error,
          stackTrace: stackTrace,
          level: 1000,
        );
        _onError?.call(error, stackTrace);
        // Don't return, continue handling other event handlers.
      }
    }
  }

  @override
  Future<void> markShown(TResolved item) async {
    final event = PresentumShownEvent<TResolved, S, V>(
      item: item,
      timestamp: DateTime.now(),
    );
    await addEvent(event);
  }

  @override
  Future<void> markDismissed(TResolved item) async {
    final event = PresentumDismissedEvent<TResolved, S, V>(
      item: item,
      timestamp: DateTime.now(),
    );
    await addEvent(event);

    await setState(
      (state) =>
          state
            ..removeFromSurface(item.surface, (entry) => entry.id == item.id),
    );
  }

  @override
  Future<void> markConverted(
    TResolved item, {
    Map<String, Object?>? conversionMetadata,
  }) async {
    final event = PresentumConvertedEvent<TResolved, S, V>(
      item: item,
      timestamp: DateTime.now(),
      conversionMetadata: conversionMetadata,
    );
    await addEvent(event);
  }

  @override
  Future<void> removeById(String id, {S? surface}) =>
      setState((state) => state..removeById(id, surface: surface));
}
