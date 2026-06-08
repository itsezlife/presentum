import 'package:example/src/maintenance/controller/maintenance_state.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class MaintenanceSchedulingStep
    implements PresentumResolverStep<MaintenanceItem, AppSurface, AppVariant> {
  const MaintenanceSchedulingStep({required this.eligibilityResolver});

  final EligibilityResolver<MaintenanceItem> eligibilityResolver;

  @override
  Future<MaintenanceSlots> call(
    PresentumStepInput<MaintenanceItem, AppSurface, AppVariant> input,
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
