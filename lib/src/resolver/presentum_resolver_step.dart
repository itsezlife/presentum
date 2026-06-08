import 'package:presentum/src/resolver/step_input.dart';
import 'package:presentum/src/state/payload.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/state/surface.dart';

/// {@template presentum_resolver_step}
/// Composable pipeline stage that maps slot state to slot state.
/// {@endtemplate}
abstract interface class PresentumResolverStep<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_resolver_step}
  Future<PresentumSlotState<TItem, S, V>> call(
    PresentumStepInput<TItem, S, V> input,
  );
}
