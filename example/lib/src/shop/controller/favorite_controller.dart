import 'package:control/control.dart';
import 'package:example/src/shop/controller/favorite_state.dart';
import 'package:example/src/shop/data/product_repository.dart';
import 'package:example/src/shop/model/product.dart';

class FavoriteController extends StateController<FavoriteState>
    with SequentialControllerHandler {
  FavoriteController({
    required IProductRepository repository,
    super.initialState = const FavoriteState.idle(
      products: <ProductID>{},
      message: 'Initial',
    ),
  }) : _productRepository = repository;

  final IProductRepository _productRepository;

  /// Fetches the data.
  void fetch() => handle(
    () async {
      setState(
        FavoriteState.processing(products: state.products, message: 'Fetching'),
      );
      final products = await _productRepository.fetchFavoriteProducts();
      setState(
        FavoriteState.successful(products: products, message: 'Successful'),
      );
    },
    error: (error, _) async => setState(
      FavoriteState.idle(
        products: state.products,
        message: 'Error: $error', // ErrorUtil.formatMessage(error)
      ),
    ),
    done: () async =>
        setState(FavoriteState.idle(products: state.products, message: 'Idle')),
  );

  /// Adds a product to the favorite list.
  void add(ProductID id) => handle(
    () async {
      setState(
        FavoriteState.processing(products: state.products, message: 'Adding'),
      );
      await _productRepository.addFavoriteProduct(id);
      final products = await _productRepository.fetchFavoriteProducts();
      setState(
        FavoriteState.successful(products: products, message: 'Successful'),
      );
    },
    error: (error, _) async => setState(
      FavoriteState.idle(
        products: state.products,
        message: 'Error: $error', // ErrorUtil.formatMessage(error)
      ),
    ),
    done: () async =>
        setState(FavoriteState.idle(products: state.products, message: 'Idle')),
  );

  /// Removes a product from the favorite list.
  void remove(ProductID id) => handle(
    () async {
      setState(
        FavoriteState.processing(products: state.products, message: 'Removing'),
      );
      await _productRepository.removeFavoriteProduct(id);
      final products = await _productRepository.fetchFavoriteProducts();
      setState(
        FavoriteState.successful(products: products, message: 'Successful'),
      );
    },
    error: (error, _) async => setState(
      FavoriteState.idle(
        products: state.products,
        message: 'Error: $error', // ErrorUtil.formatMessage(error)
      ),
    ),
    done: () async =>
        setState(FavoriteState.idle(products: state.products, message: 'Idle')),
  );
}
