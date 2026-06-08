import 'dart:developer' as dev;

import 'package:collection/collection.dart';
import 'package:example/src/shop/controller/recommendation_state.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class SyncRecommendationSlotsStep
    implements
        PresentumResolverStep<RecommendationItem, AppSurface, AppVariant> {
  const SyncRecommendationSlotsStep();

  @override
  Future<RecommendationSlots> call(
    PresentumStepInput<RecommendationItem, AppSurface, AppVariant> input,
  ) async {
    var slots = input.current;
    final candidateMap = <String, RecommendationItem>{
      for (final candidate in input.candidates) candidate.id: candidate,
    };

    for (final surface in [...slots.surfaces]) {
      final slot = slots.slotFor(surface);
      if (slot == null) continue;

      final currentItems = <RecommendationItem>[?slot.active, ...slot.queue];
      if (currentItems.isEmpty) continue;

      final syncedItems = <RecommendationItem>[];
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

    return _removeExpired(slots);
  }

  RecommendationSlots _removeExpired(RecommendationSlots slots) {
    var result = slots;
    for (final surface in [...result.surfaces]) {
      final slot = result.slotFor(surface);
      if (slot == null) continue;

      final currentItems = <RecommendationItem>[?slot.active, ...slot.queue];
      final validItems = currentItems.where((item) {
        if (item.payload.isExpired) {
          dev.log(
            'Removing expired recommendation for ${item.context}',
            name: 'SyncRecommendationSlotsStep',
          );
          return false;
        }
        return true;
      }).toList();

      if (validItems.length == currentItems.length) continue;

      if (validItems.isEmpty) {
        result = result.withCleared(surface);
      } else {
        result = result.withActive(surface, validItems.first);
        if (validItems.length > 1) {
          result = result.withReorderedQueue(surface, validItems.sublist(1));
        } else {
          result = result.withReorderedQueue(surface, const []);
        }
      }
    }
    return result;
  }

  bool _areContentsTheSame(
    RecommendationItem oldItem,
    RecommendationItem newItem,
  ) {
    final oldSet = oldItem.payload.recommendationSet;
    final newSet = newItem.payload.recommendationSet;
    if (oldSet.generatedAt != newSet.generatedAt) return false;
    if (!const ListEquality<RecommendationResult>().equals(
      oldSet.recommendations,
      newSet.recommendations,
    )) {
      return false;
    }
    if (oldItem.id != newItem.id) return false;
    if (oldItem.surface != newItem.surface) return false;
    if (oldItem.variant != newItem.variant) return false;
    if (oldItem.priority != newItem.priority) return false;
    return true;
  }
}
