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
    this.dependsOnFeatureKey,
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

  /// The feature key this payload depends on. For feature settings
  /// payloads it is null, otherwise it'll create circular dependencies.
  ///
  /// You can use this key to make this payload dependent on the feature key.
  ///
  /// If the key is not null and feature key exists in the catalog, this
  /// payload will only be shown if the feature is enabled and payload is
  /// eligible.
  ///
  /// Otherwise, if the this key is null, this payload doesn't care about
  /// the feature being existed or not. But, if the feature exists and it is
  /// not enabled by [featureKey], this payload will not be shown.
  ///
  /// So, this is primarily useful if you want to remove the feature and not
  /// being available in the settings, but want to enable the payload even
  /// when the feature is not available.
  final String? dependsOnFeatureKey;
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
