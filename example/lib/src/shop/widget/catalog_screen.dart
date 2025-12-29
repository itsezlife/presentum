import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/octopus_extension.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/widgets/common_actions.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:example/src/shop/model/category.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/products_grid_view.dart';
import 'package:example/src/shop/widget/shop_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template catalog_screen}
/// CatalogScreen widget.
/// {@endtemplate}
class CatalogScreen extends StatelessWidget {
  /// {@macro catalog_screen}
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ShopScope.getRootCategories(context);
    final colors = ColorUtil.getColors(categories.length);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // App bar
          SliverAppBar(
            title: const Text('Catalog'),
            actions: CommonActions(),
            floating: true,
            snap: true,
          ),

          /// Top padding
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          PresentumOutlet$Composition<FeatureItem, AppSurface, AppVariant>(
            surface: AppSurface.catalogView,
            surfaceMode: OutletGroupMode.custom,
            resolver: (items) => items
                .where((e) => AppVariant.catalogSections.contains(e.variant))
                .toList(),
            placeholderBuilder: (context) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            builder: (context, items) => SliverMainAxisGroup(
              slivers: [
                for (final item in items)
                  switch (item.variant) {
                    AppVariant.catalogCategoriesSection => SliverMainAxisGroup(
                      slivers: [
                        const _CatalogDivider('Categories'),

                        // Catalog root categories
                        SliverPadding(
                          padding: ScaffoldPadding.of(context),
                          sliver: SliverFixedExtentList.list(
                            itemExtent: 84,
                            children: <Widget>[
                              for (var i = 0; i < categories.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: _CatalogTile(
                                    categories[i],
                                    color: colors[i],
                                    key: ValueKey<CategoryID>(categories[i].id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppVariant.catalogRecentlyViewedProductsSection =>
                      const SliverMainAxisGroup(
                        slivers: [
                          _CatalogDivider('Recently viewed products'),
                          _RecentlyViewedProducts(),
                        ],
                      ),
                    _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  },
              ],
            ),
          ),

          /// Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class _CatalogDivider extends StatelessWidget {
  const _CatalogDivider(
    this.title, {
    // ignore: unused_element_parameter
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: ScaffoldPadding.of(context).copyWith(top: 16, bottom: 16),
    sliver: SliverToBoxAdapter(
      child: SizedBox(
        height: 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const Expanded(flex: 1, child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Expanded(flex: 9, child: Divider()),
          ],
        ),
      ),
    ),
  );
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile(this.category, {this.color, super.key});

  final CategoryEntity category;
  final Color? color;

  static final Map<CategoryID, IconData> _icons = <CategoryID, IconData>{
    'electronics': Icons.computer,
    'fragrances': Icons.spa,
    'groceries': Icons.shopping_cart,
    'home-decoration': Icons.home,
    'skincare': Icons.face,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return ListTile(
      dense: false,
      isThreeLine: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      iconColor: color,
      leading: AspectRatio(
        aspectRatio: 1,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(_icons[category.id] ?? Icons.category),
          ),
        ),
      ),
      title: Text(
        category.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodyLarge,
      ),
      subtitle: Text(
        l10n.categoryDescription(category.id),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall,
      ),
      onTap: () {
        context.octopus.pushOnTab(
          Routes.category,
          arguments: {'id': category.id},
        );
      },
    );
  }
}

/// Recently viewed products from the history stack
class _RecentlyViewedProducts extends StatefulWidget {
  // ignore: unused_element_parameter
  const _RecentlyViewedProducts({super.key});

  @override
  State<_RecentlyViewedProducts> createState() =>
      _RecentlyViewedProductsState();
}

class _RecentlyViewedProductsState extends State<_RecentlyViewedProducts> {
  late final ValueListenable<List<ProductEntity>> store;

  @override
  void initState() {
    super.initState();
    store = Dependencies.of(context).recentlyViewedStore;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: store,
    builder: (context, products, child) => products.isEmpty
        ? SliverPadding(
            padding: ScaffoldPadding.of(context),
            sliver: SliverToBoxAdapter(
              child: Material(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'No recently viewed products',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : SmallProductsSliverGridView(
            products: products.toList(growable: false),
            onTap: (context, product) {
              context.octopus.pushOnTab(
                Routes.product,
                arguments: <String, String>{
                  'id': product.id.toString(),
                  // Do not update recently viewed products list
                  'ephemeral': 'true',
                },
              );
            },
          ),
  );
}
