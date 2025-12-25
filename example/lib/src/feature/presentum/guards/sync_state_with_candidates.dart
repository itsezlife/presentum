import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/feature/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Syncs the current state slots with the latest candidates using DiffUtil.
///
/// This guard ensures that:
/// - Items removed from candidates are removed from all slots
/// - Items with updated metadata/content are refreshed in slots
/// - Items that haven't changed remain in their positions
///
/// This guard should typically run early in the guard chain, before
/// scheduling and eligibility guards, to ensure state reflects the
/// latest candidate data.
final class SyncStateWithCandidatesGuard
    extends PresentumGuard<FeatureItem, AppSurface, AppVariant> {
  /// Creates a new [SyncStateWithCandidatesGuard].
  SyncStateWithCandidatesGuard();

  @override
  FutureOr<PresentumState<FeatureItem, AppSurface, AppVariant>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<FeatureItem, AppSurface, AppVariant>> history,
    PresentumState$Mutable<FeatureItem, AppSurface, AppVariant> state,
    List<FeatureItem> candidates,
    Map<String, Object?> context,
  ) {
    // Build a map of candidates by their unique key (id + surface + variant)
    // for fast lookup.
    final candidateMap = <String, FeatureItem>{};
    for (final candidate in candidates) {
      final key = candidate.id;
      candidateMap[key] = candidate;
    }

    // Process each surface's slot.
    // Convert to list to avoid ConcurrentModificationError when removing surfaces.
    for (final surfaceEntry in state.slots.entries.toList()) {
      final surface = surfaceEntry.key;
      final slot = surfaceEntry.value;

      // Collect current items in this slot (active + queue).
      final currentItems = <FeatureItem>[?slot.active, ...slot.queue];

      if (currentItems.isEmpty) continue;

      // Build list of items that should remain, checking against candidates.
      final syncedItems = <FeatureItem>[];
      var itemsChanged = false;

      for (final currentItem in currentItems) {
        final key = currentItem.id;
        final candidateMatch = candidateMap[key];

        if (candidateMatch == null) {
          // Item no longer in candidates - mark for removal.
          dev.log(
            'Removing item from $surface: ${currentItem.id} '
            '(surface: ${currentItem.surface}, '
            'variant: ${currentItem.variant})',
            name: 'SyncStateGuard',
          );
          itemsChanged = true;
          continue;
        }

        // Check if content has changed using DiffUtil's content comparison.
        final contentsChanged = !_areContentsTheSame(
          currentItem,
          candidateMatch,
        );

        if (contentsChanged) {
          // Replace with updated version from candidates.
          dev.log(
            'Updating item in $surface: ${currentItem.id} '
            '(metadata changed)',
            name: 'SyncStateGuard',
          );
          syncedItems.add(candidateMatch);
          itemsChanged = true;
        } else {
          // Item unchanged, keep as-is.
          syncedItems.add(currentItem);
        }
      }

      // If anything changed, update the slot.
      if (itemsChanged) {
        if (syncedItems.isEmpty) {
          // All items removed - clear the surface.
          state.clearSurface(surface);
          dev.log(
            'Cleared surface $surface (no items remaining)',
            name: 'SyncStateGuard',
          );
        } else {
          // Update active and queue.
          final newActive = syncedItems.first;
          final newQueue = syncedItems.length > 1
              ? syncedItems.sublist(1)
              : const <FeatureItem>[];

          state.setActive(surface, newActive);
          if (newQueue.isNotEmpty) {
            state.setQueue(surface, newQueue);
          } else if (slot.queue.isNotEmpty) {
            // Clear queue if it was previously non-empty.
            state.setQueue(surface, const <FeatureItem>[]);
          }

          dev.log(
            'Synced surface $surface: '
            'active=${newActive.id}, queue=${newQueue.length}',
            name: 'SyncStateGuard',
          );
        }
      }
    }

    return state;
  }

  /// Checks if two entries have the same content.
  ///
  /// This compares the payload's metadata and other relevant properties
  /// to determine if an item needs to be updated.
  bool _areContentsTheSame(FeatureItem oldItem, FeatureItem newItem) {
    // Compare basic properties.
    if (oldItem.id != newItem.id) return false;
    if (oldItem.surface != newItem.surface) return false;
    if (oldItem.variant != newItem.variant) return false;
    if (oldItem.priority != newItem.priority) return false;

    // Compare option properties.
    final oldOption = oldItem.option;
    final newOption = newItem.option;

    if (oldOption.stage != newOption.stage) return false;
    if (oldOption.maxImpressions != newOption.maxImpressions) return false;
    if (oldOption.cooldownMinutes != newOption.cooldownMinutes) {
      return false;
    }
    if (oldOption.isDismissible != newOption.isDismissible) return false;
    if (oldOption.alwaysOnIfEligible != newOption.alwaysOnIfEligible) {
      return false;
    }

    // Compare metadata using deep equality.
    return _areMetadataEqual(oldItem.metadata, newItem.metadata);
  }

  /// Deep equality check for metadata maps.
  bool _areMetadataEqual(
    Map<String, Object?> oldMetadata,
    Map<String, Object?> newMetadata,
  ) {
    if (oldMetadata.length != newMetadata.length) return false;

    for (final entry in oldMetadata.entries) {
      if (!newMetadata.containsKey(entry.key)) return false;
      if (newMetadata[entry.key] != entry.value) return false;
    }

    return true;
  }
}
