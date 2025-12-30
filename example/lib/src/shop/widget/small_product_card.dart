import 'package:example/src/app/router/octopus_extension.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/common/widgets/outlined_text.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

class SmallProductCard extends StatelessWidget {
  const SmallProductCard(this.product, {this.onTap, super.key});

  final ProductEntity product;
  final void Function(BuildContext context, ProductEntity product)? onTap;

  Widget discountBanner({required Widget child}) =>
      product.discountPercentage >= 15
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
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.all(4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: <Widget>[
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: discountBanner(
                                child: ProductCardImage(product: product),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(-.95, .95),
                            child: FittedBox(
                              child: _ProductPriceTag(product: product),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Align(
                      alignment: const Alignment(0, -.5),
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 0.9,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tap area
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                hoverColor: theme.hoverColor,
                splashColor: theme.splashColor,
                highlightColor: theme.highlightColor,
                onTap: () => onTap == null
                    ? context.octopus.pushOnTab(
                        Routes.product,
                        arguments: <String, String>{
                          'id': product.id.toString(),
                        },
                      )
                    : onTap?.call(context, product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCardImage extends StatelessWidget {
  const ProductCardImage({
    required this.product,
    // ignore: unused_element_parameter
    super.key,
  });

  final ProductEntity product;

  ImageProvider<Object> get _imageProvider =>
      (!kIsWeb || Config.environment.isDevelopment
              ? AssetImage(product.thumbnail)
              : NetworkImage('/assets/${product.thumbnail}'))
          as ImageProvider<Object>;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      image: DecorationImage(
        image: _imageProvider,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    ),
  );
  // Widget build(BuildContext context) => ClipRRect(
  //   child: Ink.image(
  //     image: _imageProvider,
  //     fit: BoxFit.cover,
  //     alignment: Alignment.center,
  //   ),
  // );
}

class _ProductPriceTag extends StatelessWidget {
  const _ProductPriceTag({
    required this.product,
    // ignore: unused_element_parameter
    super.key,
  });

  final ProductEntity product;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
    child: CustomPaint(
      painter: const _SlantedRectanglePainter(
        padding: EdgeInsets.only(bottom: 10, right: 10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: DefaultTextStyle(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: const TextStyle(
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: OutlinedText(
                  r'$',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 0,
                  ),
                  strokeWidth: 2,
                  fillColor: Colors.blue,
                  strokeColor: Colors.white,
                ),
              ),
              const SizedBox(width: 1),
              OutlinedText(
                product.price.toStringAsFixed(0),
                style: const TextStyle(
                  letterSpacing: -0.5,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 0,
                ),
                strokeWidth: 4,
                fillColor: Colors.blue,
                strokeColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SlantedRectanglePainter extends CustomPainter {
  const _SlantedRectanglePainter({
    this.padding = EdgeInsets.zero, // ignore: unused_element
    // ignore: unused_element_parameter
    super.repaint,
  });

  final EdgeInsets padding;
  static final Paint _paint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.1 + padding.left, padding.top)
      ..lineTo(size.width - padding.right, padding.top)
      ..lineTo(size.width * 0.9 - padding.right, size.height - padding.bottom)
      ..lineTo(padding.left, size.height - padding.bottom)
      ..close();

    canvas
      ..drawShadow(path, Colors.black, 8, false)
      ..drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _SlantedRectanglePainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(covariant _SlantedRectanglePainter oldDelegate) =>
      false;
}
