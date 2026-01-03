import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// A widget that transitions between two children using a fade and animated
/// size animation.
class FadeSizeTransitionSwitcher extends StatelessWidget {
  const FadeSizeTransitionSwitcher({
    required this.child,
    this.sizeDuration = _duration,
    this.fadeDuration = _duration,
    this.reverseSizeDuration,
    this.reverseFadeDuration,
    this.isForwardMove = true,
    super.key,
  });

  /// The child widget to transition between.
  final Widget child;

  /// The duration of the transition.
  final Duration sizeDuration;

  /// The duration of the fade transition.
  final Duration fadeDuration;

  /// The duration of the reverse size transition.
  final Duration? reverseSizeDuration;

  /// The duration of the reverse fade transition.
  final Duration? reverseFadeDuration;

  /// Whether the transition is forward or backward.
  final bool isForwardMove;

  static const _duration = Duration(milliseconds: 300);
  // static const _sizeCurve = Interval(
  //   0 / 300,
  //   300 / 300,
  //   curve: Curves.fastOutSlowIn,
  // );
  static const _sizeCurve = Cubic(
    0.19919472913616398,
    0.010644531250000006,
    0.27920937042459737,
    0.91025390625,
  );

  Key? get _currentChildKey => child.key;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    alignment: Alignment.topLeft,
    duration: sizeDuration,
    reverseDuration: reverseSizeDuration,
    curve: _sizeCurve,
    child: AnimatedSwitcher(
      duration: fadeDuration,
      reverseDuration: fadeDuration,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        clipBehavior: Clip.none,
        children: [
          ...previousChildren.map(
            (child) => Positioned(left: 0, right: 0, child: child),
          ),
          ?currentChild,
        ],
      ),
      transitionBuilder: (child, animation) => _transitionBuilder(
        child,
        animation,
        context: context,
        currentChildKey: _currentChildKey,
        isForwardMove: isForwardMove,
        textDirection: Directionality.of(context),
      ),
      child: child,
    ),
  );
}

enum _TransitionState { incoming, outgoing }

Widget _transitionBuilder(
  Widget child,
  Animation<double> animation, {
  required BuildContext context,
  required Key? currentChildKey,
  required bool isForwardMove,
  required TextDirection textDirection,
}) {
  final isIncoming = child.key == currentChildKey;

  final state = isIncoming
      ? _TransitionState.incoming
      : _TransitionState.outgoing;

  switch (state) {
    case _TransitionState.incoming:
      return FadeTransition(opacity: animation, child: child);
    case _TransitionState.outgoing:
      return FadeTransition(
        opacity: _FlippedCurveTween(
          curve: Easing.legacyAccelerate,
        ).chain(CurveTween(curve: const Interval(0, 0.3))).animate(animation),
        child: ColoredBox(color: context.theme.canvasColor, child: child),
      );
  }
}

/// Enables creating a flipped [CurveTween].
///
/// This creates a [CurveTween] that evaluates to a result that flips the
/// tween vertically.
///
/// This tween sequence assumes that the evaluated result has to be a double
/// between 0.0 and 1.0.
class _FlippedCurveTween extends CurveTween {
  /// Creates a vertically flipped [CurveTween].
  _FlippedCurveTween({required super.curve});

  @override
  double transform(double t) => 1.0 - super.transform(t);
}
