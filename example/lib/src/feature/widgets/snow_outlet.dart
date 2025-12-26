import 'package:example/src/common/widgets/snow.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class SnowOutlet extends StatelessWidget {
  const SnowOutlet({
    required this.child,
    super.key,
    this.flakeCount = 140,
    this.minSpeed = 16,
    this.maxSpeed = 64,
    this.minRadius = 1,
    this.maxRadius = 4,
    this.windStrength = 20,
    this.swayStrength = 24,
    this.meltDuration = const Duration(seconds: 10),
    this.color = const Color(0xFFF8FBFF),
  });

  final Widget child;
  final int flakeCount;
  final double minSpeed;
  final double maxSpeed;
  final double minRadius;
  final double maxRadius;
  final double windStrength;
  final double swayStrength;
  final Duration meltDuration;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PresentumOutlet<FeatureItem, AppSurface, AppVariant>(
        surface: AppSurface.background,
        placeholderBuilder: (_) => child,
        builder: (context, item) => switch (item.variant) {
          AppVariant.snow => Snow(
            flakeCount: flakeCount,
            minSpeed: minSpeed,
            maxSpeed: maxSpeed,
            minRadius: minRadius,
            maxRadius: maxRadius,
            windStrength: windStrength,
            swayStrength: swayStrength,
            meltDuration: meltDuration,
            color: color,
            child: child,
          ),
          _ => child,
        },
      );
}
