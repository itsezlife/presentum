import 'dart:developer' as dev;

import 'package:example/src/shop/controller/recommendation_state.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class RecommendationSchedulingStep
    implements
        PresentumResolverStep<RecommendationItem, AppSurface, AppVariant> {
  const RecommendationSchedulingStep({this.minScore = 0.3});

  final double minScore;

  @override
  Future<RecommendationSlots> call(
    PresentumStepInput<RecommendationItem, AppSurface, AppVariant> input,
  ) async {
    final filteredCandidates = <RecommendationItem>[];

    for (final item in input.candidates) {
      final hasQualityRecs = item.recommendations.any(
        (r) => r.score >= minScore,
      );
      if (!hasQualityRecs) {
        dev.log(
          'Filtering out recommendation item - no items meet quality threshold',
          name: 'RecommendationSchedulingStep',
        );
        continue;
      }

      final qualityRecs = item.recommendations
          .where((r) => r.score >= minScore)
          .toList();
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
      filteredCandidates.add(
        RecommendationItem(payload: filteredPayload, option: item.option),
      );
    }

    var slots = input.current;

    final bySurface = <AppSurface, List<RecommendationItem>>{};
    for (final item in filteredCandidates) {
      bySurface.putIfAbsent(item.surface, () => []).add(item);
    }

    for (final entry in bySurface.entries) {
      final surface = entry.key;
      final items = entry.value
        ..sort((a, b) {
          final priorityCmp = b.priority.compareTo(a.priority);
          if (priorityCmp != 0) return priorityCmp;
          if (a.stage != null && b.stage != null) {
            return a.stage!.compareTo(b.stage!);
          }
          if (a.stage != null) return -1;
          if (b.stage != null) return 1;
          return 0;
        });

      if (items.isEmpty) continue;
      slots = slots.withActive(surface, items.first);
      if (items.length > 1) {
        slots = slots.withReorderedQueue(surface, items.sublist(1));
      }
    }

    return slots;
  }
}
