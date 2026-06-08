import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/transitions/slots_diff.dart';

/// {@template presentum_slots_transition}
/// Captures a slot-state change produced by a successful pipeline run.
///
/// Intention is recorded separately via [PresentumSlotsHistory.record].
/// {@endtemplate}
@immutable
final class PresentumSlotsTransition<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_slots_transition}
  const PresentumSlotsTransition({
    required this.oldSlots,
    required this.newSlots,
    required this.timestamp,
  });

  /// Slot state before the pipeline ran.
  final PresentumSlotState<TItem, S, V> oldSlots;

  /// Slot state after all steps completed.
  final PresentumSlotState<TItem, S, V> newSlots;

  /// Clock used for this pipeline invocation.
  final DateTime timestamp;

  /// Lazily computed diff between [oldSlots] and [newSlots].
  PresentumSlotsDiff<TItem, S, V> get diff =>
      PresentumSlotsDiff.compute(oldSlots, newSlots);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentumSlotsTransition<TItem, S, V> &&
          oldSlots == other.oldSlots &&
          newSlots == other.newSlots &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(oldSlots, newSlots, timestamp);

  @override
  String toString() =>
      'PresentumSlotsTransition(timestamp: $timestamp, '
      'surfaces: ${newSlots.activeSurfaces.length})';
}
