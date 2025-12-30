import 'package:example/src/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

/// {@template shop_back_button}
/// ShopBackButton widget.
/// {@endtemplate}
class ShopBackButton extends StatelessWidget {
  /// {@macro shop_back_button}
  const ShopBackButton({super.key});

  @override
  Widget build(BuildContext context) => BackButton(
    onPressed: () {
      if (Navigator.canPop(context)) {
        Navigator.maybePop(context);
        return;
      }
      // Fallback: on back button pressed, close shop tabs
      final router = Octopus.maybeOf(context);
      if (router == null) return;
      final home = router.state.find((route) => route.name == Routes.home.name);
      if (home == null) {
        router.setState((state) => state..removeLast());
      } else {
        router.setState(
          (state) =>
              state..removeWhere((route) => route.name == Routes.home.name),
        );
      }
    },
  );
}
