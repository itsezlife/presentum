import 'dart:developer' as dev;

import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

/// Syncs slot actives/queues with the current candidate list.
final class SyncCampaignsSlotsStep
    implements
        PresentumResolverStep<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        > {
  const SyncCampaignsSlotsStep();

  @override
  Future<
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  >
  call(
    PresentumStepInput<CampaignPresentumItem, CampaignSurface, CampaignVariant>
    input,
  ) async {
    var slots = input.current;
    final candidateMap = <String, CampaignPresentumItem>{
      for (final candidate in input.candidates) candidate.id: candidate,
    };

    final surfaces = [...slots.surfaces];
    for (final surface in surfaces) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      final currentItems = <CampaignPresentumItem>[?slot.active, ...slot.queue];
      if (currentItems.isEmpty) continue;

      final syncedItems = <CampaignPresentumItem>[];
      var itemsChanged = false;

      for (final currentItem in currentItems) {
        final candidateMatch = candidateMap[currentItem.id];

        if (candidateMatch == null) {
          dev.log(
            'Removing item from $surface: ${currentItem.id}',
            name: 'SyncCampaignsSlotsStep',
          );
          itemsChanged = true;
          continue;
        }

        if (!_areContentsTheSame(currentItem, candidateMatch)) {
          dev.log(
            'Updating item in $surface: ${currentItem.id}',
            name: 'SyncCampaignsSlotsStep',
          );
          syncedItems.add(candidateMatch);
          itemsChanged = true;
        } else {
          syncedItems.add(currentItem);
        }
      }

      if (!itemsChanged) continue;

      if (syncedItems.isEmpty) {
        slots = slots.withCleared(surface);
        dev.log(
          'Cleared surface $surface (no items remaining)',
          name: 'SyncCampaignsSlotsStep',
        );
        continue;
      }

      slots = slots.withActive(surface, syncedItems.first);
      if (syncedItems.length > 1) {
        slots = slots.withReorderedQueue(surface, syncedItems.sublist(1));
      } else if (slot.queue.isNotEmpty) {
        slots = slots.withReorderedQueue(surface, const []);
      }
    }

    return slots;
  }

  bool _areContentsTheSame(
    CampaignPresentumItem oldItem,
    CampaignPresentumItem newItem,
  ) {
    if (oldItem.id != newItem.id) return false;
    if (oldItem.surface != newItem.surface) return false;
    if (oldItem.variant != newItem.variant) return false;
    if (oldItem.priority != newItem.priority) return false;
    if (oldItem.option != newItem.option) return false;

    final oldMetadata = oldItem.metadata;
    final newMetadata = newItem.metadata;
    if (oldMetadata.length != newMetadata.length) return false;
    for (final entry in oldMetadata.entries) {
      if (newMetadata[entry.key] != entry.value) return false;
    }
    return true;
  }
}
