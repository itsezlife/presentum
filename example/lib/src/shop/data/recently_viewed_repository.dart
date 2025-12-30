import 'dart:convert';
import 'dart:developer' as dev;

import 'package:example/src/shop/model/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IRecentlyViewedRepository {
  Future<List<ProductEntity>> getRecentlyViewedProducts();
  Future<void> addRecentlyViewedProduct(ProductEntity product);
  Future<void> removeRecentlyViewedProduct(ProductEntity product);
  Future<void> clearRecentlyViewedProducts();
}

final class RecentlyViewedRepositoryImpl implements IRecentlyViewedRepository {
  const RecentlyViewedRepositoryImpl({
    required SharedPreferencesWithCache prefs,
    required this.count,
  }) : _prefs = prefs;

  final int count;
  final SharedPreferencesWithCache _prefs;

  @override
  Future<List<ProductEntity>> getRecentlyViewedProducts() async {
    final productsJson = _prefs.getStringList('recently_viewed_products') ?? [];
    if (productsJson.isEmpty) return [];

    if (productsJson case final Iterable<String> products) {
      final productsList = <ProductEntity>[];
      for (final product in products) {
        final productJson = jsonDecode(product);
        if (productJson case final Map<String, Object?> json) {
          productsList.add(ProductEntity.fromJson(json));
        } else {
          dev.log('Invalid product JSON: $product');
        }
      }
      return productsList;
    }
  }

  @override
  Future<void> addRecentlyViewedProduct(ProductEntity product) async {
    final products = await getRecentlyViewedProducts();

    // Remove if already exists to avoid duplicates
    products
      ..removeWhere((p) => p.id == product.id)
      // Add to the beginning of the list
      ..insert(0, product);

    // Keep only the most recent 10 items
    if (products.length > 10) {
      products.removeRange(10, products.length);
    }

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();

    await _prefs.setStringList('recently_viewed_products', productsJson);
  }

  @override
  Future<void> removeRecentlyViewedProduct(ProductEntity product) async {
    final products = await getRecentlyViewedProducts();
    products.removeWhere((p) => p.id == product.id);

    final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();

    await _prefs.setStringList('recently_viewed_products', productsJson);
  }

  @override
  Future<void> clearRecentlyViewedProducts() async {
    await _prefs.remove('recently_viewed_products');
  }
}
