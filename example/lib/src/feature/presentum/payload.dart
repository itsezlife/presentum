import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

@immutable
final class FeatureOption extends PresentumOption<AppSurface, AppVariant> {
  const FeatureOption({
    required this.surface,
    required this.variant,
    required this.isDismissible,
    this.stage,
    this.maxImpressions,
    this.cooldownMinutes,
    this.alwaysOnIfEligible = true,
  });

  @override
  final AppSurface surface;

  @override
  final AppVariant variant;

  @override
  final int? stage;

  @override
  final int? maxImpressions;

  @override
  final int? cooldownMinutes;

  @override
  final bool alwaysOnIfEligible;

  @override
  final bool isDismissible;
}

@immutable
final class FeaturePayload extends PresentumPayload<AppSurface, AppVariant> {
  const FeaturePayload({
    required this.id,
    required this.priority,
    required this.options,
    required this.featureKey,
    this.metadata = const {},
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<PresentumOption<AppSurface, AppVariant>> options;

  /// The feature this presentation belongs to (used by the preference guard).
  final String featureKey;
}

@immutable
final class FeatureItem
    extends PresentumItem<FeaturePayload, AppSurface, AppVariant> {
  const FeatureItem({required this.payload, required this.option});

  @override
  final FeaturePayload payload;

  @override
  final PresentumOption<AppSurface, AppVariant> option;
}
