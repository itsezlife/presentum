import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:presentum/src/controller/config.dart';
import 'package:presentum/src/controller/engine/controller.dart';
import 'package:presentum/src/controller/events.dart';
import 'package:presentum/src/controller/guard.dart';
import 'package:presentum/src/controller/observer.dart';
import 'package:presentum/src/controller/storage.dart';
import 'package:presentum/src/controller/transitions.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';
import 'package:presentum/src/widgets/inherited_presentum.dart';

/// {@template presentum}
/// The main class of the package.
/// {@endtemplate}
abstract interface class Presentum<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// Creates a new [Presentum] instance.
  /// 
  /// If [storage] is not provided, the [NoOpPresentumStorage] will be used.
  /// {@macro presentum}
  factory Presentum({
    PresentumStorage<S, V>? storage,
    List<IPresentumEventHandler<TItem, S, V>>? eventHandlers,
    List<IPresentumTransitionObserver<TItem, S, V>>? transitionObservers,
    Map<S, PresentumSlot<TItem, S, V>>? slots,
    List<IPresentumGuard<TItem, S, V>>? guards,
    PresentumState<TItem, S, V>? initialState,
    List<PresentumHistoryEntry<TItem, S, V>>? history,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) = Presentum$EngineImpl;

  /// Receives the [Presentum] instance from the elements tree.
  static Presentum<TItem, S, V>? maybeOf<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context) => InheritedPresentum.maybeOf<TItem, S, V>(
    context,
    listen: false,
  )?.presentum;

  /// Receives the [Presentum] instance from the elements tree.
  static Presentum<TItem, S, V> of<
    TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
    S extends PresentumSurface,
    V extends PresentumVisualVariant
  >(BuildContext context) =>
      InheritedPresentum.of<TItem, S, V>(context, listen: false).presentum;

  /// Configuration of the [Presentum].
  abstract final PresentumConfig<TItem, S, V> config;

  /// State observer,
  /// which can be used to listen to changes in the [PresentumState].
  PresentumStateObserver<TItem, S, V> get observer;

  /// Current state.
  PresentumState$Immutable<TItem, S, V> get state;

  /// History of the [PresentumState] states.
  List<PresentumHistoryEntry<TItem, S, V>> get history;

  /// Completes when processing queue is empty
  /// and all transactions are completed.
  /// This is mean controller is ready to use and in a idle state.
  Future<void> get processingCompleted;

  /// Whether the controller is currently processing a tasks.
  bool get isProcessing;

  /// Whether the controller is currently idle.
  bool get isIdle;

  /// Set new state and rebuild the navigation tree if needed.
  ///
  /// Better to use [transaction] method to change multiple states
  /// at once synchronously at the same time and merge changes into transaction.
  Future<void> setState(
    PresentumState<TItem, S, V> Function(
      PresentumState$Mutable<TItem, S, V> state,
    )
    change,
  );

  /// Execute a synchronous transaction.
  /// For example you can use it to change multiple states at once and
  /// combine them into one change.
  ///
  /// [change] is a function that takes the current state as an argument
  /// and returns a new state.
  /// [priority] is used to determine the order of execution of transactions.
  /// The higher the priority, the earlier the transaction will be executed.
  /// If the priority is not specified, the transaction will be executed
  /// in the order in which it was added.
  Future<void> transaction(
    PresentumState<TItem, S, V> Function(PresentumState<TItem, S, V> state)
    change, {
    int? priority,
  });

  /// Push a new item to the presentation slot.
  Future<void> pushSlot(S surface, {required TItem item});

  /// Push multiple items to the presentation slot.
  Future<void> pushAllSlots(List<({S surface, TItem item})> items);

  /// Add a new event to the event listeners.
  Future<void> addEvent(PresentumEvent<TItem, S, V> event);

  /// Mark an item as shown.
  Future<void> markShown(TItem item);

  /// Mark an item as dismissed in the storage and removes it from the slot.
  Future<void> markDismissed(TItem item);

  /// Mark an item as converted.
  Future<void> markConverted(
    TItem item, {
    Map<String, Object?>? conversionMetadata,
  });

  /// Remove all instances of an item with the given [id] from slots.
  ///
  /// If [surface] is provided, removal is limited to that surface.
  Future<void> removeById(String id, {S? surface});
}
