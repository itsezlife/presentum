import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';

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
final class PresentumSlotsDiff<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_state_diff}
  const PresentumSlotsDiff._({
    required this.oldSlots,
    required this.newSlots,
    required List<SlotChange<TItem, S, V>> changes,
    required Map<S, SlotDiff<TItem, S, V>> slotDiffs,
  }) : _changes = changes,
       _slotDiffs = slotDiffs;

  /// Computes the diff between two states.
  factory PresentumSlotsDiff.compute(
    PresentumSlotState<TItem, S, V> oldSlots,
    PresentumSlotState<TItem, S, V> newSlots,
  ) {
    final changes = <SlotChange<TItem, S, V>>[];
    final slotDiffs = <S, SlotDiff<TItem, S, V>>{};

    // Get all unique surfaces from both states
    final allSurfaces = <S>{...oldSlots.surfaces, ...newSlots.surfaces};

    for (final surface in allSurfaces) {
      final oldSlot = oldSlots.slotFor(surface);
      final newSlot = newSlots.slotFor(surface);

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

    return PresentumSlotsDiff._(
      oldSlots: oldSlots,
      newSlots: newSlots,
      changes: changes,
      slotDiffs: slotDiffs,
    );
  }

  /// The state before the transition.
  final PresentumSlotState<TItem, S, V> oldSlots;

  /// The state after the transition.
  final PresentumSlotState<TItem, S, V> newSlots;

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
      .where((surface) => !oldSlots.surfaces.contains(surface))
      .toList();

  /// Surfaces that were removed (existed in old state, not in new).
  List<S> get surfacesRemoved => oldSlots.surfaces
      .where((surface) => !newSlots.surfaces.contains(surface))
      .toList();

  /// Surfaces that were modified (existed in both, but changed).
  List<S> get surfacesModified => _slotDiffs.keys
      .where(
        (surface) =>
            oldSlots.surfaces.contains(surface) &&
            newSlots.surfaces.contains(surface),
      )
      .toList();

  /// Get diff for a specific surface, or null if it didn't change.
  SlotDiff<TItem, S, V>? diffForSurface(S surface) => _slotDiffs[surface];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumSlotsDiff<TItem, S, V> &&
          oldSlots == other.oldSlots &&
          newSlots == other.newSlots;

  @override
  int get hashCode => Object.hash(oldSlots, newSlots);

  @override
  String toString() =>
      'PresentumSlotsDiff('
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
