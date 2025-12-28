import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

@immutable
final class AppUpdatesOption extends PresentumOption<AppSurface, AppVariant> {
  const AppUpdatesOption({
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
final class AppUpdatesPayload extends PresentumPayload<AppSurface, AppVariant> {
  const AppUpdatesPayload({
    required this.id,
    required this.priority,
    required this.options,
    this.metadata = const {},
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<AppUpdatesOption> options;
}

@immutable
final class AppUpdatesItem
    extends PresentumItem<AppUpdatesPayload, AppSurface, AppVariant> {
  const AppUpdatesItem({required this.payload, required this.option});

  @override
  final AppUpdatesPayload payload;

  @override
  final AppUpdatesOption option;
}
