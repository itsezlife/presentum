import 'package:presentum/src/resolver/context.dart';
import 'package:presentum/src/resolver/pipeline.dart';
import 'package:presentum/src/resolver/presentum_resolver_impl.dart';
import 'package:presentum/src/resolver/presentum_resolver_step.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/slots_history.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';
import 'package:presentum/src/transitions/slots_transition.dart';

/// {@template presentum_resolver}
/// Thin convenience wrapper around a [PresentumStepsPipeline].
/// {@endtemplate}
abstract interface class PresentumResolver<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_resolver}
  factory PresentumResolver({
    required PresentumStorage<S, V> storage,
    List<PresentumResolverStep<TItem, S, V>> steps = const [],
  }) => PresentumResolver$Impl<TItem, S, V>(storage: storage, steps: steps);

  /// Underlying pipeline — use to add steps or call directly.
  PresentumStepsPipeline<TItem, S, V> get pipeline;

  /// Delegates to [pipeline].
  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V>? current,
    PresentumSlotsHistory<TItem, S, V>? history,
    DateTime? now,
    void Function(PresentumSlotsTransition<TItem, S, V> transition)?
    onTransition,
  });
}
