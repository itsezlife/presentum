import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Presentum state observer.
abstract interface class PresentumStateObserver<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements ValueListenable<PresentumState$Immutable<TItem, S, V>> {
  /// Max history length.
  static const int maxHistoryLength = 10000;

  /// Current immutable state.
  @override
  PresentumState$Immutable<TItem, S, V> get value;

  /// History of the states.
  List<PresentumHistoryEntry<TItem, S, V>> get history;

  /// Set history.
  void setHistory(Iterable<PresentumHistoryEntry<TItem, S, V>> history);
}

/// Presentum history entry.
@immutable
final class PresentumHistoryEntry<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements Comparable<PresentumHistoryEntry<TItem, S, V>> {
  /// {@macro presentum_history_entry}
  PresentumHistoryEntry({required this.state, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// The state of the entry.
  final PresentumState$Immutable<TItem, S, V> state;

  /// The timestamp of the entry.
  final DateTime timestamp;

  @override
  int compareTo(covariant PresentumHistoryEntry<TItem, S, V> other) =>
      timestamp.compareTo(other.timestamp);

  @override
  late final int hashCode = state.hashCode ^ timestamp.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumHistoryEntry<TItem, S, V> &&
          timestamp == other.timestamp &&
          state == other.state;
}
