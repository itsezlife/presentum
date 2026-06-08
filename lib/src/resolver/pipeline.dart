import 'package:presentum/src/resolver/context.dart';
import 'package:presentum/src/resolver/presentum_resolver_step.dart';
import 'package:presentum/src/resolver/step_input.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/slots_history.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';
import 'package:presentum/src/transitions/slots_transition.dart';

/// {@template presentum_steps_pipeline}
/// Core composable primitive — owns [storage] and runs ordered resolver steps.
/// {@endtemplate}
final class PresentumStepsPipeline<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_steps_pipeline}
  const PresentumStepsPipeline({required this.storage, required this.steps});

  /// Storage dependency — not passed on each [call].
  final PresentumStorage<S, V> storage;

  /// Ordered steps executed on each [call].
  final List<PresentumResolverStep<TItem, S, V>> steps;

  /// Runs [steps] in order, threading [current] through each stage.
  ///
  /// On step failure the pipeline aborts and rethrows; the caller keeps
  /// [current] unchanged (no partial result is returned).
  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V>? current,
    PresentumSlotsHistory<TItem, S, V>? history,
    DateTime? now,
    void Function(PresentumSlotsTransition<TItem, S, V> transition)?
    onTransition,
  }) async {
    final initial = current ?? PresentumSlotState<TItem, S, V>.empty();
    var slots = initial;
    final resolvedNow = now ?? DateTime.now();
    final resolvedHistory = history ?? PresentumSlotsHistory<TItem, S, V>();

    try {
      for (final step in steps) {
        final input = PresentumStepInput<TItem, S, V>(
          candidates: candidates,
          context: context,
          current: slots,
          history: resolvedHistory,
          storage: storage,
          now: resolvedNow,
        );
        slots = await step.call(input);
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }

    onTransition?.call(
      PresentumSlotsTransition<TItem, S, V>(
        oldSlots: initial,
        newSlots: slots,
        timestamp: resolvedNow,
      ),
    );
    return slots;
  }
}
