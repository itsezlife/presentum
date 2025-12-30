import 'dart:math' as math;

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:flutter/material.dart';

/// {@template scaffold_padding}
/// ScaffoldPadding widget.
/// {@endtemplate}
class ScaffoldPadding extends EdgeInsets {
  const ScaffoldPadding._(final double value)
    : super.symmetric(horizontal: value);

  /// {@macro scaffold_padding}
  factory ScaffoldPadding.of(
    BuildContext context, {
    double horizontalPadding = AppSpacing.lg,
  }) => ScaffoldPadding._(
    math.max(
      (MediaQuery.widthOf(context) - Config.maxScreenLayoutWidth) / 2,
      horizontalPadding,
    ),
  );

  /// {@macro scaffold_padding}
  static Widget widget(
    BuildContext context, {
    double horizontalPadding = AppSpacing.lg,
    Widget? child,
  }) => Padding(
    padding: ScaffoldPadding.of(context, horizontalPadding: horizontalPadding),
    child: child,
  );

  /// {@macro scaffold_padding}
  static Widget sliver(
    BuildContext context, {
    double horizontalPadding = AppSpacing.lg,
    Widget? child,
  }) => SliverPadding(
    padding: ScaffoldPadding.of(context, horizontalPadding: horizontalPadding),
    sliver: child,
  );
}
