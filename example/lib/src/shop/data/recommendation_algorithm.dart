// ignore_for_file: use_named_constants

import 'dart:math' as math;

import 'package:example/src/common/constant/config.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:flutter/foundation.dart';

/// {@template user_interaction_history}
/// User interaction history for personalized recommendations
/// {@endtemplate}
@immutable
class UserInteractionHistory {
  /// {@macro user_interaction_history}
  const UserInteractionHistory({
    this.viewedProducts = const [],
    this.favoriteProducts = const {},
    this.purchasedProducts = const [],
    this.searchQueries = const [],
  });

  final List<ProductID> viewedProducts;
  final Set<ProductID> favoriteProducts;
  final List<ProductID> purchasedProducts;
  final List<String> searchQueries;

  /// Get all interacted product IDs
  Set<ProductID> get allInteractedProducts => {
    ...viewedProducts,
    ...favoriteProducts,
    ...purchasedProducts,
  };

  /// Get recently interacted products (last N)
  List<ProductID> getRecent(int count) {
    final recentViews = viewedProducts.reversed.take(count);
    final recentPurchases = purchasedProducts.reversed.take(count);
    return {...recentViews, ...recentPurchases}.toList();
  }
}

/// {@template recommendation_algorithm}
/// Core recommendation algorithm service
///
/// This service runs heavy computational tasks and should be used
/// in isolates or web workers for production applications.
/// {@endtemplate}
class RecommendationAlgorithm {
  /// {@macro recommendation_algorithm}
  const RecommendationAlgorithm();

  /// Generate recommendations based on request
  Future<RecommendationSet> generate({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Delegate to appropriate strategy
    final recommendations = await switch (request.strategy) {
      RecommendationStrategy.contentBased => _contentBasedRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      RecommendationStrategy.collaborative => _collaborativeRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      RecommendationStrategy.hybrid => _hybridRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      RecommendationStrategy.trending => _trendingRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      RecommendationStrategy.personalized => _personalizedRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      RecommendationStrategy.frequentlyBoughtTogether =>
        _frequentlyBoughtTogetherRecommendations(
          request: request,
          allProducts: allProducts,
          userHistory: userHistory,
        ),
    };

    // Filter and sort
    final filtered =
        recommendations
            .where((r) => !request.excludeProductIds.contains(r.productId))
            .where((r) => r.quality.index <= request.minQuality.index)
            .toList()
          ..sort();

    // Take only requested limit
    final limited = filtered.take(request.limit).toList();

    return RecommendationSet(
      context: request.context,
      recommendations: limited,
      generatedAt: DateTime.now(),
      sourceProductId: request.sourceProductId,
      expiresAt: DateTime.now().add(
        const Duration(seconds: Config.recommendationSetExpirationSeconds),
      ),
      metadata: {
        'strategy': request.strategy.name,
        'total_candidates': recommendations.length,
        'filtered_count': filtered.length,
      },
    );
  }

  /// Content-based filtering: recommend similar products
  Future<List<RecommendationResult>> _contentBasedRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    final sourceId = request.sourceProductId;
    if (sourceId == null) {
      return _fallbackRecommendations(allProducts, userHistory);
    }

    final sourceProduct = allProducts.firstWhere(
      (p) => p.id == sourceId,
      orElse: () => throw ArgumentError('Source product not found'),
    );

    final results = <RecommendationResult>[];

    for (final product in allProducts) {
      if (product.id == sourceId) continue;

      final similarity = _calculateContentSimilarity(sourceProduct, product);
      if (similarity < 0.1) continue; // Skip very low similarity

      final quality = RecommendationQuality.fromScore(similarity);
      final reason = _generateContentReason(sourceProduct, product);

      results.add(
        RecommendationResult(
          productId: product.id,
          score: similarity,
          strategy: RecommendationStrategy.contentBased,
          quality: quality,
          reason: reason,
          metadata: {
            'source_product': sourceId,
            'same_category': product.category == sourceProduct.category,
            'same_brand': product.brand == sourceProduct.brand,
          },
        ),
      );
    }

    return results;
  }

  /// Calculate content similarity between two products
  double _calculateContentSimilarity(
    ProductEntity source,
    ProductEntity target,
  ) {
    var score = 0.0;

    // Category match (40% weight)
    if (source.category == target.category) {
      score += 0.4;
    }

    // Brand match (20% weight)
    if (source.brand == target.brand) {
      score += 0.2;
    }

    // Price similarity (20% weight)
    final priceDiff = (source.price - target.price).abs();
    final avgPrice = (source.price + target.price) / 2;
    final priceRatio = 1 - (priceDiff / avgPrice).clamp(0.0, 1.0);
    score += priceRatio * 0.2;

    // Rating similarity (10% weight)
    final ratingDiff = (source.rating - target.rating).abs();
    final ratingRatio = 1 - (ratingDiff / 5.0);
    score += ratingRatio * 0.1;

    // Stock availability boost (10% weight)
    if (target.stock > 0) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate human-readable reason for content-based recommendation
  String _generateContentReason(ProductEntity source, ProductEntity target) {
    if (source.category == target.category && source.brand == target.brand) {
      return 'Similar ${source.brand} product in ${source.category}';
    } else if (source.category == target.category) {
      return 'Similar product in ${source.category}';
    } else if (source.brand == target.brand) {
      return 'Same brand: ${source.brand}';
    } else {
      return 'You might also like';
    }
  }

  /// Collaborative filtering: based on user behavior patterns
  Future<List<RecommendationResult>> _collaborativeRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Simplified collaborative filtering
    // In production, this would use matrix factorization or neural collaborative filtering

    final interactedIds = userHistory.allInteractedProducts;
    if (interactedIds.isEmpty) {
      return _fallbackRecommendations(allProducts, userHistory);
    }

    // Find products in same categories as interacted products
    final interactedProducts = allProducts
        .where((p) => interactedIds.contains(p.id))
        .toList();

    final categoryPreferences = <String, int>{};
    final brandPreferences = <String, int>{};

    for (final product in interactedProducts) {
      categoryPreferences[product.category] =
          (categoryPreferences[product.category] ?? 0) + 1;
      brandPreferences[product.brand] =
          (brandPreferences[product.brand] ?? 0) + 1;
    }

    final results = <RecommendationResult>[];

    for (final product in allProducts) {
      if (interactedIds.contains(product.id)) continue;

      final categoryScore =
          (categoryPreferences[product.category] ?? 0).toDouble() /
          interactedProducts.length;
      final brandScore =
          (brandPreferences[product.brand] ?? 0).toDouble() /
          interactedProducts.length;

      final score = categoryScore * 0.6 + brandScore * 0.4;
      if (score < 0.2) continue;

      final quality = RecommendationQuality.fromScore(score);

      results.add(
        RecommendationResult(
          productId: product.id,
          score: score,
          strategy: RecommendationStrategy.collaborative,
          quality: quality,
          reason: 'Based on your preferences',
          metadata: {
            'category_affinity': categoryScore,
            'brand_affinity': brandScore,
          },
        ),
      );
    }

    return results;
  }

  /// Hybrid approach combining multiple strategies
  Future<List<RecommendationResult>> _hybridRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Run both content-based and collaborative in parallel
    final results = await Future.wait([
      _contentBasedRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
      _collaborativeRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      ),
    ]);

    // Merge and deduplicate
    final merged = <ProductID, RecommendationResult>{};

    for (final resultList in results) {
      for (final result in resultList) {
        if (merged.containsKey(result.productId)) {
          // Average the scores if product appears in multiple strategies
          final existing = merged[result.productId]!;
          final avgScore = (existing.score + result.score) / 2;
          merged[result.productId] = RecommendationResult(
            productId: result.productId,
            score: avgScore,
            strategy: RecommendationStrategy.hybrid,
            quality: RecommendationQuality.fromScore(avgScore),
            reason: 'Highly recommended',
            metadata: {
              'strategies': [existing.strategy.name, result.strategy.name],
            },
          );
        } else {
          merged[result.productId] = result;
        }
      }
    }

    return merged.values.toList();
  }

  /// Trending/popular products
  Future<List<RecommendationResult>> _trendingRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Sort by rating and stock (proxy for popularity)
    final sorted = [...allProducts]
      ..sort((a, b) {
        final ratingCmp = b.rating.compareTo(a.rating);
        if (ratingCmp != 0) return ratingCmp;
        return b.stock.compareTo(a.stock);
      });

    return sorted.take(request.limit * 2).map((product) {
      final score = (product.rating / 5.0) * 0.8 + 0.2;
      return RecommendationResult(
        productId: product.id,
        score: score,
        strategy: RecommendationStrategy.trending,
        quality: RecommendationQuality.fromScore(score),
        reason: 'Trending now',
        metadata: {'rating': product.rating, 'stock': product.stock},
      );
    }).toList();
  }

  /// Personalized based on user history
  Future<List<RecommendationResult>> _personalizedRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Combine multiple signals for personalization
    final favoriteIds = userHistory.favoriteProducts;
    final recentIds = userHistory.getRecent(10);

    if (favoriteIds.isEmpty && recentIds.isEmpty) {
      return _trendingRecommendations(
        request: request,
        allProducts: allProducts,
        userHistory: userHistory,
      );
    }

    // Build user profile from favorites and recent views
    final profileProducts = allProducts
        .where((p) => favoriteIds.contains(p.id) || recentIds.contains(p.id))
        .toList();

    final results = <RecommendationResult>[];

    for (final product in allProducts) {
      if (favoriteIds.contains(product.id) || recentIds.contains(product.id)) {
        continue;
      }

      // Calculate match with user profile
      var maxSimilarity = 0.0;
      for (final profileProduct in profileProducts) {
        final similarity = _calculateContentSimilarity(profileProduct, product);
        maxSimilarity = math.max(maxSimilarity, similarity);
      }

      // Boost if favorited
      if (favoriteIds.isNotEmpty) {
        final favSimilarities = profileProducts
            .where((p) => favoriteIds.contains(p.id))
            .map((p) => _calculateContentSimilarity(p, product));
        if (favSimilarities.isNotEmpty) {
          final avgFavSim =
              favSimilarities.reduce((a, b) => a + b) / favSimilarities.length;
          maxSimilarity = (maxSimilarity + avgFavSim * 1.5) / 2;
        }
      }

      if (maxSimilarity < 0.2) continue;

      final quality = RecommendationQuality.fromScore(maxSimilarity);

      results.add(
        RecommendationResult(
          productId: product.id,
          score: maxSimilarity,
          strategy: RecommendationStrategy.personalized,
          quality: quality,
          reason: 'Picked for you',
          metadata: {'profile_size': profileProducts.length},
        ),
      );
    }

    return results;
  }

  /// Frequently bought together
  Future<List<RecommendationResult>> _frequentlyBoughtTogetherRecommendations({
    required RecommendationRequest request,
    required List<ProductEntity> allProducts,
    required UserInteractionHistory userHistory,
  }) async {
    // Simplified version - in production, use association rule mining
    final sourceId = request.sourceProductId;
    if (sourceId == null) {
      return _fallbackRecommendations(allProducts, userHistory);
    }

    // For now, use content-based as proxy
    return _contentBasedRecommendations(
      request: request.copyWith(strategy: RecommendationStrategy.contentBased),
      allProducts: allProducts,
      userHistory: userHistory,
    );
  }

  /// Fallback recommendations when no better options available
  List<RecommendationResult> _fallbackRecommendations(
    List<ProductEntity> allProducts,
    UserInteractionHistory userHistory,
  ) {
    // Return highest-rated products
    final sorted = [...allProducts]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return sorted.take(20).map((product) {
      final score = 0.3 + (product.rating / 5.0) * 0.2;
      return RecommendationResult(
        productId: product.id,
        score: score,
        strategy: RecommendationStrategy.trending,
        quality: RecommendationQuality.fallback,
        reason: 'Popular choice',
        metadata: const {'fallback': true},
      );
    }).toList();
  }
}
