import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/octopus_extension.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/favorite_button.dart';
import 'package:example/src/shop/widget/small_product_card.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

/// {@template large_product_card}
/// Large product card for recommendations
/// {@endtemplate}
class LargeProductCard extends StatelessWidget {
  /// {@macro large_product_card}
  const LargeProductCard({required this.product, this.onTap, super.key});

  final ProductEntity product;
  final void Function(BuildContext context, ProductEntity product)? onTap;

  Widget discountBanner({
    required Widget child,
    required ProductEntity product,
  }) => product.discountPercentage >= 15
      ? ClipRect(
          child: Banner(
            color: Colors.red,
            location: BannerLocation.topEnd,
            message: '${product.discountPercentage.round()}%',
            child: child,
          ),
        )
      : child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final hasDiscount = product.discountPercentage >= 15;
    final discountedPrice = hasDiscount
        ? (product.price * (1 - product.discountPercentage / 100)).round()
        : product.price;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => onTap == null
            ? context.octopus.pushOnTab(
                Routes.product,
                arguments: <String, String>{'id': product.id.toString()},
              )
            : onTap?.call(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  // Image
                  Positioned.fill(
                    child: discountBanner(
                      child: ProductCardImage(product: product),
                      product: product,
                    ),
                  ),

                  // Favorite button (top-left)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Transform.scale(
                      scale: 0.7,
                      // child: FavoriteButton(productId: product.id, mini: true),
                      child: FavoriteButton(productId: product.id, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          height: 1.2,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Rating
                    if (product.rating > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.sm),

                    // Price section
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${Config.currencySymbol}$discountedPrice',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 2)),
                          if (hasDiscount) ...[
                            TextSpan(
                              text: '${Config.currencySymbol}${product.price}',
                              style: textTheme.labelSmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: colorScheme.outline,
                                fontSize: 11,
                                height: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
