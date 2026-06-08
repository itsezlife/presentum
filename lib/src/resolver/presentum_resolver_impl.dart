import 'package:flutter/foundation.dart';
import 'package:presentum/src/resolver/context.dart';
import 'package:presentum/src/resolver/pipeline.dart';
import 'package:presentum/src/resolver/presentum_resolver.dart';
import 'package:presentum/src/resolver/presentum_resolver_step.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/slots_history.dart';
import 'package:presentum/src/state/surface.dart';
import 'package:presentum/src/storage/storage.dart';
import 'package:presentum/src/transitions/slots_transition.dart';

@internal
final class PresentumResolver$Impl<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    implements PresentumResolver<TItem, S, V> {
  PresentumResolver$Impl({
    required PresentumStorage<S, V> storage,
    List<PresentumResolverStep<TItem, S, V>> steps = const [],
  }) : _pipeline = PresentumStepsPipeline<TItem, S, V>(
         storage: storage,
         steps: steps,
       );

  final PresentumStepsPipeline<TItem, S, V> _pipeline;

  @override
  PresentumStepsPipeline<TItem, S, V> get pipeline => _pipeline;

  @override
  Future<PresentumSlotState<TItem, S, V>> call({
    required List<TItem> candidates,
    required PresentumContext context,
    PresentumSlotState<TItem, S, V>? current,
    PresentumSlotsHistory<TItem, S, V>? history,
    DateTime? now,
    void Function(PresentumSlotsTransition<TItem, S, V> transition)?
    onTransition,
  }) => _pipeline.call(
    candidates: candidates,
    context: context,
    current: current,
    history: history,
    now: now,
    onTransition: onTransition,
  );
}
