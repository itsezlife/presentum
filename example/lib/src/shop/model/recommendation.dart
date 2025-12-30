import 'package:example/src/shop/model/product.dart';
import 'package:meta/meta.dart';

/// Strategy for generating recommendations
enum RecommendationStrategy {
  /// Based on content similarity (category, brand, price range)
  contentBased,

  /// Based on user behavior patterns
  collaborative,

  /// Hybrid approach combining multiple strategies
  hybrid,

  /// Trending/popular products
  trending,

  /// Personalized based on user history
  personalized,

  /// Products frequently bought together
  frequentlyBoughtTogether,
}

/// Context for recommendation generation
enum RecommendationContext {
  /// General homepage recommendations
  homeFeed,

  /// Recommendations on product detail page
  productDetail,

  /// Recommendations in cart/checkout
  cartUpsell,

  /// Post-purchase recommendations
  postPurchase,

  /// Search result augmentation
  searchEnhancement,

  /// Category browsing suggestions
  categoryBrowsing,
}

/// Confidence/quality score for recommendations
enum RecommendationQuality {
  /// High confidence match (score >= 0.8)
  high,

  /// Medium confidence match (0.5 <= score < 0.8)
  medium,

  /// Low confidence match (0.3 <= score < 0.5)
  low,

  /// Fallback/generic recommendations (score < 0.3)
  fallback;

  static RecommendationQuality fromScore(double score) {
    if (score >= 0.8) return high;
    if (score >= 0.5) return medium;
    if (score >= 0.3) return low;
    return fallback;
  }
}

/// {@template recommendation_result}
/// A single recommendation with its metadata
/// {@endtemplate}
@immutable
class RecommendationResult implements Comparable<RecommendationResult> {
  /// {@macro recommendation_result}
  const RecommendationResult({
    required this.productId,
    required this.score,
    required this.strategy,
    required this.quality,
    required this.reason,
    this.metadata = const {},
  });

  /// The recommended product ID
  final ProductID productId;

  /// Confidence score (0.0 to 1.0)
  final double score;

  /// Strategy used to generate this recommendation
  final RecommendationStrategy strategy;

  /// Quality tier of this recommendation
  final RecommendationQuality quality;

  /// Human-readable reason for recommendation
  final String reason;

  /// Additional metadata for debugging/analytics
  final Map<String, Object?> metadata;

  @override
  int compareTo(RecommendationResult other) {
    // Higher scores first
    final scoreComparison = other.score.compareTo(score);
    if (scoreComparison != 0) return scoreComparison;

    // Then by quality
    return quality.index.compareTo(other.quality.index);
  }

  @override
  int get hashCode => Object.hash(productId, score, strategy);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationResult && other.productId == productId);

  @override
  String toString() =>
      'RecommendationResult('
      'productId: $productId, '
      'score: ${score.toStringAsFixed(3)}, '
      'quality: $quality, '
      'strategy: $strategy'
      ')';
}

/// {@template recommendation_set}
/// A complete set of recommendations for a specific context
/// {@endtemplate}
@immutable
class RecommendationSet {
  /// {@macro recommendation_set}
  const RecommendationSet({
    required this.context,
    required this.recommendations,
    required this.generatedAt,
    this.sourceProductId,
    this.expiresAt,
    this.metadata = const {},
  });

  /// Context for which these recommendations were generated
  final RecommendationContext context;

  /// List of recommendations, pre-sorted by relevance
  final List<RecommendationResult> recommendations;

  /// When this set was generated
  final DateTime generatedAt;

  /// Source product (if context is productDetail)
  final ProductID? sourceProductId;

  /// When this set should be considered stale
  final DateTime? expiresAt;

  /// Additional context metadata
  final Map<String, Object?> metadata;

  /// Check if recommendations are still fresh
  bool get isExpired {
    if (expiresAt case final expiry?) {
      return DateTime.now().isAfter(expiry);
    }
    return false;
  }

  /// Age of this recommendation set
  Duration get age => DateTime.now().difference(generatedAt);

  /// Filter by quality threshold
  List<RecommendationResult> byQuality(RecommendationQuality minQuality) =>
      recommendations
          .where((r) => r.quality.index <= minQuality.index)
          .toList();

  /// Get top N recommendations
  List<RecommendationResult> top(int n) => recommendations.take(n).toList();

  RecommendationSet copyWith({List<RecommendationResult>? recommendations}) =>
      RecommendationSet(
        context: context,
        recommendations: recommendations ?? this.recommendations,
        generatedAt: generatedAt,
        sourceProductId: sourceProductId,
        expiresAt: expiresAt,
        metadata: metadata,
      );

  @override
  String toString() =>
      'RecommendationSet('
      'context: $context, '
      'count: ${recommendations.length}, '
      'age: ${age.inMinutes}m '
      ')';
}

/// {@template recommendation_request}
/// Request parameters for generating recommendations
/// {@endtemplate}
@immutable
class RecommendationRequest {
  /// {@macro recommendation_request}
  const RecommendationRequest({
    required this.context,
    this.sourceProductId,
    this.strategy = RecommendationStrategy.hybrid,
    this.limit = 20,
    this.minQuality = RecommendationQuality.low,
    this.excludeProductIds = const {},
    this.userContext = const {},
  });

  final RecommendationContext context;
  final ProductID? sourceProductId;
  final RecommendationStrategy strategy;
  final int limit;
  final RecommendationQuality minQuality;
  final Set<ProductID> excludeProductIds;
  final Map<String, Object?> userContext;

  RecommendationRequest copyWith({
    RecommendationContext? context,
    ProductID? sourceProductId,
    RecommendationStrategy? strategy,
    int? limit,
    RecommendationQuality? minQuality,
    Set<ProductID>? excludeProductIds,
    Map<String, Object?>? userContext,
  }) => RecommendationRequest(
    context: context ?? this.context,
    sourceProductId: sourceProductId ?? this.sourceProductId,
    strategy: strategy ?? this.strategy,
    limit: limit ?? this.limit,
    minQuality: minQuality ?? this.minQuality,
    excludeProductIds: excludeProductIds ?? this.excludeProductIds,
    userContext: userContext ?? this.userContext,
  );
}
