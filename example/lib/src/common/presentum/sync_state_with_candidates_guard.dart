import 'dart:async';
import 'dart:developer' as dev;

import 'package:presentum/presentum.dart';

/// {@template sync_state_with_candidates_guard}
/// This guard keeps the current state in sync with the list of candidates.
///
/// When candidates change (items added, removed, or updated), this guard
/// makes sure the state reflects those changes. It removes items that are
/// no longer in the candidates list and updates items whose content has
/// changed.
///
/// The guard works by:
/// - Comparing each item currently in state with the candidates
/// - Removing items that don't exist in candidates anymore
/// - Updating items whose metadata or properties have changed
/// - Keeping items that haven't changed as they are
///
/// This is useful when you have a dynamic list of content that can change
/// over time and you want the presentation state to stay current.
///
/// By default, the guard compares the items by their id, surface, variant,
/// priority, option, and metadata.
///
/// You can override the [areContentsTheSame], [areItemsTheSame], and
/// [areOptionsTheSame] methods to provide a custom comparison logic,
/// if you need to compare the content of the items in a different way,
/// specific to your [TItem] type.
/// {@endtemplate}
abstract base class ISyncStateWithCandidatesGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumGuard<TItem, S, V> {
  /// {@macro sync_state_with_candidates_guard}
  ISyncStateWithCandidatesGuard({super.refresh});

  @override
  FutureOr<PresentumState<TItem, S, V>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<TItem, S, V>> history,
    PresentumState$Mutable<TItem, S, V> state,
    List<TItem> candidates,
    Map<String, Object?> context,
  ) {
    // Build a map of candidates by their unique key (id + surface + variant)
    // for fast lookup.
    final candidateMap = <String, TItem>{};
    for (final candidate in candidates) {
      final key = candidate.id;
      candidateMap[key] = candidate;
    }

    // Process each surface's slot.
    final slots = [...state.slots.entries];
    for (final surfaceEntry in slots) {
      final surface = surfaceEntry.key;
      final slot = surfaceEntry.value;

      // Collect current items in this slot (active + queue).
      final currentItems = <TItem>[?slot.active, ...slot.queue];

      if (currentItems.isEmpty) continue;

      // Build list of items that should remain, checking against candidates.
      final syncedItems = <TItem>[];
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
        final contentsChanged = !areContentsTheSame(
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
              : <TItem>[];

          state.setActive(surface, newActive);
          if (newQueue.isNotEmpty) {
            state.setQueue(surface, newQueue);
          } else if (slot.queue.isNotEmpty) {
            // Clear queue if it was previously non-empty.
            state.setQueue(surface, <TItem>[]);
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
  bool areContentsTheSame(TItem oldItem, TItem newItem) {
    // Compare basic properties.
    final itemsAreTheSame = areItemsTheSame(oldItem, newItem);
    if (!itemsAreTheSame) return false;

    // Compare option properties.
    final oldOption = oldItem.option;
    final newOption = newItem.option;

    final optionsAreTheSame = areOptionsTheSame(oldOption, newOption);
    if (!optionsAreTheSame) return false;

    // Compare metadata using deep equality.
    final metadataAreTheSame = areMetadataEqual(
      oldItem.metadata,
      newItem.metadata,
    );
    if (!metadataAreTheSame) return false;

    return true;
  }

  /// Checks if two items have the same content.
  bool areItemsTheSame(TItem oldItem, TItem newItem) {
    if (oldItem.id != newItem.id) return false;
    if (oldItem.surface != newItem.surface) return false;
    if (oldItem.variant != newItem.variant) return false;
    if (oldItem.priority != newItem.priority) return false;
    if (oldItem.option != newItem.option) return false;
    return true;
  }

  bool areOptionsTheSame(PresentumOption oldOption, PresentumOption newOption) {
    if (oldOption.stage != newOption.stage) return false;
    if (oldOption.maxImpressions != newOption.maxImpressions) return false;
    if (oldOption.cooldownMinutes != newOption.cooldownMinutes) {
      return false;
    }
    if (oldOption.isDismissible != newOption.isDismissible) return false;
    if (oldOption.alwaysOnIfEligible != newOption.alwaysOnIfEligible) {
      return false;
    }
    return true;
  }

  /// Deep equality check for metadata maps.
  bool areMetadataEqual(
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

/// Guard that syncs the state with the candidates.
///
/// - See [ISyncStateWithCandidatesGuard] for more details.
/// 
/// {@macro sync_state_with_candidates_guard}
final class SyncStateWithCandidatesGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends ISyncStateWithCandidatesGuard<TItem, S, V> {
  /// {@macro sync_state_with_candidates_guard}
  SyncStateWithCandidatesGuard({super.refresh});
}
