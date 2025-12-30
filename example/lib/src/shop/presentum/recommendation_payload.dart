import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:meta/meta.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_payload}
/// Payload for recommendation presentations
/// {@endtemplate}
@immutable
class RecommendationPayload extends PresentumPayload<AppSurface, AppVariant> {
  /// {@macro recommendation_payload}
  const RecommendationPayload({
    required this.id,
    required this.priority,
    required this.options,
    required this.context,
    required this.recommendationSet,
    this.sourceProductId,
    this.metadata = const {},
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final List<RecommendationOption> options;

  @override
  final Map<String, dynamic> metadata;

  /// Context for which these recommendations are shown
  final RecommendationContext context;

  /// The recommendation set to display
  final RecommendationSet recommendationSet;

  /// Source product (if applicable)
  final ProductID? sourceProductId;

  /// Get products from recommendation set
  List<RecommendationResult> get recommendations =>
      recommendationSet.recommendations;

  /// Check if recommendations are still fresh
  bool get isExpired => recommendationSet.isExpired;

  /// Age of recommendations
  Duration get age => recommendationSet.age;

  @override
  int get hashCode => Object.hash(id, context, recommendationSet.generatedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecommendationPayload && other.id == id);

  @override
  String toString() =>
      'RecommendationPayload('
      'id: $id, '
      'context: $context, '
      'count: ${recommendations.length}, '
      'age: ${age.inMinutes}m '
      ')';
}

/// {@template recommendation_option}
/// Options for recommendation presentation
/// {@endtemplate}
@immutable
class RecommendationOption extends PresentumOption<AppSurface, AppVariant> {
  /// {@macro recommendation_option}
  const RecommendationOption({
    required this.surface,
    required this.variant,
    this.stage,
    this.maxImpressions,
    this.cooldownMinutes,
    this.isDismissible = false,
    this.alwaysOnIfEligible = true,
  });

  @override
  final AppSurface surface;

  @override
  final AppVariant variant;

  @override
  final int? stage;

  @override
  final int? maxImpressions;

  @override
  final int? cooldownMinutes;

  @override
  final bool isDismissible;

  @override
  final bool alwaysOnIfEligible;
}

/// {@template recommendation_item}
/// Presentum item for recommendations
/// {@endtemplate}
@immutable
final class RecommendationItem
    extends PresentumItem<RecommendationPayload, AppSurface, AppVariant> {
  /// {@macro recommendation_item}
  const RecommendationItem({required this.payload, required this.option});

  @override
  final RecommendationPayload payload;

  @override
  final RecommendationOption option;

  /// Get recommendations from this item
  List<RecommendationResult> get recommendations => payload.recommendations;

  /// Get recommendation context
  RecommendationContext get context => payload.context;

  /// Get source product ID
  ProductID? get sourceProductId => payload.sourceProductId;

  @override
  String toString() =>
      'RecommendationItem('
      'id: $id, '
      'surface: $surface, '
      'variant: $variant, '
      'context: $context, '
      'count: ${recommendations.length}'
      ')';
}
