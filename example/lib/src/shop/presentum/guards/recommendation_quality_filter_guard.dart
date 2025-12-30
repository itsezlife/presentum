import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_quality_filter_guard}
/// Guard that filters out low-quality recommendations
///
/// Ensures only recommendations meeting minimum quality threshold are displayed
/// {@endtemplate}
class RecommendationQualityFilterGuard
    extends PresentumGuard<RecommendationItem, AppSurface, AppVariant> {
  /// {@macro recommendation_quality_filter_guard}
  RecommendationQualityFilterGuard({this.minScore = 0.3, super.refresh});

  final double minScore;

  @override
  FutureOr<PresentumState<RecommendationItem, AppSurface, AppVariant>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<RecommendationItem, AppSurface, AppVariant>>
    history,
    PresentumState$Mutable<RecommendationItem, AppSurface, AppVariant> state,
    List<RecommendationItem> candidates,
    Map<String, Object?> context,
  ) {
    final filtered = <RecommendationItem>[];

    for (final item in candidates) {
      // Check if any recommendation meets the quality threshold
      final hasQualityRecs = item.recommendations.any(
        (r) => r.score >= minScore || true,
      );

      if (hasQualityRecs) {
        // Filter recommendations within the item
        final qualityRecs = item.recommendations
            .where((r) => r.score >= minScore)
            .toList();

        // Create new item with filtered recommendations
        final filteredSet = item.payload.recommendationSet.copyWith(
          recommendations: qualityRecs,
        );

        final filteredPayload = RecommendationPayload(
          id: item.payload.id,
          priority: item.payload.priority,
          options: item.payload.options,
          context: item.payload.context,
          recommendationSet: filteredSet,
          sourceProductId: item.payload.sourceProductId,
          metadata: item.payload.metadata,
        );

        filtered.add(
          RecommendationItem(payload: filteredPayload, option: item.option),
        );
      } else {
        dev.log(
          'Filtering out recommendation item - no items meet quality threshold',
          name: 'RecommendationQualityFilterGuard',
        );
      }
    }

    return state;
  }
}
