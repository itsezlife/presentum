import 'package:example/src/maintenance/controller/maintenance_state.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class SyncMaintenanceSlotsStep
    implements PresentumResolverStep<MaintenanceItem, AppSurface, AppVariant> {
  const SyncMaintenanceSlotsStep();

  @override
  Future<MaintenanceSlots> call(
    PresentumStepInput<MaintenanceItem, AppSurface, AppVariant> input,
  ) async {
    var slots = input.current;
    final candidateMap = <String, MaintenanceItem>{
      for (final candidate in input.candidates) candidate.id: candidate,
    };

    for (final surface in [...slots.surfaces]) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      final currentItems = <MaintenanceItem>[?slot.active, ...slot.queue];
      if (currentItems.isEmpty) continue;

      final syncedItems = <MaintenanceItem>[];
      var itemsChanged = false;

      for (final currentItem in currentItems) {
        final candidateMatch = candidateMap[currentItem.id];
        if (candidateMatch == null) {
          itemsChanged = true;
          continue;
        }
        if (!_areContentsTheSame(currentItem, candidateMatch)) {
          syncedItems.add(candidateMatch);
          itemsChanged = true;
        } else {
          syncedItems.add(currentItem);
        }
      }

      if (!itemsChanged) continue;

      if (syncedItems.isEmpty) {
        slots = slots.withCleared(surface);
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

  bool _areContentsTheSame(MaintenanceItem oldItem, MaintenanceItem newItem) {
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
