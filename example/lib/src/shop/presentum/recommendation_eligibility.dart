import 'dart:async';

import 'package:example/src/common/constant/config.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';

/// {@template recommendation_expired_eligibility}
/// Condition: Recommendations must not be expired
/// {@endtemplate}
@immutable
final class RecommendationExpiredEligibility extends Eligibility {
  /// {@macro recommendation_expired_eligibility}
  const RecommendationExpiredEligibility();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecommendationExpiredEligibility;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'RecommendationExpiredEligibility()';
}

/// {@template recommendation_minimum_count_eligibility}
/// Condition: Minimum number of recommendations required
/// {@endtemplate}
@immutable
final class RecommendationMinimumCountEligibility extends Eligibility {
  /// {@macro recommendation_minimum_count_eligibility}
  const RecommendationMinimumCountEligibility({required this.minCount});

  final int minCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationMinimumCountEligibility &&
          other.minCount == minCount);

  @override
  int get hashCode => minCount.hashCode;

  @override
  String toString() => 'RecommendationMinimumCountEligibility(min: $minCount)';
}

/// {@template recommendation_quality_threshold_eligibility}
/// Condition: Average recommendation quality must meet threshold
/// {@endtemplate}
@immutable
final class RecommendationQualityThresholdEligibility extends Eligibility {
  /// {@macro recommendation_quality_threshold_eligibility}
  const RecommendationQualityThresholdEligibility({required this.minScore});

  final double minScore;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationQualityThresholdEligibility &&
          other.minScore == minScore);

  @override
  int get hashCode => minScore.hashCode;

  @override
  String toString() =>
      'RecommendationQualityThresholdEligibility(minScore: $minScore)';
}

/// {@template recommendation_freshness_eligibility}
/// Condition: Recommendations must be fresh (not older than max age)
/// {@endtemplate}
@immutable
final class RecommendationFreshnessEligibility extends Eligibility {
  /// {@macro recommendation_freshness_eligibility}
  const RecommendationFreshnessEligibility({required this.maxAge});

  final Duration maxAge;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationFreshnessEligibility && other.maxAge == maxAge);

  @override
  int get hashCode => maxAge.hashCode;

  @override
  String toString() => 'RecommendationFreshnessEligibility(maxAge: $maxAge)';
}

/// {@template recommendation_context_eligibility}
/// Condition: Recommendation context must be in allowed set
/// {@endtemplate}
@immutable
final class RecommendationContextEligibility extends Eligibility {
  /// {@macro recommendation_context_eligibility}
  const RecommendationContextEligibility({required this.allowedContexts});

  final Set<RecommendationContext> allowedContexts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationContextEligibility &&
          other.allowedContexts.length == allowedContexts.length &&
          other.allowedContexts.every(allowedContexts.contains));

  @override
  int get hashCode => Object.hashAll(allowedContexts);

  @override
  String toString() =>
      'RecommendationContextEligibility(contexts: $allowedContexts)';
}

/// Evaluates [RecommendationExpiredEligibility] conditions
final class RecommendationExpiredRule
    implements EligibilityRule<RecommendationExpiredEligibility> {
  /// Creates a recommendation expired rule
  const RecommendationExpiredRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is RecommendationExpiredEligibility;

  @override
  Future<bool> evaluate(
    RecommendationExpiredEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final item = context['_item'];
    if (item is! RecommendationItem) {
      throw const EvaluationException(
        'RecommendationExpiredRule requires RecommendationItem in context["_item"]',
      );
    }

    // Return true if NOT expired
    return !item.payload.isExpired;
  }
}

/// Evaluates [RecommendationMinimumCountEligibility] conditions
final class RecommendationMinimumCountRule
    implements EligibilityRule<RecommendationMinimumCountEligibility> {
  /// Creates a recommendation minimum count rule
  const RecommendationMinimumCountRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is RecommendationMinimumCountEligibility;

  @override
  Future<bool> evaluate(
    RecommendationMinimumCountEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final item = context['_item'];
    if (item is! RecommendationItem) {
      throw const EvaluationException(
        'RecommendationMinimumCountRule requires RecommendationItem in context["_item"]',
      );
    }

    return item.recommendations.length >= eligibility.minCount;
  }
}

/// Evaluates [RecommendationQualityThresholdEligibility] conditions
final class RecommendationQualityThresholdRule
    implements EligibilityRule<RecommendationQualityThresholdEligibility> {
  /// Creates a recommendation quality threshold rule
  const RecommendationQualityThresholdRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is RecommendationQualityThresholdEligibility;

  @override
  Future<bool> evaluate(
    RecommendationQualityThresholdEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final item = context['_item'];
    if (item is! RecommendationItem) {
      throw const EvaluationException(
        'RecommendationQualityThresholdRule requires RecommendationItem in context["_item"]',
      );
    }

    if (item.recommendations.isEmpty) return false;

    final avgScore =
        item.recommendations.map((r) => r.score).reduce((a, b) => a + b) /
        item.recommendations.length;

    return avgScore >= eligibility.minScore;
  }
}

/// Evaluates [RecommendationFreshnessEligibility] conditions
final class RecommendationFreshnessRule
    implements EligibilityRule<RecommendationFreshnessEligibility> {
  /// Creates a recommendation freshness rule
  const RecommendationFreshnessRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is RecommendationFreshnessEligibility;

  @override
  Future<bool> evaluate(
    RecommendationFreshnessEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final item = context['_item'];
    if (item is! RecommendationItem) {
      throw const EvaluationException(
        'RecommendationFreshnessRule requires RecommendationItem in context["_item"]',
      );
    }

    return item.payload.age <= eligibility.maxAge;
  }
}

/// Evaluates [RecommendationContextEligibility] conditions
final class RecommendationContextRule
    implements EligibilityRule<RecommendationContextEligibility> {
  /// Creates a recommendation context rule
  const RecommendationContextRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is RecommendationContextEligibility;

  @override
  Future<bool> evaluate(
    RecommendationContextEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final item = context['_item'];
    if (item is! RecommendationItem) {
      throw const EvaluationException(
        'RecommendationContextRule requires RecommendationItem in context["_item"]',
      );
    }

    return eligibility.allowedContexts.contains(item.context);
  }
}

// ============================================================================
// Extractors (if recommendations had metadata)
// ============================================================================

/// Extractor for recommendation-specific eligibility from item payload
///
/// Since RecommendationItem doesn't implement HasMetadata, we use a simple
/// extractor that creates standard conditions
final class RecommendationEligibilityExtractor
    implements EligibilityExtractor<RecommendationItem> {
  /// Creates a recommendation eligibility extractor
  const RecommendationEligibilityExtractor({
    this.minRecommendationCount = 3,
    this.minAverageScore = 0.3,
    this.maxAge = const Duration(hours: 2),
  });

  final int minRecommendationCount;
  final double minAverageScore;
  final Duration maxAge;

  @override
  bool supports(RecommendationItem subject) => true;

  @override
  Iterable<Eligibility> extract(RecommendationItem subject) => [
    const RecommendationExpiredEligibility(),
    RecommendationMinimumCountEligibility(minCount: minRecommendationCount),
    RecommendationQualityThresholdEligibility(minScore: minAverageScore),
    RecommendationFreshnessEligibility(maxAge: maxAge),
  ];
}

/// Wrapper resolver that injects the item into context for rule evaluation
final class RecommendationEligibilityResolver
    implements EligibilityResolver<RecommendationItem> {
  /// Creates a recommendation eligibility resolver
  RecommendationEligibilityResolver({
    int minRecommendationCount = 3,
    double minAverageScore = 0.3,
    Duration maxAge = const Duration(
      seconds: Config.recommendationMaxAgeSeconds,
    ),
  }) : _delegate = DefaultEligibilityResolver<RecommendationItem>(
         rules: [
           // Include standard rules for combinator support
           ...createStandardRules(),

           /// Creates a standard set of recommendation eligibility rules
           const RecommendationExpiredRule(),
           const RecommendationMinimumCountRule(),
           const RecommendationQualityThresholdRule(),
           const RecommendationFreshnessRule(),
           const RecommendationContextRule(),
         ],
         extractors: [
           RecommendationEligibilityExtractor(
             minRecommendationCount: minRecommendationCount,
             minAverageScore: minAverageScore,
             maxAge: maxAge,
           ),
         ],
       );

  final DefaultEligibilityResolver<RecommendationItem> _delegate;

  @override
  Future<Eligibility?> getIneligibleCondition(
    RecommendationItem subject,
    Map<String, dynamic> context,
  ) {
    // Inject the item into context so rules can access it
    final contextWithItem = <String, dynamic>{...context, '_item': subject};
    return _delegate.getIneligibleCondition(subject, contextWithItem);
  }

  @override
  Future<bool> isEligible(
    RecommendationItem subject,
    Map<String, dynamic> context,
  ) => getIneligibleCondition(subject, context).then((c) => c == null);
}
