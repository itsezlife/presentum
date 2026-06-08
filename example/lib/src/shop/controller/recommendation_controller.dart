// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer' as dev;

import 'package:control/control.dart';
import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/shop/controller/recommendation_state.dart';
import 'package:example/src/shop/data/recommendation_repository.dart';
import 'package:example/src/shop/data/recommendation_store.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:example/src/shop/presentum/steps/recommendation_scheduling_step.dart';
import 'package:example/src/shop/presentum/steps/sync_recommendation_slots_step.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class RecommendationController extends StateController<RecommendationState>
    with DroppableControllerHandler {
  RecommendationController({
    required PersistentPresentumStorage<AppSurface, AppVariant> storage,
    required RecommendationStore store,
    super.initialState = const RecommendationState.initial(),
  }) : _storage = storage,
       _store = store {
    _pipeline =
        PresentumStepsPipeline<RecommendationItem, AppSurface, AppVariant>(
          storage: _storage,
          steps: const [
            SyncRecommendationSlotsStep(),
            RecommendationSchedulingStep(),
          ],
        );
    _store.addListener(_onStoreChanged);
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.resumed:
            _scheduleRefresh();
          case AppLifecycleState.inactive:
          case AppLifecycleState.paused:
          case AppLifecycleState.detached:
          case AppLifecycleState.hidden:
            _cancelRefresh();
        }
      },
    );
    RouteTracker.instance.addListener(_onRouteChange);
    loadRecommendations(
      context: RecommendationContext.homeFeed,
      forceRefresh: true,
    );
    _onRouteChange();
  }

  final PersistentPresentumStorage<AppSurface, AppVariant> _storage;
  final RecommendationStore _store;

  late final PresentumStepsPipeline<RecommendationItem, AppSurface, AppVariant>
  _pipeline;
  late final AppLifecycleListener _lifecycleListener;

  final Map<RecommendationContext, RecommendationSet> _activeRecommendations =
      {};

  Timer? _refreshDebounce;

  void _onRouteChange() {
    final currentNode = RouteTracker.instance.currentNode;
    if (currentNode == null) return;
    if (currentNode.name != Routes.product.name) return;

    final id = switch (currentNode.arguments['id']) {
      String id => int.tryParse(id),
      _ => null,
    };
    if (id == null) return;

    loadRecommendations(
      context: RecommendationContext.productDetail,
      sourceProductId: id,
    );
    recordInteraction(
      productId: id,
      interactionType: RecommendationInteractionType.view,
      triggerRecomputation: false,
    );
  }

  void _onStoreChanged() => _scheduleRefresh();

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 1500),
      () => handle(_cleanupAndRefreshRecommendationSets),
    );
  }

  void _cancelRefresh() => _refreshDebounce?.cancel();

  Future<void> _cleanupAndRefreshRecommendationSets() async {
    final expired = await _store.cleanupExpired();
    for (final entry in expired.entries) {
      final set = entry.value;
      final context = set.context;
      _activeRecommendations.remove(context);
      await refreshRecommendations(
        context: context,
        sourceProductId: set.sourceProductId,
      );
    }
  }

  Future<void> loadRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
    bool forceRefresh = false,
  }) => handle(() async {
    final set = await _store.getRecommendations(
      context: context,
      sourceProductId: sourceProductId,
      forceRefresh: forceRefresh,
    );

    if (set != null) {
      _activeRecommendations[context] = set;
      await _updateCandidates();
      dev.log(
        'Loaded recommendations for $context: ${set.recommendations.length} items',
        name: 'RecommendationController',
      );
    }
  });

  Future<void> recordInteraction({
    required ProductID productId,
    required String interactionType,
    bool triggerRecomputation = false,
  }) => _store.recordInteraction(
    productId: productId,
    interactionType: interactionType,
    triggerRecomputation: triggerRecomputation,
  );

  Future<void> refreshRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) => handle(() async {
    await _store.invalidate(context: context, sourceProductId: sourceProductId);
    await loadRecommendations(
      context: context,
      sourceProductId: sourceProductId,
      forceRefresh: true,
    );
  });

  Future<void> _updateCandidates() async {
    final candidates = <RecommendationItem>[];

    for (final entry in _activeRecommendations.entries) {
      final context = entry.key;
      final set = entry.value;
      if (set.isExpired) continue;

      final payload = RecommendationPayload(
        id: 'recommendation:${context.name}:${set.sourceProductId ?? 'general'}',
        priority: _getPriorityForContext(context),
        options: [
          RecommendationOption(
            surface: AppSurface.productRecommendations,
            variant: AppVariant.productRecommendationsGrid,
            stage: _getStageForContext(context),
            isDismissible: false,
            alwaysOnIfEligible: true,
          ),
        ],
        context: context,
        recommendationSet: set,
        sourceProductId: set.sourceProductId,
        metadata: {
          'generatedAt': set.generatedAt.toIso8601String(),
          'count': set.recommendations.length,
        },
      );

      for (final option in payload.options) {
        candidates.add(RecommendationItem(payload: payload, option: option));
      }
    }

    setState(state.copyWith(candidates: candidates));
    await _resolveAndCommit();
  }

  Future<void> _resolveAndCommit() async {
    final newSlots = await _pipeline(
      candidates: state.candidates,
      context: const {},
      current: state.slots,
      history: state.history,
    );
    setState(
      state.copyWith(
        slots: newSlots,
        history: state.history.record(slots: newSlots, current: state.slots),
      ),
    );
  }

  int _getPriorityForContext(RecommendationContext context) =>
      switch (context) {
        RecommendationContext.productDetail => 100,
        RecommendationContext.homeFeed => 80,
        RecommendationContext.cartUpsell => 90,
        RecommendationContext.postPurchase => 70,
        RecommendationContext.searchEnhancement => 60,
        RecommendationContext.categoryBrowsing => 50,
      };

  int _getStageForContext(RecommendationContext context) => switch (context) {
    RecommendationContext.productDetail => 100,
    RecommendationContext.homeFeed => 200,
    RecommendationContext.cartUpsell => 150,
    RecommendationContext.postPurchase => 300,
    RecommendationContext.searchEnhancement => 250,
    RecommendationContext.categoryBrowsing => 220,
  };

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _store.removeListener(_onStoreChanged);
    _lifecycleListener.dispose();
    RouteTracker.instance.removeListener(_onRouteChange);
    super.dispose();
  }
}
