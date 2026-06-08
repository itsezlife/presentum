import 'package:example/src/maintenance/controller/maintenance_state.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class RemoveIneligibleMaintenanceStep
    implements PresentumResolverStep<MaintenanceItem, AppSurface, AppVariant> {
  const RemoveIneligibleMaintenanceStep({required this.eligibility});

  final EligibilityResolver<MaintenanceItem> eligibility;

  @override
  Future<MaintenanceSlots> call(
    PresentumStepInput<MaintenanceItem, AppSurface, AppVariant> input,
  ) async {
    var slots = input.current;
    final checkedItems = <String>{};
    final ineligibleItems = <String>{};

    for (final surface in [...slots.surfaces]) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      for (final item in [?slot.active, ...slot.queue]) {
        if (checkedItems.contains(item.id)) continue;
        checkedItems.add(item.id);

        final eligible = await eligibility.isEligible(item, input.context);
        if (!eligible) ineligibleItems.add(item.id);
      }
    }

    if (ineligibleItems.isEmpty) return slots;

    for (final surface in [...slots.surfaces]) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      final active = slot.active;
      final queue = slot.queue;
      final activeIneligible =
          active != null && ineligibleItems.contains(active.id);
      final filteredQueue = queue
          .where((item) => !ineligibleItems.contains(item.id))
          .toList();
      final hadIneligibleInQueue = filteredQueue.length != queue.length;

      if (!activeIneligible && !hadIneligibleInQueue) continue;

      if (activeIneligible) {
        if (filteredQueue.isNotEmpty) {
          slots = slots.withActive(surface, filteredQueue.first);
          if (filteredQueue.length > 1) {
            slots = slots.withReorderedQueue(surface, filteredQueue.sublist(1));
          }
        } else {
          slots = slots.withCleared(surface);
        }
      } else if (active != null) {
        slots = slots.withReorderedQueue(surface, filteredQueue);
      }
    }

    return slots;
  }
}
