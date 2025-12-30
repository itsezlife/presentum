import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/common/widgets/common_actions.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/products_grid_view.dart';
import 'package:example/src/shop/widget/shop_scope.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:shared/shared.dart';

/// {@template favorites_screen}
/// FavoritesScreen widget.
/// {@endtemplate}
class FavoritesScreen extends StatelessWidget {
  /// {@macro favorites_screen}
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = ShopScope.getFavorites(context, listen: true);
    final products = favorites
        .map<ProductEntity?>(
          (id) => ShopScope.getProductById(context, id, listen: false),
        )
        .whereType<ProductEntity>()
        .toList(growable: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // App bar
          SliverAppBar(
            title: const Text('Favorites'),
            pinned: true,
            floating: true,
            snap: true,
            actions: CommonActions(),
          ),

          // Products
          if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: Center(child: Text('Favorites is empty')),
            )
          else
            LargeProductsSliverGridView(
              products: products,
              padding: ScaffoldPadding.of(
                context,
                horizontalPadding: AppSpacing.lg,
              ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
              onTap: (context, product) {
                context.octopus.setState((state) {
                  const homeAppTab = HomeAppTab();
                  final node = state.find(
                    (n) => n.name == homeAppTab.tabRouteName(Routes.catalog),
                  );
                  if (node == null) {
                    return state
                      ..removeByName(Routes.favorites.name)
                      ..add(
                        Routes.favorites.node(
                          children: <OctopusNode>[
                            OctopusNode.mutable(
                              homeAppTab.tabRouteName(Routes.catalog),
                              children: [
                                Routes.catalog.node(),
                                Routes.product.node(
                                  arguments: {'id': product.id.toString()},
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      ..arguments[homeAppTab.identifier] =
                          HomeTabsEnum.catalog.name;
                  }
                  node.children
                    ..removeWhere(
                      (e) =>
                          e.name == Routes.category.name ||
                          e.name == Routes.product.name,
                    )
                    ..add(
                      Routes.product.node(
                        arguments: {'id': product.id.toString()},
                      ),
                    );
                  return state
                    ..arguments[homeAppTab.identifier] =
                        HomeTabsEnum.catalog.name;
                });
              },
            ),
        ],
      ),
    );
  }
}
