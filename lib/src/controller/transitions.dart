import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_transition_observer}
/// Observer for Presentum state transitions.
///
/// Unlike [IPresentumEventHandler] which handles user-action lifecycle events
/// (shown, dismissed, converted), transition observers react to internal
/// state changes in the engine.
///
/// You can consider using transition observers for:
/// - Business logic integration (e.g., BLoC/Cubit)
/// - Conditional data fetching based on active items
/// - Custom analytics for state flow
/// - Debug logging of state changes
///
/// Transition observers should not directly call `setState` on
/// the presentum instance, as this creates circular dependencies and
/// unpredictable behavior. Instead, dispatch events to your business logic
/// layer (BLoC, Provider, etc.) which can then coordinate state changes
/// through the public API.
///
/// {@endtemplate}
abstract interface class IPresentumTransitionObserver<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_transition_observer}
  const IPresentumTransitionObserver();

  /// Called when a state transition occurs, after guards approve but before
  /// the state is committed and listeners are notified.
  ///
  /// The [transition] parameter contains both old and new states, along with
  /// computed diff information.
  ///
  /// The transition is made in the following sequence:
  /// - Called after all guards have approved the state change
  /// - Called before [notifyListeners]
  /// - Called synchronously in state change flow
  ///
  /// If this method throws, the state transition continues. Other observers
  /// will still be notified.
  ///
  /// Do NOT call `setState` or `transaction` on the presentum instance from
  /// within this method. This creates circular dependencies. Instead, schedule
  /// async work or dispatch to business logic layer.
  FutureOr<void> call(PresentumStateTransition<TItem, S, V> transition);
}

/// {@template presentum_state_transition}
/// Represents a state transition in the Presentum engine.
///
/// A transition captures the change from one immutable state to another,
/// along with computed diff information about what specifically changed.
/// {@endtemplate}
@immutable
final class PresentumStateTransition<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_state_transition}
  const PresentumStateTransition({
    required this.oldState,
    required this.newState,
    required this.timestamp,
  });

  /// The state before the transition.
  final PresentumState$Immutable<TItem, S, V> oldState;

  /// The state after the transition.
  final PresentumState$Immutable<TItem, S, V> newState;

  /// The timestamp when the transition occurred.
  final DateTime timestamp;

  /// Lazily computed diff between old and new states.
  ///
  /// This property performs slot-by-slot comparison to identify:
  /// - Variants that became active
  /// - Variants that became inactive
  /// - Variants added to queues
  /// - Variants removed from queues
  /// - Surfaces that were added or removed
  PresentumStateDiff<TItem, S, V> get diff =>
      PresentumStateDiff.compute(oldState, newState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumStateTransition<TItem, S, V> &&
          oldState == other.oldState &&
          newState == other.newState &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(oldState, newState, timestamp);

  @override
  String toString() =>
      'PresentumStateTransition(timestamp: $timestamp, '
      'surfaces: ${newState.slots.length}, '
      'intention: ${newState.intention})';
}

/// {@template presentum_state_diff}
/// Computed difference between two Presentum states.
///
/// This class provides high-level access to what changed between states,
/// without requiring consumers to manually diff slot maps.
///
/// **Performance:**
/// Diff computation is lazy and cached. First access performs the diff,
/// subsequent accesses return cached results.
/// {@endtemplate}
@immutable
final class PresentumStateDiff<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_state_diff}
  const PresentumStateDiff._({
    required this.oldState,
    required this.newState,
    required List<SlotChange<TItem, S, V>> changes,
    required Map<S, SlotDiff<TItem, S, V>> slotDiffs,
  }) : _changes = changes,
       _slotDiffs = slotDiffs;

  /// Computes the diff between two states.
  factory PresentumStateDiff.compute(
    PresentumState$Immutable<TItem, S, V> oldState,
    PresentumState$Immutable<TItem, S, V> newState,
  ) {
    final changes = <SlotChange<TItem, S, V>>[];
    final slotDiffs = <S, SlotDiff<TItem, S, V>>{};

    // Get all unique surfaces from both states
    final allSurfaces = <S>{...oldState.slots.keys, ...newState.slots.keys};

    for (final surface in allSurfaces) {
      final oldSlot = oldState.slots[surface];
      final newSlot = newState.slots[surface];

      // Compute slot-level diff
      final slotDiff = SlotDiff<TItem, S, V>.compute(
        surface: surface,
        oldSlot: oldSlot,
        newSlot: newSlot,
      );

      if (slotDiff.isNotEmpty) {
        slotDiffs[surface] = slotDiff;
        changes.addAll(slotDiff.changes);
      }
    }

    return PresentumStateDiff._(
      oldState: oldState,
      newState: newState,
      changes: changes,
      slotDiffs: slotDiffs,
    );
  }

  /// The state before the transition.
  final PresentumState$Immutable<TItem, S, V> oldState;

  /// The state after the transition.
  final PresentumState$Immutable<TItem, S, V> newState;

  /// All changes across all slots, in no particular order.
  final List<SlotChange<TItem, S, V>> _changes;

  /// Per-surface slot diffs.
  final Map<S, SlotDiff<TItem, S, V>> _slotDiffs;

  /// All changes that occurred in this transition.
  List<SlotChange<TItem, S, V>> get changes => List.unmodifiable(_changes);

  /// Diffs for each surface that changed.
  Map<S, SlotDiff<TItem, S, V>> get slotDiffs => Map.unmodifiable(_slotDiffs);

  /// Returns true if no changes occurred.
  bool get isEmpty => _changes.isEmpty;

  /// Returns true if any changes occurred.
  bool get isNotEmpty => _changes.isNotEmpty;

  /// All items that became active (moved to active slot).
  List<TItem> get itemsActivated => _changes
      .whereType<ItemActivatedChange<TItem, S, V>>()
      .map((e) => e.item)
      .toList();

  /// All items that became inactive (removed from active slot).
  List<TItem> get itemsDeactivated => _changes
      .whereType<ItemDeactivatedChange<TItem, S, V>>()
      .map((e) => e.item)
      .toList();

  /// All items added to queues.
  List<TItem> get itemsQueued => _changes
      .whereType<ItemQueuedChange<TItem, S, V>>()
      .map((e) => e.item)
      .toList();

  /// All items removed from queues.
  List<TItem> get itemsDequeued => _changes
      .whereType<ItemDequeuedChange<TItem, S, V>>()
      .map((e) => e.item)
      .toList();

  /// Surfaces that were added (didn't exist in old state).
  List<S> get surfacesAdded => _slotDiffs.keys
      .where((surface) => !oldState.slots.containsKey(surface))
      .toList();

  /// Surfaces that were removed (existed in old state, not in new).
  List<S> get surfacesRemoved => oldState.slots.keys
      .where((surface) => !newState.slots.containsKey(surface))
      .toList();

  /// Surfaces that were modified (existed in both, but changed).
  List<S> get surfacesModified => _slotDiffs.keys
      .where(
        (surface) =>
            oldState.slots.containsKey(surface) &&
            newState.slots.containsKey(surface),
      )
      .toList();

  /// Get diff for a specific surface, or null if it didn't change.
  SlotDiff<TItem, S, V>? diffForSurface(S surface) => _slotDiffs[surface];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumStateDiff<TItem, S, V> &&
          oldState == other.oldState &&
          newState == other.newState;

  @override
  int get hashCode => Object.hash(oldState, newState);

  @override
  String toString() =>
      'PresentumStateDiff('
      'activated: ${itemsActivated.length}, '
      'deactivated: ${itemsDeactivated.length}, '
      'queued: ${itemsQueued.length}, '
      'dequeued: ${itemsDequeued.length})';
}

/// {@template slot_diff}
/// Computed difference for a single slot/surface.
/// {@endtemplate}
@immutable
final class SlotDiff<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro slot_diff}
  const SlotDiff._({
    required this.surface,
    required this.oldSlot,
    required this.newSlot,
    required List<SlotChange<TItem, S, V>> changes,
  }) : _changes = changes;

  /// Computes the diff for a single slot.
  factory SlotDiff.compute({
    required S surface,
    required PresentumSlot<TItem, S, V>? oldSlot,
    required PresentumSlot<TItem, S, V>? newSlot,
  }) {
    final changes = <SlotChange<TItem, S, V>>[];

    // Handle slot creation/deletion
    if (oldSlot == null && newSlot == null) {
      return SlotDiff._(
        surface: surface,
        oldSlot: null,
        newSlot: null,
        changes: const [],
      );
    }

    if (oldSlot == null) {
      // Slot was created
      if (newSlot!.active case final newActive?) {
        changes.add(
          ItemActivatedChange(
            surface: surface,
            item: newActive,
            previousActive: null,
          ),
        );
      }
      for (final item in newSlot.queue) {
        changes.add(ItemQueuedChange(surface: surface, item: item));
      }
      return SlotDiff._(
        surface: surface,
        oldSlot: null,
        newSlot: newSlot,
        changes: changes,
      );
    }

    if (newSlot == null) {
      // Slot was deleted
      if (oldSlot.active case final oldActive?) {
        changes.add(
          ItemDeactivatedChange(
            surface: surface,
            item: oldActive,
            newActive: null,
          ),
        );
      }
      for (final item in oldSlot.queue) {
        changes.add(ItemDequeuedChange(surface: surface, item: item));
      }
      return SlotDiff._(
        surface: surface,
        oldSlot: oldSlot,
        newSlot: null,
        changes: changes,
      );
    }

    // Both slots exist - compare active items
    if (oldSlot.active != newSlot.active) {
      if (oldSlot.active case final oldActive?) {
        changes.add(
          ItemDeactivatedChange(
            surface: surface,
            item: oldActive,
            newActive: newSlot.active,
          ),
        );
      }
      if (newSlot.active case final newActive?) {
        changes.add(
          ItemActivatedChange(
            surface: surface,
            item: newActive,
            previousActive: oldSlot.active,
          ),
        );
      }
    }

    // Compare queues using ID-based diff
    final oldQueueIds = oldSlot.queue.map((e) => e.id).toSet();
    final newQueueIds = newSlot.queue.map((e) => e.id).toSet();

    // Find items added to queue
    for (final item in newSlot.queue) {
      if (!oldQueueIds.contains(item.id)) {
        changes.add(ItemQueuedChange(surface: surface, item: item));
      }
    }

    // Find items removed from queue
    for (final item in oldSlot.queue) {
      if (!newQueueIds.contains(item.id)) {
        changes.add(ItemDequeuedChange(surface: surface, item: item));
      }
    }

    return SlotDiff._(
      surface: surface,
      oldSlot: oldSlot,
      newSlot: newSlot,
      changes: changes,
    );
  }

  /// The surface this diff is for.
  final S surface;

  /// The slot state before the change (null if slot was created).
  final PresentumSlot<TItem, S, V>? oldSlot;

  /// The slot state after the change (null if slot was deleted).
  final PresentumSlot<TItem, S, V>? newSlot;

  /// All changes that occurred in this slot.
  final List<SlotChange<TItem, S, V>> _changes;

  /// All changes that occurred in this slot.
  List<SlotChange<TItem, S, V>> get changes => List.unmodifiable(_changes);

  /// Returns true if no changes occurred.
  bool get isEmpty => _changes.isEmpty;

  /// Returns true if any changes occurred.
  bool get isNotEmpty => _changes.isNotEmpty;

  /// Returns true if the active item changed.
  bool get activeChanged => oldSlot?.active != newSlot?.active;

  /// Returns true if the queue changed.
  bool get queueChanged => !const ListEquality<String>().equals(
    oldSlot?.queue.map((e) => e.id).toList(),
    newSlot?.queue.map((e) => e.id).toList(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotDiff<TItem, S, V> &&
          surface == other.surface &&
          oldSlot == other.oldSlot &&
          newSlot == other.newSlot;

  @override
  int get hashCode => Object.hash(surface, oldSlot, newSlot);

  @override
  String toString() =>
      'SlotDiff($surface, changes: ${_changes.length}, '
      'activeChanged: $activeChanged, queueChanged: $queueChanged)';
}

/// Signature for slot change pattern matching callbacks.
typedef SlotChangeMatch<
  R,
  T extends SlotChange<TItem, S, V>,
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> = R Function(T value);

/// Base class for all slot changes.
@immutable
sealed class SlotChange<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro slot_change}
  const SlotChange({required this.surface, required this.item});

  /// The surface where the change occurred.
  final S surface;

  /// The item involved in the change.
  final TItem item;

  /// Pattern matching for [SlotChange].
  ///
  /// Exhaustively matches all change types. All callbacks are required.
  R map<R>({
    required SlotChangeMatch<R, ItemActivatedChange<TItem, S, V>, TItem, S, V>
    activated,
    required SlotChangeMatch<R, ItemDeactivatedChange<TItem, S, V>, TItem, S, V>
    deactivated,
    required SlotChangeMatch<R, ItemQueuedChange<TItem, S, V>, TItem, S, V>
    queued,
    required SlotChangeMatch<R, ItemDequeuedChange<TItem, S, V>, TItem, S, V>
    dequeued,
  }) => switch (this) {
    ItemActivatedChange<TItem, S, V> c => activated(c),
    ItemDeactivatedChange<TItem, S, V> c => deactivated(c),
    ItemQueuedChange<TItem, S, V> c => queued(c),
    ItemDequeuedChange<TItem, S, V> c => dequeued(c),
  };

  /// Pattern matching for [SlotChange] with optional handlers.
  ///
  /// Unhandled cases fall back to [orElse].
  R maybeMap<R>({
    required R Function() orElse,
    SlotChangeMatch<R, ItemActivatedChange<TItem, S, V>, TItem, S, V>?
    activated,
    SlotChangeMatch<R, ItemDeactivatedChange<TItem, S, V>, TItem, S, V>?
    deactivated,
    SlotChangeMatch<R, ItemQueuedChange<TItem, S, V>, TItem, S, V>? queued,
    SlotChangeMatch<R, ItemDequeuedChange<TItem, S, V>, TItem, S, V>? dequeued,
  }) => map<R>(
    activated: activated ?? (_) => orElse(),
    deactivated: deactivated ?? (_) => orElse(),
    queued: queued ?? (_) => orElse(),
    dequeued: dequeued ?? (_) => orElse(),
  );

  /// Pattern matching for [SlotChange] returning null for unhandled cases.
  R? mapOrNull<R>({
    SlotChangeMatch<R, ItemActivatedChange<TItem, S, V>, TItem, S, V>?
    activated,
    SlotChangeMatch<R, ItemDeactivatedChange<TItem, S, V>, TItem, S, V>?
    deactivated,
    SlotChangeMatch<R, ItemQueuedChange<TItem, S, V>, TItem, S, V>? queued,
    SlotChangeMatch<R, ItemDequeuedChange<TItem, S, V>, TItem, S, V>? dequeued,
  }) => map<R?>(
    activated: activated ?? (_) => null,
    deactivated: deactivated ?? (_) => null,
    queued: queued ?? (_) => null,
    dequeued: dequeued ?? (_) => null,
  );

  /// Convenience getter to check if this is an activation change.
  bool get isActivated => this is ItemActivatedChange<TItem, S, V>;

  /// Convenience getter to check if this is a deactivation change.
  bool get isDeactivated => this is ItemDeactivatedChange<TItem, S, V>;

  /// Convenience getter to check if this is a queued change.
  bool get isQueued => this is ItemQueuedChange<TItem, S, V>;

  /// Convenience getter to check if this is a dequeued change.
  bool get isDequeued => this is ItemDequeuedChange<TItem, S, V>;

  @override
  String toString() => 'SlotChange($surface, ${item.id})';
}

/// {@template item_activated_change}
/// An item became the active item in a slot.
/// {@endtemplate}
@immutable
final class ItemActivatedChange<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends SlotChange<TItem, S, V> {
  /// {@macro item_activated_change}
  const ItemActivatedChange({
    required super.surface,
    required super.item,
    required this.previousActive,
  });

  /// The previously active item (null if slot was empty).
  final TItem? previousActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemActivatedChange<TItem, S, V> &&
          surface == other.surface &&
          item == other.item &&
          previousActive == other.previousActive;

  @override
  int get hashCode => Object.hash(surface, item, previousActive);
}

/// {@template item_deactivated_change}
/// An item was removed from the active slot.
/// {@endtemplate}
@immutable
final class ItemDeactivatedChange<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends SlotChange<TItem, S, V> {
  /// {@macro item_deactivated_change}
  const ItemDeactivatedChange({
    required super.surface,
    required super.item,
    required this.newActive,
  });

  /// The new active item (null if slot is now empty).
  final TItem? newActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemDeactivatedChange<TItem, S, V> &&
          surface == other.surface &&
          item == other.item &&
          newActive == other.newActive;

  @override
  int get hashCode => Object.hash(surface, item, newActive);
}

/// {@template item_queued_change}
/// An item was added to a slot's queue.
/// {@endtemplate}
@immutable
final class ItemQueuedChange<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends SlotChange<TItem, S, V> {
  /// {@macro item_queued_change}
  const ItemQueuedChange({required super.surface, required super.item});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemQueuedChange<TItem, S, V> &&
          surface == other.surface &&
          item == other.item;

  @override
  int get hashCode => Object.hash(surface, item);
}

/// {@template item_dequeued_change}
/// An item was removed from a slot's queue.
/// {@endtemplate}
@immutable
final class ItemDequeuedChange<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends SlotChange<TItem, S, V> {
  /// {@macro item_dequeued_change}
  const ItemDequeuedChange({required super.surface, required super.item});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemDequeuedChange<TItem, S, V> &&
          surface == other.surface &&
          item == other.item;

  @override
  int get hashCode => Object.hash(surface, item);
}
