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
import 'package:presentum/src/controller/transitions.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

@internal
final class Presentum$EngineImpl<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements Presentum<TItem, S, V> {
  factory Presentum$EngineImpl({
    PresentumStorage<S, V>? storage,
    List<IPresentumEventHandler<TItem, S, V>>? eventHandlers,
    List<IPresentumTransitionObserver<TItem, S, V>>? transitionObservers,
    Map<S, PresentumSlot<TItem, S, V>>? slots,
    List<IPresentumGuard<TItem, S, V>>? guards,
    PresentumState<TItem, S, V>? initialState,
    List<PresentumHistoryEntry<TItem, S, V>>? history,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final resolvedStorage = storage ?? NoOpPresentumStorage<S, V>();
    final resolvedEventHandlers =
        eventHandlers ?? <IPresentumEventHandler<TItem, S, V>>[];
    final observer = PresentumStateObserver$EngineImpl(
      initialState?.freeze() ??
          PresentumState$Immutable<TItem, S, V>(
            slots: slots ?? <S, PresentumSlot<TItem, S, V>>{},
            intention: PresentumStateIntention.auto,
          ),
      history,
    );
    final engine = PresentumEngine$Impl(
      observer: observer,
      guards: guards,
      transitionObservers: transitionObservers,
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
    required List<IPresentumEventHandler<TItem, S, V>> eventHandlers,
    required PresentumEngine$Impl<TItem, S, V> engine,
    required PresentumStateObserver<TItem, S, V> observer,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : config = PresentumConfig<TItem, S, V>(
         storage: storage,
         observer: observer,
         engine: engine,
       ),
       _engine = engine,
       _eventHandlers = eventHandlers,
       _onError = onError;

  @override
  final PresentumConfig<TItem, S, V> config;

  final PresentumEngine$Impl<TItem, S, V> _engine;
  final List<IPresentumEventHandler<TItem, S, V>> _eventHandlers;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  @override
  PresentumStateObserver<TItem, S, V> get observer => config.observer;

  @override
  PresentumState$Immutable<TItem, S, V> get state => observer.value;

  @override
  List<PresentumHistoryEntry<TItem, S, V>> get history => observer.history;

  @override
  bool get isIdle => !isProcessing;

  @override
  bool get isProcessing => _engine.isProcessing;

  @override
  Future<void> get processingCompleted => _engine.processingCompleted;

  @override
  Future<void> setState(
    PresentumState<TItem, S, V> Function(
      PresentumState$Mutable<TItem, S, V> state,
    )
    change,
  ) => _engine.setNewPresentationState(
    change(state.mutate()..intention = PresentumStateIntention.auto),
  );

  @override
  Future<void> pushSlot(S surface, {required TItem item}) =>
      setState((state) => state..add(surface, item));

  @override
  Future<void> pushAllSlots(List<({S surface, TItem item})> items) =>
      setState((state) {
        for (final item in items) {
          state.add(item.surface, item.item);
        }
        return state;
      });

  Completer<void>? _txnCompleter;
  final Queue<
    (
      PresentumState<TItem, S, V> Function(PresentumState$Mutable<TItem, S, V>),
      int,
    )
  >
  _txnQueue =
      Queue<
        (
          PresentumState<TItem, S, V> Function(
            PresentumState$Mutable<TItem, S, V>,
          ),
          int,
        )
      >();

  @override
  Future<void> transaction(
    PresentumState<TItem, S, V> Function(PresentumState$Mutable<TItem, S, V>)
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
              final PresentumState$Mutable<TItem, S, V> state => state,
              final PresentumState$Immutable<TItem, S, V> state =>
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
  Future<void> addEvent(PresentumEvent<TItem, S, V> event) async {
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
  Future<void> markShown(TItem item) async {
    final event = PresentumShownEvent<TItem, S, V>(
      item: item,
      timestamp: DateTime.now(),
    );
    await addEvent(event);
  }

  @override
  Future<void> markDismissed(TItem item) async {
    final event = PresentumDismissedEvent<TItem, S, V>(
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
    TItem item, {
    Map<String, Object?>? conversionMetadata,
  }) async {
    final event = PresentumConvertedEvent<TItem, S, V>(
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
