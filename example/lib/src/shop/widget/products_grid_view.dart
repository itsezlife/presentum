import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/large_product_card.dart';
import 'package:example/src/shop/widget/small_product_card.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class ProductsSliverGridView extends StatelessWidget {
  const ProductsSliverGridView({
    required this.products,
    required this.maxCrossAxisExtent,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.itemBuilder,
    this.onTap,
    this.padding,
    super.key,
  });

  final List<ProductEntity> products;
  final void Function(BuildContext context, ProductEntity product)? onTap;
  final Widget Function(BuildContext context, ProductEntity product)
  itemBuilder;
  final double maxCrossAxisExtent;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: padding ?? ScaffoldPadding.of(context),
    sliver: SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return itemBuilder(context, product);
      },
    ),
  );
}

class LargeProductsSliverGridView extends StatelessWidget {
  const LargeProductsSliverGridView({
    required this.products,
    this.onTap,
    this.padding,
    super.key,
  });

  final List<ProductEntity> products;
  final void Function(BuildContext context, ProductEntity product)? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    final childAspectRatio = screenSize.maybeWhen(
      orElse: () => .65,
      desktop: () => .6,
    );

    return ProductsSliverGridView(
      products: products,
      maxCrossAxisExtent: 200,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      onTap: onTap,
      itemBuilder: (context, product) => LargeProductCard(
        product: product,
        onTap: onTap,
        key: ValueKey(product.id),
      ),
      padding: padding,
    );
  }
}

class SmallProductsSliverGridView extends StatelessWidget {
  const SmallProductsSliverGridView({
    required this.products,
    this.onTap,
    this.padding,
    super.key,
  });

  final List<ProductEntity> products;
  final void Function(BuildContext context, ProductEntity product)? onTap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => ProductsSliverGridView(
    products: products,
    maxCrossAxisExtent: 152,
    childAspectRatio: 152 / 180,
    crossAxisSpacing: AppSpacing.xs,
    mainAxisSpacing: AppSpacing.xs,
    onTap: onTap,
    itemBuilder: (context, product) =>
        SmallProductCard(product, onTap: onTap, key: ValueKey(product.id)),
    padding: padding,
  );
}
