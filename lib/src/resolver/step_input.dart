import 'package:flutter/foundation.dart';
import 'package:presentum/src/resolver/context.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/slots_history.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';

/// {@template presentum_step_input}
/// Immutable input assembled by [PresentumStepsPipeline] for each step.
/// {@endtemplate}
@immutable
final class PresentumStepInput<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_step_input}
  const PresentumStepInput({
    required this.candidates,
    required this.context,
    required this.current,
    required this.history,
    required this.storage,
    required this.now,
  });

  /// Candidate items for this pipeline invocation.
  final List<TItem> candidates;

  /// Read-only runtime facts for eligibility and scheduling.
  final PresentumContext context;

  /// Slot state threaded through the pipeline (updated after each step).
  final PresentumSlotState<TItem, S, V> current;

  /// Historical slot snapshots for this domain.
  final PresentumSlotsHistory<TItem, S, V> history;

  /// Storage owned by the pipeline — not passed per host `call`.
  final PresentumStorage<S, V> storage;

  /// Clock for this pipeline invocation.
  final DateTime now;

  /// Returns a copy with the given fields replaced.
  PresentumStepInput<TItem, S, V> copyWith({
    List<TItem>? candidates,
    PresentumContext? context,
    PresentumSlotState<TItem, S, V>? current,
    PresentumSlotsHistory<TItem, S, V>? history,
    PresentumStorage<S, V>? storage,
    DateTime? now,
  }) => PresentumStepInput<TItem, S, V>(
    candidates: candidates ?? this.candidates,
    context: context ?? this.context,
    current: current ?? this.current,
    history: history ?? this.history,
    storage: storage ?? this.storage,
    now: now ?? this.now,
  );
}
