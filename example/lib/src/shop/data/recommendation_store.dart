import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/shop/data/recommendation_algorithm.dart';
import 'package:example/src/shop/data/recommendation_repository.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:flutter/foundation.dart';

/// {@template recommendation_computation_config}
/// Configuration for recommendation computation
/// {@endtemplate}
@immutable
class RecommendationComputationConfig {
  /// {@macro recommendation_computation_config}
  const RecommendationComputationConfig({
    this.cacheDuration = const Duration(hours: 1),
    this.maxCachedSets = 50,
    this.interactionHistoryMaxAge = const Duration(days: 90),
    this.autoComputeOnInteraction = true,
    this.debounceInterval = const Duration(seconds: 2),
  });

  /// How long recommendation sets remain valid
  final Duration cacheDuration;

  /// Maximum number of cached recommendation sets
  final int maxCachedSets;

  /// Maximum age for interaction history
  final Duration interactionHistoryMaxAge;

  /// Whether to automatically recompute on user interactions
  final bool autoComputeOnInteraction;

  /// Debounce interval for auto-computation
  final Duration debounceInterval;
}

/// {@template recommendation_store}
/// Store that manages recommendation state and computation
/// {@endtemplate}
class RecommendationStore extends ChangeNotifier {
  /// {@macro recommendation_store}
  RecommendationStore({
    required this.repository,
    required this.algorithm,
    required this.getAllProducts,
    required this.getFavoriteProducts,
    required this.getRecentlyViewedProducts,
    this.config = const RecommendationComputationConfig(),
  }) {
    _initialize();
  }

  final IRecommendationRepository repository;
  final RecommendationAlgorithm algorithm;
  final List<ProductEntity> Function() getAllProducts;
  final Set<ProductID> Function() getFavoriteProducts;
  final List<ProductID> Function() getRecentlyViewedProducts;
  final RecommendationComputationConfig config;

  /// In-memory cache of recommendation sets
  final Map<String, RecommendationSet> _cache = {};

  /// Pending computation requests (for debouncing)
  Timer? _debounceTimer;

  /// Current computation task
  Future<void>? _currentComputation;

  /// Flag to track initialization
  var _initialized = false;

  void _initialize() {
    if (_initialized) return;
    _initialized = true;

    // Prune old interactions on startup
    repository.pruneInteractionHistory(config.interactionHistoryMaxAge);
  }

  /// Get recommendations for a specific context
  Future<RecommendationSet?> getRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(context, sourceProductId);

    // Check memory cache first
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        dev.log(
          'Returning cached recommendations for $context',
          name: 'RecommendationStore',
        );
        return cached;
      }
    }

    // Check persistent cache
    if (!forceRefresh) {
      final persisted = await repository.getRecommendationSet(
        context: context,
        sourceProductId: sourceProductId,
      );

      if (persisted != null && !persisted.isExpired) {
        dev.log(
          'Returning persisted recommendations for $context',
          name: 'RecommendationStore',
        );
        _cache[cacheKey] = persisted;
        return persisted;
      }
    }

    // Compute new recommendations
    dev.log(
      'Computing new recommendations for $context',
      name: 'RecommendationStore',
    );

    return _computeRecommendations(
      context: context,
      sourceProductId: sourceProductId,
    );
  }

  /// Compute recommendations
  Future<RecommendationSet> _computeRecommendations({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) async {
    final allProducts = getAllProducts();
    if (allProducts.isEmpty) {
      throw StateError('No products available for recommendations');
    }

    // Build user history
    final favoriteIds = getFavoriteProducts();
    final viewedIds = getRecentlyViewedProducts();

    final userHistory = UserInteractionHistory(
      viewedProducts: viewedIds,
      favoriteProducts: favoriteIds,
      purchasedProducts: const [], // Add if you track purchases
    );

    // Determine strategy based on context
    final strategy = _selectStrategy(context, sourceProductId);

    // Build request
    final request = RecommendationRequest(
      context: context,
      sourceProductId: sourceProductId,
      strategy: strategy,
      limit: _selectLimit(context),
      minQuality: _selectMinQuality(context),
      excludeProductIds: {
        if (sourceProductId != null) sourceProductId,
        ...favoriteIds,
      },
    );

    // Run algorithm
    final set = await algorithm.generate(
      request: request,
      allProducts: allProducts,
      userHistory: userHistory,
    );

    // Cache results
    final cacheKey = _getCacheKey(context, sourceProductId);
    _cache[cacheKey] = set;
    await repository.saveRecommendationSet(set);

    // Enforce cache size limit
    _enforceCacheLimit();

    notifyListeners();
    return set;
  }

  /// Record a user interaction and optionally trigger recomputation
  Future<void> recordInteraction({
    required ProductID productId,
    required String interactionType,
    bool triggerRecomputation = false,
  }) async {
    await repository.recordInteraction(
      productId: productId,
      interactionType: interactionType,
    );

    dev.log(
      'Recorded "$interactionType" interaction for product $productId',
      name: 'RecommendationStore',
    );

    if (config.autoComputeOnInteraction && triggerRecomputation) {
      _scheduleRecomputation();
    }
  }

  /// Schedule a debounced recomputation
  void _scheduleRecomputation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(config.debounceInterval, _recomputeAll);
  }

  /// Recompute all active recommendation sets
  Future<void> _recomputeAll() async {
    // Prevent concurrent computations
    if (_currentComputation != null) {
      dev.log(
        'Skipping recomputation - already in progress',
        name: 'RecommendationStore',
      );
      return;
    }

    dev.log('Recomputing all recommendations', name: 'RecommendationStore');

    _currentComputation = Future(() async {
      try {
        // Recompute commonly used contexts
        final contexts = <(RecommendationContext, ProductID?)>[
          (RecommendationContext.homeFeed, null),
          // Add more as needed
        ];

        for (final (context, sourceId) in contexts) {
          await _computeRecommendations(
            context: context,
            sourceProductId: sourceId,
          );
        }
      } finally {
        _currentComputation = null;
      }
    });

    await _currentComputation;
  }

  /// Invalidate cache for specific context
  Future<void> invalidate({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) async {
    final cacheKey = _getCacheKey(context, sourceProductId);
    _cache.remove(cacheKey);
    notifyListeners();
  }

  /// Clear all cached recommendations
  Future<void> clearAll() async {
    _cache.clear();
    await repository.clearAllRecommendations();
    notifyListeners();
  }

  /// Cleanup expired recommendations
  Future<Map<String, RecommendationSet>> cleanupExpired() async {
    final expired = <String, RecommendationSet>{};

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expired[entry.key] = entry.value;
      }
    }

    await repository.clearExpiredRecommendations();

    if (expired.isEmpty) return {};

    dev.log(
      'Cleaned up $expired expired recommendation sets',
      name: 'RecommendationStore',
    );
    notifyListeners();
    return expired;
  }

  /// Enforce maximum cache size
  void _enforceCacheLimit() {
    if (_cache.length <= config.maxCachedSets) return;

    // Remove oldest entries
    final sorted = _cache.entries.toList()
      ..sort((a, b) => a.value.generatedAt.compareTo(b.value.generatedAt));

    final toRemove = sorted.length - config.maxCachedSets;
    for (var i = 0; i < toRemove; i++) {
      _cache.remove(sorted[i].key);
    }

    dev.log(
      'Removed $toRemove old recommendation sets to enforce cache limit',
      name: 'RecommendationStore',
    );
  }

  String _getCacheKey(RecommendationContext context, ProductID? sourceId) =>
      sourceId != null ? '${context.name}:$sourceId' : context.name;

  RecommendationStrategy _selectStrategy(
    RecommendationContext context,
    ProductID? sourceProductId,
  ) => switch (context) {
    RecommendationContext.homeFeed => RecommendationStrategy.personalized,
    RecommendationContext.productDetail =>
      sourceProductId != null
          ? RecommendationStrategy.contentBased
          : RecommendationStrategy.trending,
    RecommendationContext.cartUpsell =>
      RecommendationStrategy.frequentlyBoughtTogether,
    RecommendationContext.postPurchase => RecommendationStrategy.hybrid,
    RecommendationContext.searchEnhancement =>
      RecommendationStrategy.collaborative,
    RecommendationContext.categoryBrowsing => RecommendationStrategy.hybrid,
  };

  int _selectLimit(RecommendationContext context) => switch (context) {
    RecommendationContext.homeFeed => 20,
    RecommendationContext.productDetail => 15,
    RecommendationContext.cartUpsell => 10,
    RecommendationContext.postPurchase => 20,
    RecommendationContext.searchEnhancement => 15,
    RecommendationContext.categoryBrowsing => 20,
  };

  RecommendationQuality _selectMinQuality(RecommendationContext context) =>
      switch (context) {
        RecommendationContext.cartUpsell => RecommendationQuality.high,
        RecommendationContext.productDetail => RecommendationQuality.medium,
        _ => RecommendationQuality.low,
      };

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
