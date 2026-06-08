import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template presentum_slot_state}
/// Immutable map of per-surface presentation slots (active + queue).
///
/// Host controllers own this type. Updates use [withActive], [withDismissed],
/// and related transforms — never mutate the internal map in place.
/// {@endtemplate}
@immutable
final class PresentumSlotState<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_slot_state}
  const PresentumSlotState.empty() : _slots = const {};

  const PresentumSlotState._(Map<S, PresentumSlot<TItem, S, V>> slots)
    : _slots = slots;

  final Map<S, PresentumSlot<TItem, S, V>> _slots;

  /// Whether the internal slot map has no surface entries.
  bool get isEmpty => _slots.isEmpty;

  /// Surfaces that have a slot map entry.
  Iterable<S> get surfaces => _slots.keys;

  MapEquality<S, PresentumSlot<TItem, S, V>> get _mapEquality =>
      MapEquality<S, PresentumSlot<TItem, S, V>>();

  /// Slot for [surface], or null when the surface has no entry.
  PresentumSlot<TItem, S, V>? slotFor(S surface) => _slots[surface];

  /// Active item for [surface], or null when missing or inactive.
  TItem? activeFor(S surface) => _slots[surface]?.active;

  /// FIFO queue for [surface]; empty when the surface has no entry.
  List<TItem> queueFor(S surface) =>
      List<TItem>.unmodifiable(_slots[surface]?.queue ?? const []);

  /// Whether [surface] has a non-null active item.
  bool hasActive(S surface) => _slots[surface]?.active != null;

  /// Surfaces that currently have an active item.
  Iterable<S> get activeSurfaces sync* {
    for (final entry in _slots.entries) {
      if (entry.value.active != null) yield entry.key;
    }
  }

  /// All active items across surfaces (iteration order not guaranteed).
  List<TItem> get activeItems => [
    for (final slot in _slots.values) ?slot.active,
  ];

  /// Sets [item] as active and clears the queue for [surface].
  PresentumSlotState<TItem, S, V> withActive(S surface, TItem item) {
    final next = _mutableCopy();
    next[surface] = PresentumSlot<TItem, S, V>(
      surface: surface,
      active: item,
      queue: const [],
    );
    return PresentumSlotState._(next);
  }

  /// Sets active when empty; otherwise appends to the queue tail.
  PresentumSlotState<TItem, S, V> withEnqueued(S surface, TItem item) {
    final slot = _slots[surface];
    if (slot == null || slot.active == null) {
      return withActive(surface, item);
    }
    final next = _mutableCopy();
    next[surface] = slot.copyWith(queue: [...slot.queue, item]);
    return PresentumSlotState._(next);
  }

  /// Clears the active item and promotes the first queued item, if any.
  PresentumSlotState<TItem, S, V> withDismissed(S surface) {
    final slot = _slots[surface];
    if (slot == null) return this;

    final next = _mutableCopy();
    if (slot.queue.isEmpty) {
      next[surface] = slot.copyWith(active: null);
    } else {
      final promoted = slot.queue.first;
      final remaining = List<TItem>.of(slot.queue)..removeAt(0);
      next[surface] = slot.copyWith(active: promoted, queue: remaining);
    }
    return PresentumSlotState._(next);
  }

  /// Removes [surface] from the slot map entirely.
  PresentumSlotState<TItem, S, V> withCleared(S surface) {
    if (!_slots.containsKey(surface)) return this;
    final next = _mutableCopy()..remove(surface);
    return PresentumSlotState._(next);
  }

  /// Keeps [surface] with an empty slot (`active: null`, `queue: []`).
  PresentumSlotState<TItem, S, V> withClearedSlot(S surface) {
    final next = _mutableCopy();
    next[surface] = PresentumSlot<TItem, S, V>.empty(surface);
    return PresentumSlotState._(next);
  }

  /// Replaces the queue for [surface]; active is unchanged.
  PresentumSlotState<TItem, S, V> withReorderedQueue(
    S surface,
    List<TItem> queue,
  ) {
    final slot = _slots[surface] ?? PresentumSlot<TItem, S, V>.empty(surface);
    final next = _mutableCopy();
    next[surface] = slot.copyWith(queue: List<TItem>.of(queue));
    return PresentumSlotState._(next);
  }

  /// Copies slots for [surfaces] from [other]; other surfaces stay unchanged.
  PresentumSlotState<TItem, S, V> mergeFrom(
    PresentumSlotState<TItem, S, V> other, {
    required Set<S> surfaces,
  }) {
    if (surfaces.isEmpty) return this;
    final next = _mutableCopy();
    for (final surface in surfaces) {
      final slot = other._slots[surface];
      if (slot != null) {
        next[surface] = slot;
      } else {
        next.remove(surface);
      }
    }
    return PresentumSlotState._(next);
  }

  Map<S, PresentumSlot<TItem, S, V>> _mutableCopy() =>
      Map<S, PresentumSlot<TItem, S, V>>.of(_slots);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumSlotState<TItem, S, V> &&
          _mapEquality.equals(_slots, other._slots);

  @override
  int get hashCode => _mapEquality.hash(_slots);

  @override
  String toString() => 'PresentumSlotState(slots: $_slots)';
}
