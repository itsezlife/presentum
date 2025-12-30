import 'package:example/src/common/widgets/app_retain.dart';
import 'package:example/src/home/view/home_view.dart';
import 'package:example/src/main/view/main_view.dart';
import 'package:example/src/maintenance/view/maintenance_view.dart';
import 'package:example/src/settings/view/settings_view.dart';
import 'package:example/src/settings/widgets/about_app_dialog.dart';
import 'package:example/src/shop/shop_screens.dart' deferred as shop_screens;
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

enum Routes with OctopusRoute {
  home('home', title: 'Home'),
  main('main', title: 'Main'),
  maintenance('maintenance', title: 'Maintenance'),
  settings('settings', title: 'Settings'),
  catalog('catalog', title: 'Catalog'),
  category('category', title: 'Category'),
  productImageDialog('product-img-dialog', title: 'Product\'s Image'),
  product('product', title: 'Product'),
  basket('basket', title: 'Basket'),
  checkout('checkout', title: 'Checkout'),
  favorites('favorites', title: 'Favorites'),
  aboutAppDialog('about-app-dialog', title: 'About Application');

  const Routes(this.name, {this.title});

  @override
  final String name;

  @override
  final String? title;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) {
    switch (this) {
      case Routes.home:
        return _buildHomeShell(context, state, node);
      case Routes.main:
        return const MainView();
      case Routes.maintenance:
        return const AppRetain(child: MaintenanceView());
      case Routes.settings:
        return const SettingsView();
      case Routes.catalog:
        return _ShopLoader(builder: (context) => shop_screens.CatalogScreen());
      case Routes.category:
        return _ShopLoader(
          builder: (context) =>
              shop_screens.CategoryScreen(id: node.arguments['id']),
        );
      case Routes.product:
        return _ShopLoader(
          builder: (context) =>
              shop_screens.ProductScreen(id: node.arguments['id']),
        );
      case Routes.productImageDialog:
        return _ShopLoader(
          builder: (context) => shop_screens.ProductImageDialog(
            id: node.arguments['id'],
            idx: node.arguments['idx'],
          ),
        );
      case Routes.basket:
        return _ShopLoader(builder: (context) => shop_screens.BasketScreen());
      case Routes.checkout:
        return _ShopLoader(builder: (context) => shop_screens.CheckoutScreen());
      case Routes.favorites:
        return _ShopLoader(
          builder: (context) => shop_screens.FavoritesScreen(),
        );
      case Routes.aboutAppDialog:
        return const AboutApplicationDialog();
    }
  }

  @override
  Page<Object?> pageBuilder(
    BuildContext context,
    OctopusState state,
    OctopusNode node,
  ) {
    if (node.name.startsWith(Routes.home.name)) {
      return super.pageBuilder(context, state, node);
    }
    if (node.name.endsWith(Routes.maintenance.name)) {
      return NoAnimationPage(
        child: Routes.maintenance.builder(context, state, node),
      );
    }
    return super.pageBuilder(context, state, node);
  }

  Widget _buildHomeShell(
    BuildContext context,
    OctopusState state,
    OctopusNode node,
  ) => const AppRetain(child: HomeView());
}

class _ShopLoader extends StatelessWidget {
  const _ShopLoader({
    required this.builder,
    // ignore: unused_element_parameter
    super.key,
  });

  static final Future<void> _loadShop = shop_screens.loadLibrary();

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    initialData: null,
    future: _loadShop,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return builder(context);
      }
      return const Center(child: CircularProgressIndicator());
    },
  );
}
