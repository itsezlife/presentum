import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/assets.gen.dart';
import 'package:example/src/feature/widgets/feature_enabled_wrapper.dart';
import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/widget/shop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

enum FavoriteButtonVariant { regular, pulsating }

/// {@template favorite_button}
/// FavoriteButton widget.
/// {@endtemplate}
class FavoriteButton extends StatelessWidget {
  /// {@macro favorite_button}
  const FavoriteButton({
    required this.productId,
    required this.size,
    super.key,
    this.variant = FavoriteButtonVariant.regular,
  });

  /// {@macro favorite_button}
  const FavoriteButton.pulsating({
    required this.productId,
    this.variant = FavoriteButtonVariant.pulsating,
    super.key,
  }) : size = null;

  final FavoriteButtonVariant variant;
  final ProductID productId;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final status = ShopScope.isFavorite(context, productId, listen: true);
    return RepaintBoundary(
      child: FloatingActionButton(
        onPressed: () {
          if (status) {
            ShopScope.removeFavorite(context, productId);
            HapticFeedback.lightImpact().ignore();
          } else {
            ShopScope.addFavorite(context, productId);
            HapticFeedback.mediumImpact().ignore();
          }
        },
        backgroundColor: status
            ? colorScheme.surfaceContainerHighest
            : colorScheme.primary,
        shape: status
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: colorScheme.primary),
              )
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: switch (variant) {
          FavoriteButtonVariant.regular => FavoriteIconOutlet(filled: status),
          FavoriteButtonVariant.pulsating => _FavoriteHeartBeatIcon(
            favorite: status,
          ),
        },
      ),
    );
  }
}

class _FavoriteHeartBeatIcon extends StatefulWidget {
  const _FavoriteHeartBeatIcon({
    this.favorite = true,
    // ignore: unused_element_parameter
    this.duration = const Duration(milliseconds: 650),
    // ignore: unused_element_parameter
    super.key,
  });

  /// Is the icon currently filled in?
  final bool favorite;

  /// The duration of the animation.
  final Duration duration;

  @override
  State<_FavoriteHeartBeatIcon> createState() => _FavoriteHeartBeatIconState();
}

/// State for widget _FavoriteHeartBeatIcon.
class _FavoriteHeartBeatIconState extends State<_FavoriteHeartBeatIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heartbeat1, _heartbeat2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0,
    );
    _heartbeat1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .75, curve: Curves.easeInOut),
    );
    _heartbeat2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.5, 1, curve: Curves.easeInOut),
    );
    if (!widget.favorite) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _FavoriteHeartBeatIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != _controller.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.favorite != oldWidget.favorite) {
      if (widget.favorite) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: <Widget>[
      if (!widget.favorite)
        Positioned.fill(
          child: FadeTransition(
            opacity: ReverseAnimation(_heartbeat1),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.75).animate(_heartbeat1),
              child: FavoriteIconOutlet(
                filled: false,
                color: Colors.redAccent.withAlpha(127),
                size: 32,
              ),
            ),
          ),
        ),
      if (!widget.favorite)
        Positioned.fill(
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0,
              end: .75,
            ).animate(ReverseAnimation(_heartbeat2)),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.5).animate(_heartbeat2),
              child: FavoriteIconOutlet(
                color: Colors.red.withAlpha(200),
                filled: false,
                size: 28,
              ),
            ),
          ),
        ),
      Positioned.fill(
        key: const ValueKey<String>('_FavoriteHeartBeatIconState#icon'),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.bounceInOut,
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: FavoriteIconOutlet(
            color: widget.favorite
                ? Colors.red
                : context.theme.colorScheme.onPrimary,
            filled: widget.favorite,
            size: widget.favorite ? 36 : 24,
          ),
        ),
      ),
    ],
  );
}

class FavoriteIconOutlet extends StatelessWidget {
  const FavoriteIconOutlet({
    required this.filled,
    this.color,
    super.key,
    this.size = 24,
  });

  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) => HasFeatureCandidatesAndEnabledWrapper(
    featureKey: FeatureId.newYearTheme,
    builder: ({required isEnabled}) => isEnabled
        ? NewYearThemedIcon(size: size, filled: filled, color: color)
        : HeartIcon(size: size, filled: filled, color: color),
  );
}

class HeartIcon extends StatelessWidget {
  const HeartIcon({
    required this.size,
    required this.filled,
    this.color,
    super.key,
  });

  final double size;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    filled ? Icons.favorite : Icons.favorite_border,
    color: color ?? (filled ? Colors.red : context.theme.colorScheme.onPrimary),
    size: size,
  );
}

class NewYearThemedIcon extends StatelessWidget {
  const NewYearThemedIcon({
    required this.size,
    required this.filled,
    this.color,
    super.key,
  });

  final double size;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) => filled
      ? Assets.icons.favoriteButtonFilledSnowyVariant.image(
          width: size * 2,
          height: size * 2,
        )
      : Assets.icons.favoriteButtonOutlinedSnowyVariant.image(
          width: size * 2,
          height: size * 2,
          color: context.theme.colorScheme.onPrimary,
        );
}
