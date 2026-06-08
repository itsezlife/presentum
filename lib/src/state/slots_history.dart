import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';

/// How a slot-state commit is recorded in [PresentumSlotsHistory].
///
/// Mirrors [PresentumStateIntention] from the v0.3.6 engine observer.
enum PresentumSlotsStateIntention {
  /// Append a new history entry (default).
  auto,

  /// Replace the last history entry.
  replace,

  /// Append a new history entry (never replaces last).
  append,

  /// Skip recording; host should not emit a slot update.
  cancel,
}

/// One committed [PresentumSlotState] snapshot in history.
@immutable
final class PresentumSlotsHistoryEntry<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements Comparable<PresentumSlotsHistoryEntry<TItem, S, V>> {
  /// {@macro presentum_slots_history_entry}
  PresentumSlotsHistoryEntry({required this.slots, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Slot snapshot at commit time.
  final PresentumSlotState<TItem, S, V> slots;

  /// When this snapshot was recorded.
  final DateTime timestamp;

  @override
  int compareTo(covariant PresentumSlotsHistoryEntry<TItem, S, V> other) =>
      timestamp.compareTo(other.timestamp);

  @override
  late final int hashCode = Object.hash(slots, timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumSlotsHistoryEntry<TItem, S, V> &&
          timestamp == other.timestamp &&
          slots == other.slots;
}

/// Append-only ring buffer of committed slot snapshots.
///
/// Host controllers own an instance beside [PresentumSlotState]. Call
/// [record] after pipeline revalidation or lifecycle commits.
@immutable
final class PresentumSlotsHistory<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_slots_history}
  const PresentumSlotsHistory([
    List<PresentumSlotsHistoryEntry<TItem, S, V>>? entries,
  ]) : _entries = entries ?? const [];

  /// Maximum number of entries retained (oldest evicted first).
  static const int maxLength = 10000;

  final List<PresentumSlotsHistoryEntry<TItem, S, V>> _entries;

  /// Read-only view of recorded entries, sorted by [timestamp].
  List<PresentumSlotsHistoryEntry<TItem, S, V>> get entries =>
      UnmodifiableListView<PresentumSlotsHistoryEntry<TItem, S, V>>(_entries);

  /// Latest entry, or null when [entries] is empty.
  PresentumSlotsHistoryEntry<TItem, S, V>? get lastOrNull =>
      _entries.isEmpty ? null : _entries.last;

  /// Records [slots] using engine [changeState] semantics.
  ///
  /// Returns `this` when the commit is skipped ([PresentumSlotsStateIntention
  /// .cancel], both empty slot maps, or [slots] equals [current]).
  ///
  /// [current] is the committed slot state before this update (defaults to the
  /// last recorded snapshot, or empty when history is empty).
  PresentumSlotsHistory<TItem, S, V> record({
    required PresentumSlotState<TItem, S, V> slots,
    PresentumSlotsStateIntention intention = PresentumSlotsStateIntention.auto,
    DateTime? timestamp,
    PresentumSlotState<TItem, S, V>? current,
  }) {
    if (intention == PresentumSlotsStateIntention.cancel) return this;

    final committed =
        current ?? lastOrNull?.slots ?? PresentumSlotState<TItem, S, V>.empty();

    if (committed.isEmpty && slots.isEmpty) return this;
    if (committed == slots) return this;

    final entry = PresentumSlotsHistoryEntry<TItem, S, V>(
      slots: slots,
      timestamp: timestamp,
    );

    final next = List<PresentumSlotsHistoryEntry<TItem, S, V>>.of(_entries);

    switch (intention) {
      case PresentumSlotsStateIntention.auto:
      case PresentumSlotsStateIntention.append:
      case PresentumSlotsStateIntention.replace when next.isEmpty:
        next.add(entry);
      case PresentumSlotsStateIntention.replace:
        next[next.length - 1] = entry;
      case PresentumSlotsStateIntention.cancel:
        return this;
    }

    if (next.length > maxLength) {
      next.removeAt(0);
    }

    return PresentumSlotsHistory<TItem, S, V>(next);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumSlotsHistory<TItem, S, V> &&
          listEquals(_entries, other._entries);

  @override
  int get hashCode => Object.hashAll(_entries);
}
