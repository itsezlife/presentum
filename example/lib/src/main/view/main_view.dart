import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/common/widgets/section_header.dart';
import 'package:example/src/main/widgets/new_year_banner.dart';
import 'package:example/src/shop/controller/shop_controller.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/products_grid_view.dart';
import 'package:example/src/shop/widget/recommendation_outlet.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:shared/shared.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Main View'),
            pinned: true,
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: ScaffoldPadding.of(
              context,
            ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
            sliver: SliverList.list(children: const [NewYearBanner()]),
          ),
          RecommendationOutlet(
            title: 'Recommended for You',
            subtitle: 'Personalized picks based on your preferences',
            maxItems: 4,
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
          const _ShuffledProductsSection(excludeProductId: 1),
        ],
      ),
    ),
  );
}

/// {@template shuffled_products_section}
/// Infinite loading list of shuffled products as fallback below recommendations
/// {@endtemplate}
class _ShuffledProductsSection extends StatefulWidget {
  const _ShuffledProductsSection({required this.excludeProductId});

  final int excludeProductId;

  @override
  State<_ShuffledProductsSection> createState() =>
      _ShuffledProductsSectionState();
}

class _ShuffledProductsSectionState extends State<_ShuffledProductsSection> {
  late final ShopController _shopController;
  List<ProductEntity>? _shuffledProducts;

  @override
  void initState() {
    super.initState();
    final dependencies = Dependencies.of(context);
    _shopController = dependencies.shopController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shuffledProducts == null) {
      _initializeProducts();
    }
  }

  void _initializeProducts() {
    final allProducts = _shopController.state.products;
    final filtered =
        allProducts.where((p) => p.id != widget.excludeProductId).toList()
          ..shuffle();
    setState(() {
      _shuffledProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _shuffledProducts;

    if (products == null || products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: [
        // Section header
        SliverPadding(
          padding: ScaffoldPadding.of(
            context,
          ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.md),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Explore More',
              subtitle: 'Discover our latest products',
            ),
          ),
        ),

        // Products grid using the same widget as category screen
        LargeProductsSliverGridView(
          products: products,
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
                  Routes.product.node(arguments: {'id': product.id.toString()}),
                );
              return state
                ..arguments[homeAppTab.identifier] = HomeTabsEnum.catalog.name;
            });
          },
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xlg)),
      ],
    );
  }
}
