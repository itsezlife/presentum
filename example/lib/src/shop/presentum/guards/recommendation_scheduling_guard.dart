import 'dart:async';

import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_scheduling_guard}
/// Guard that schedules recommendations based on priority and stage
///
/// This guard:
/// - Sorts recommendations by priority and score
/// - Places items in appropriate slots
/// - Ensures only high-quality recommendations are shown
/// {@endtemplate}
class RecommendationSchedulingGuard
    extends PresentumGuard<RecommendationItem, AppSurface, AppVariant> {
  /// {@macro recommendation_scheduling_guard}
  RecommendationSchedulingGuard({super.refresh});

  @override
  FutureOr<PresentumState<RecommendationItem, AppSurface, AppVariant>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<RecommendationItem, AppSurface, AppVariant>>
    history,
    PresentumState$Mutable<RecommendationItem, AppSurface, AppVariant> state,
    List<RecommendationItem> candidates,
    Map<String, Object?> context,
  ) {
    // Group candidates by surface
    final bySurface = <AppSurface, List<RecommendationItem>>{};

    for (final item in candidates) {
      bySurface.putIfAbsent(item.surface, () => []).add(item);
    }

    // Schedule items for each surface
    for (final entry in bySurface.entries) {
      final surface = entry.key;
      final items = entry.value
        // Sort by priority and stage
        ..sort((a, b) {
          // Higher priority first
          final priorityCmp = b.priority.compareTo(a.priority);
          if (priorityCmp != 0) return priorityCmp;

          // Lower stage first (if both have stage)
          if (a.stage != null && b.stage != null) {
            return a.stage!.compareTo(b.stage!);
          }

          // Items with stage come before items without
          if (a.stage != null) return -1;
          if (b.stage != null) return 1;

          return 0;
        });

      if (items.isNotEmpty) {
        state.setActive(surface, items.first);
        if (items.length > 1) {
          state.setQueue(surface, items.sublist(1));
        }
      }
    }

    return state;
  }
}
