import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/shop/data/recommendation_repository.dart';
import 'package:example/src/shop/data/recommendation_store.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_provider}
/// Provider that manages recommendation presentum integration
///
/// This provider:
/// - Generates recommendation candidates from store
/// - Configures guards and eligibility
/// - Manages recommendation lifecycle
/// - Handles refresh triggers
/// {@endtemplate}
class RecommendationProvider extends ChangeNotifier {
  /// {@macro recommendation_provider}
  RecommendationProvider({required this.engine, required this.store}) {
    _initialize();
    loadRecommendations(
      context: RecommendationContext.homeFeed,
      forceRefresh: true,
    );
    RouteTracker.instance.addListener(_onRouteChange);
    _onRouteChange();
  }

  final PresentumEngine<RecommendationItem, AppSurface, AppVariant> engine;
  final RecommendationStore store;

  /// Current recommendations being displayed
  final Map<RecommendationContext, RecommendationSet> _activeRecommendations =
      {};

  /// Debounce timer for refresh
  Timer? _refreshDebounce;

  var _initialized = false;

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

  late final AppLifecycleListener _lifecycleListener;

  void _initialize() {
    if (_initialized) return;
    _initialized = true;

    // Listen to store changes
    store.addListener(_onStoreChanged);

    // Listen to app lifecycle changes
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

    // Initial candidate setup
    Future.microtask(_updateCandidates);
  }

  /// Load recommendations for a specific context
  Future<void> loadRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
    bool forceRefresh = false,
  }) async {
    try {
      final set = await store.getRecommendations(
        context: context,
        sourceProductId: sourceProductId,
        forceRefresh: forceRefresh,
      );

      if (set != null) {
        _activeRecommendations[context] = set;
        await _updateCandidates();
        dev.log(
          'Loaded recommendations for $context: ${set.recommendations.length} items',
          name: 'RecommendationProvider',
        );
      }
    } on Object catch (error, stackTrace) {
      dev.log(
        'Failed to load recommendations for $context',
        error: error,
        stackTrace: stackTrace,
        name: 'RecommendationProvider',
      );
    }
  }

  /// Record user interaction with a product
  Future<void> recordInteraction({
    required ProductID productId,
    required String interactionType,
    bool triggerRecomputation = false,
  }) async {
    await store.recordInteraction(
      productId: productId,
      interactionType: interactionType,
      triggerRecomputation: triggerRecomputation,
    );
  }

  /// Invalidate and refresh recommendations for a context
  Future<void> refreshRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) async {
    await store.invalidate(context: context, sourceProductId: sourceProductId);

    await loadRecommendations(
      context: context,
      sourceProductId: sourceProductId,
      forceRefresh: true,
    );
  }

  void _onStoreChanged() {
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(
      const Duration(milliseconds: 1500),
      _cleanupAndRefreshRecommendationSets,
    );
  }

  void _cancelRefresh() {
    _refreshDebounce?.cancel();
  }

  Future<void> _cleanupAndRefreshRecommendationSets() async {
    final expired = await store.cleanupExpired();
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

  Future<void> _updateCandidates() async {
    final candidates = <RecommendationItem>[];

    for (final entry in _activeRecommendations.entries) {
      final context = entry.key;
      final set = entry.value;

      // Skip if expired
      if (set.isExpired) {
        continue;
      }

      // Create payload
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

      // Create item for each option
      for (final option in payload.options) {
        candidates.add(RecommendationItem(payload: payload, option: option));
      }
    }

    dev.log(
      'Updating candidates: ${candidates.length} items',
      name: 'RecommendationProvider',
    );

    // Update engine
    engine.setCandidates((_, _) => candidates);
    notifyListeners();
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
    store.removeListener(_onStoreChanged);
    _lifecycleListener.dispose();
    RouteTracker.instance.removeListener(_onRouteChange);
    super.dispose();
  }
}
