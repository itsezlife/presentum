import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/state.dart';

/// Presentum state observer.
abstract interface class PresentumStateObserver<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    implements ValueListenable<PresentumState$Immutable<TResolved, S>> {
  /// Max history length.
  static const int maxHistoryLength = 10000;

  /// Current immutable state.
  @override
  PresentumState$Immutable<TResolved, S> get value;

  /// History of the states.
  List<PresentumHistoryEntry<TResolved, S>> get history;

  /// Set history.
  void setHistory(Iterable<PresentumHistoryEntry<TResolved, S>> history);
}

/// Presentum history entry.
@immutable
final class PresentumHistoryEntry<
  TResolved extends Identifiable,
  S extends PresentumSurface
>
    implements Comparable<PresentumHistoryEntry<TResolved, S>> {
  /// {@macro presentum_history_entry}
  PresentumHistoryEntry({required this.state, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// The state of the entry.
  final PresentumState$Immutable<TResolved, S> state;

  /// The timestamp of the entry.
  final DateTime timestamp;

  @override
  int compareTo(covariant PresentumHistoryEntry<TResolved, S> other) =>
      timestamp.compareTo(other.timestamp);

  @override
  late final int hashCode = state.hashCode ^ timestamp.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumHistoryEntry<TResolved, S> &&
          timestamp == other.timestamp &&
          state == other.state;
}
