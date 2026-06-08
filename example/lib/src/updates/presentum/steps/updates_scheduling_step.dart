import 'package:example/src/updates/controller/updates_state.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Schedules eligible update items as actives per surface.
final class UpdatesSchedulingStep
    implements PresentumResolverStep<AppUpdatesItem, AppSurface, AppVariant> {
  const UpdatesSchedulingStep({required this.eligibilityResolver});

  final EligibilityResolver<AppUpdatesItem> eligibilityResolver;

  @override
  Future<UpdatesSlots> call(
    PresentumStepInput<AppUpdatesItem, AppSurface, AppVariant> input,
  ) async {
    var slots = input.current;

    for (final item in input.candidates) {
      final isEligible = await eligibilityResolver.isEligible(
        item,
        input.context,
      );
      if (!isEligible) continue;
      slots = slots.withActive(item.surface, item);
    }

    return slots;
  }
}
