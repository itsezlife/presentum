import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/widgets/common_actions.dart';
import 'package:example/src/common/widgets/not_found_screen.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/shop/model/category.dart';
import 'package:example/src/shop/widget/catalog_breadcrumbs.dart';
import 'package:example/src/shop/widget/products_grid_view.dart';
import 'package:example/src/shop/widget/shop_back_button.dart';
import 'package:example/src/shop/widget/shop_scope.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

/// {@template category_screen}
/// CategoryScreen.
/// {@endtemplate}
class CategoryScreen extends StatelessWidget {
  /// {@macro category_screen}
  const CategoryScreen({required this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context) {
    final categoryId = id;
    if (categoryId == null) return const NotFoundScreen();
    final content = ShopScope.getCategoryById(context, categoryId);
    if (content == null) return const NotFoundScreen();
    final CategoryContent(:category, :categories, :products) = content;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // App bar
          SliverAppBar(
            title: Text(category.title),
            pinned: true,
            floating: true,
            snap: true,
            leading: const ShopBackButton(),
            actions: CommonActions(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: SizedBox(
                height: 48,
                child: CatalogBreadcrumbs.category(id: categoryId),
              ),
            ),
            /* expandedHeight: 200,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  'https://picsum.photos/seed/$id/600/200',
                  fit: BoxFit.cover,
                ),
              ), */
          ),

          /// Top padding
          const SliverPadding(padding: EdgeInsets.only(top: 16)),

          // Subcategories
          CategoriesSliverListView(categories: categories),

          // Divider
          if (categories.isNotEmpty && products.isNotEmpty)
            SliverPadding(
              padding: ScaffoldPadding.of(context).copyWith(top: 8, bottom: 8),
              sliver: const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1),
              ),
            ),

          // Products
          LargeProductsSliverGridView(products: products),

          /// Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}

class CategoriesSliverListView extends StatelessWidget {
  const CategoriesSliverListView({required this.categories, super.key});

  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: ScaffoldPadding.of(context),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = categories[index];
        return ListTile(
          key: ValueKey<CategoryID>(category.id),
          title: Text(category.title),
          onTap: () => context.octopus.setState(
            (state) => state
              ..findByName('catalog-tab')?.add(
                Routes.category.node(
                  arguments: <String, String>{'id': category.id},
                ),
              ),
          ),
        );
      }, childCount: categories.length),
    ),
  );
}
