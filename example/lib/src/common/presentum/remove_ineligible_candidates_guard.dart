import 'dart:async';

import 'package:presentum/presentum.dart';

/// {@template remove_ineligible_candidates_guard}
/// Always put this guard last in the guards list to ensure we remove ineligible
/// items from the state.
///
/// This guard checks items that are already in state (active + queued) and
/// removes any that are no longer eligible. It can promote queued items to
/// active when the current active item becomes ineligible.
///
/// If you're using guards that rebuild state from scratch (like clearing all
/// slots and repopulating), this guard is probably redundant since those
/// guards already filter out ineligible items during the rebuild process.
///
/// This guard is mainly useful when:
/// - Previous guards preserve existing state structure
/// - You need incremental updates rather than full rebuilds
/// - Items can become ineligible after being placed in state (time windows, etc.)
///
/// Performance consideration: This does eligibility checks on items that may
/// have already been checked by earlier guards, so it adds overhead if used
/// alongside guards that already do proper filtering.
/// {@endtemplate}
final class RemoveIneligibleCandidatesGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumGuard<TItem, S, V> {
  /// {@macro remove_ineligible_candidates_guard}
  RemoveIneligibleCandidatesGuard({required this.eligibility, super.refresh});

  final EligibilityResolver<TItem> eligibility;

  @override
  FutureOr<PresentumState<TItem, S, V>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<TItem, S, V>> history,
    PresentumState$Mutable<TItem, S, V> state,
    List<TItem> candidates,
    Map<String, Object?> context,
  ) async {
    final checkedItems = <String>{};
    final ineligibleItems = <String>{};

    // First pass: identify all ineligible items from the current state and
    // current candidates.
    final slots = [...state.slots.entries];

    for (final entry in slots) {
      final slot = entry.value;

      if (slot.active case final active?) {
        final itemId = active.id;

        // Only check eligibility once per distinct campaign
        if (checkedItems.contains(itemId)) continue;
        checkedItems.add(itemId);

        final eligible = await eligibility.isEligible(active, <String, Object?>{
          ...context,
        });

        if (!eligible) {
          ineligibleItems.add(itemId);
        }
      }

      // Also check items in queue
      for (final queuedItem in slot.queue) {
        final itemId = queuedItem.id;

        if (checkedItems.contains(itemId)) continue;
        checkedItems.add(itemId);

        final eligible = await eligibility.isEligible(
          queuedItem,
          <String, Object?>{...context},
        );

        if (!eligible) {
          ineligibleItems.add(itemId);
        }
      }
    }

    // Second pass: remove all ineligible items from all surfaces in the
    // candidate state.
    if (ineligibleItems.isNotEmpty) {
      final slots = [...state.slots.entries];
      for (final entry in slots) {
        final surface = entry.key;
        final slot = entry.value;

        final active = slot.active;
        final queue = slot.queue;

        final activeIneligible =
            active?.payload.id != null && ineligibleItems.contains(active!.id);

        // Filter queue to remove ineligible items.
        final filteredQueue = queue
            .where((queuedItem) => !ineligibleItems.contains(queuedItem.id))
            .toList();

        // If nothing was ineligible for this surface, skip.
        final hadIneligibleInQueue = filteredQueue.length != queue.length;
        if (!activeIneligible && !hadIneligibleInQueue) continue;

        // Rebuild slot in `next` with only eligible items.
        if (activeIneligible) {
          if (filteredQueue.isNotEmpty) {
            // Promote first eligible item to active.
            final nextActive = filteredQueue.first;
            final nextQueue = filteredQueue.length > 1
                ? filteredQueue.sublist(1)
                : <TItem>[];

            state.setActive(surface, nextActive);
            if (nextQueue.isNotEmpty) {
              state.setQueue(surface, nextQueue);
            }
          } else {
            // No eligible items remain on this surface. Touch the surface in
            // state so that follow‑up guards do not restore stale items.
            state.clearSurface(surface);
          }
        } else {
          // Active is still eligible, only the queue changed.
          if (active != null) {
            state.setActive(surface, active);
          }
          state.setQueue(surface, filteredQueue);
        }
      }
    }

    return state;
  }
}
