import 'dart:async';
import 'dart:developer' as dev;

import 'package:collection/collection.dart';
import 'package:example/src/common/presentum/sync_state_with_candidates_guard.dart';
import 'package:example/src/shop/data/recommendation_store.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_sync_guard}
/// Guard that syncs recommendation items with the store state
///
/// This guard:
/// - Removes items whose recommendations have expired
/// - Updates items when recommendation content changes
/// - Ensures displayed recommendations are always fresh
/// {@endtemplate}
final class RecommendationSyncGuard
    extends
        ISyncStateWithCandidatesGuard<
          RecommendationItem,
          AppSurface,
          AppVariant
        > {
  /// {@macro recommendation_sync_guard}
  RecommendationSyncGuard({required this.store, super.refresh});

  final RecommendationStore store;

  @override
  bool areItemsTheSame(RecommendationItem oldItem, RecommendationItem newItem) {
    // Check if recommendation set has changed
    final oldSet = oldItem.payload.recommendationSet;
    final newSet = newItem.payload.recommendationSet;

    // Compare generation times
    if (oldSet.generatedAt != newSet.generatedAt) return false;

    // Compare recommendation lists
    final recommendationsEqual = const ListEquality<RecommendationResult>()
        .equals(oldSet.recommendations, newSet.recommendations);
    if (!recommendationsEqual) {
      return false;
    }

    return super.areItemsTheSame(oldItem, newItem);
  }

  @override
  FutureOr<PresentumState<RecommendationItem, AppSurface, AppVariant>> call(
    PresentumStorage storage,
    List<PresentumHistoryEntry<RecommendationItem, AppSurface, AppVariant>>
    history,
    PresentumState$Mutable<RecommendationItem, AppSurface, AppVariant> state,
    List<RecommendationItem> candidates,
    Map<String, Object?> context,
  ) {
    // First, run standard sync logic
    final syncedState = super.call(
      storage,
      history,
      state,
      candidates,
      context,
    );

    // Then check for expired recommendations in remaining items
    if (syncedState
        is Future<PresentumState<RecommendationItem, AppSurface, AppVariant>>) {
      return syncedState.then(_removeExpired);
    } else {
      return _removeExpired(syncedState);
    }
  }

  PresentumState<RecommendationItem, AppSurface, AppVariant> _removeExpired(
    PresentumState<RecommendationItem, AppSurface, AppVariant> state,
  ) {
    final mutableState = PresentumState$Mutable.from(state);
    var modified = false;

    final slots = [...mutableState.slots.entries];
    for (final surfaceEntry in slots) {
      final surface = surfaceEntry.key;
      final slot = surfaceEntry.value;

      final currentItems = <RecommendationItem>[?slot.active, ...slot.queue];
      final validItems = currentItems.where((item) {
        if (item.payload.isExpired) {
          dev.log(
            'Removing expired recommendation for ${item.context}',
            name: 'RecommendationSyncGuard',
          );
          return false;
        }
        return true;
      }).toList();

      if (validItems.length != currentItems.length) {
        modified = true;
        if (validItems.isEmpty) {
          mutableState.clearSurface(surface);
        } else {
          mutableState.setActive(surface, validItems.first);
          if (validItems.length > 1) {
            mutableState.setQueue(surface, validItems.sublist(1));
          } else {
            mutableState.setQueue(surface, <RecommendationItem>[]);
          }
        }
      }
    }

    return modified ? mutableState : state;
  }
}
