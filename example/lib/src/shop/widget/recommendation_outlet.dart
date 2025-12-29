import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/common/widgets/section_header.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:example/src/shop/widget/products_grid_view.dart';
import 'package:example/src/shop/widget/shop_scope.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template recommendation_outlet}
/// Presentum outlet for displaying recommendations
///
/// This widget:
/// - Observes the recommendation surface
/// - Renders appropriate UI based on variant
/// - Handles empty states
/// {@endtemplate}
class RecommendationOutlet extends StatelessWidget {
  /// {@macro recommendation_outlet}
  const RecommendationOutlet({
    this.productId,
    this.title,
    this.subtitle,
    this.placeholder,
    this.maxItems,
    this.onTap,
    super.key,
  });

  final ProductID? productId;
  final String? title;
  final String? subtitle;
  final Widget? placeholder;
  final int? maxItems;
  final void Function(BuildContext context, ProductEntity product)? onTap;

  @override
  Widget build(
    BuildContext context,
  ) => PresentumOutlet$Composition<RecommendationItem, AppSurface, AppVariant>(
    surface: AppSurface.productRecommendations,
    surfaceMode: OutletGroupMode.custom,
    resolver: (items) {
      final filtered = items
          .where((e) => e.sourceProductId == productId)
          .toList();
      return filtered;
    },
    placeholderBuilder: (context) =>
        placeholder ?? const SliverToBoxAdapter(child: SizedBox.shrink()),
    builder: (context, items) => switch (items.first.variant) {
      AppVariant.productRecommendationsGrid => _buildGrid(context, items.first),
      _ => placeholder ?? const SliverToBoxAdapter(child: SizedBox.shrink()),
    },
  );

  Widget _buildGrid(BuildContext context, RecommendationItem item) {
    var recommendations = item.recommendations;
    if (maxItems case final maxItems?) {
      recommendations = recommendations.take(maxItems).toList();
    }

    if (recommendations.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        // Header
        SliverPadding(
          padding: ScaffoldPadding.of(
            context,
          ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: title, subtitle: subtitle),
          ),
        ),

        // Recommendations grid
        RecommendationsSliverGrid(
          recommendations: recommendations,
          onTap: onTap,
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xlg)),
      ],
    );
  }
}

/// {@template recommendations_sliver_grid}
/// Sliver grid view for displaying recommendations in CustomScrollView
/// {@endtemplate}
class RecommendationsSliverGrid extends StatelessWidget {
  /// {@macro recommendations_sliver_grid}
  const RecommendationsSliverGrid({
    required this.recommendations,
    this.onTap,
    super.key,
  });

  final List<RecommendationResult> recommendations;
  final void Function(BuildContext context, ProductEntity product)? onTap;

  @override
  Widget build(BuildContext context) => LargeProductsSliverGridView(
    products: recommendations
        .map((r) => ShopScope.getProductById(context, r.productId))
        .nonNulls
        .toList(),
    onTap: onTap,
  );
}
