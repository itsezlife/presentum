import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';

/// Removes ineligible actives/queued items; clears footer when header is active.
final class RemoveIneligibleCampaignsStep
    implements
        PresentumResolverStep<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  const RemoveIneligibleCampaignsStep({required this.eligibility});

  final EligibilityResolver<HasMetadata> eligibility;

  @override
  Future<
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  >
  call(
    PresentumStepInput<CampaignPresentumItem, CampaignSurface, CampaignVariant>
    input,
  ) async {
    var slots = input.current;
    final checkedItems = <String>{};
    final ineligibleItems = <String>{};

    final surfaces = [...slots.surfaces];
    for (final surface in surfaces) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      for (final item in [?slot.active, ...slot.queue]) {
        if (checkedItems.contains(item.id)) continue;
        checkedItems.add(item.id);

        final eligible = await eligibility.isEligible(item, input.context);
        if (!eligible) ineligibleItems.add(item.id);
      }
    }

    if (ineligibleItems.isNotEmpty) {
      for (final surface in surfaces) {
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
              slots = slots.withReorderedQueue(
                surface,
                filteredQueue.sublist(1),
              );
            }
          } else {
            slots = slots.withCleared(surface);
          }
        } else if (active != null) {
          slots = slots.withReorderedQueue(surface, filteredQueue);
        }
      }
    }

    if (slots.activeFor(CampaignSurface.homeTopBanner) != null) {
      slots = slots.withCleared(CampaignSurface.homeFooterBanner);
    }

    return slots;
  }
}
