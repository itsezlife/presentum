import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/shop/data/recently_viewed_repository.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:flutter/foundation.dart';

class RecentlyViewedStore extends ValueListenable<List<ProductEntity>>
    with ChangeNotifier {
  RecentlyViewedStore({
    required IRecentlyViewedRepository repository,
    required ProductEntity? Function(int id) getProductById,
  }) : _repository = repository,
       _getProductById = getProductById {
    RouteTracker.instance.addListener(_onCurrentNodeChanged);
    _onCurrentNodeChanged();
    _loadProducts();
  }

  final IRecentlyViewedRepository _repository;
  final ProductEntity? Function(int id) _getProductById;

  var _products = <ProductEntity>[];

  @override
  List<ProductEntity> get value => _products;

  Future<void> _loadProducts() async {
    try {
      _products = await _repository.getRecentlyViewedProducts();
      notifyListeners();
    } on Object catch (error, stackTrace) {
      // Handle error silently or log it
      _products = <ProductEntity>[];
      notifyListeners();

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RecentlyViewedStore',
          context: ErrorSummary('Failed to load recently viewed products'),
        ),
      );
    }
  }

  void _onCurrentNodeChanged() {
    final currentNode = RouteTracker.instance.currentNode;
    if (currentNode == null) return;
    if (currentNode.name != Routes.product.name) return;

    /// Do not update recently viewed products list if it's ephemeral flag is true
    ///
    /// It is true only when tapping on the product in the recently viewed
    /// products list.
    if (currentNode.arguments['ephemeral'] == 'true') return;

    final id = switch (currentNode.arguments['id']) {
      String id => int.tryParse(id),
      _ => null,
    };
    if (id == null) return;

    final product = _getProductById(id);
    if (product == null) return;

    // Add product to recently viewed using _repository
    _repository
        .addRecentlyViewedProduct(product)
        .then((_) {
          _loadProducts();
        })
        .catchError((error) {
          // Handle error silently or log it
        });
  }

  Future<void> removeProduct(ProductEntity product) async {
    try {
      await _repository.removeRecentlyViewedProduct(product);
      await _loadProducts();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RecentlyViewedStore',
          context: ErrorSummary(
            'Failed to remove product from recently viewed',
          ),
        ),
      );
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearRecentlyViewedProducts();
      await _loadProducts();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RecentlyViewedStore',
          context: ErrorSummary('Failed to clear recently viewed products'),
        ),
      );
    }
  }

  @override
  void dispose() {
    RouteTracker.instance.removeListener(_onCurrentNodeChanged);
    super.dispose();
  }
}
