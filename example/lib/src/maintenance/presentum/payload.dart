import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class MaintenanceOption extends PresentumOption<AppSurface, AppVariant> {
  const MaintenanceOption({
    required this.surface,
    required this.variant,
    required this.isDismissible,
    this.maxImpressions,
    this.cooldownMinutes,
    this.stage,
    this.alwaysOnIfEligible = true,
  });

  @override
  final AppSurface surface;

  @override
  final AppVariant variant;

  @override
  final bool alwaysOnIfEligible;

  @override
  final bool isDismissible;

  @override
  final int? maxImpressions;

  @override
  final int? cooldownMinutes;

  @override
  final int? stage;
}

@immutable
final class MaintenancePayload
    extends PresentumPayload<AppSurface, AppVariant> {
  const MaintenancePayload({
    required this.id,
    required this.priority,
    required this.options,
    required this.metadata,
  });

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<MaintenanceOption> options;

  /// Time remaining until maintenance ends (null if not started or no window)
  Duration? get timeUntilEnd {
    final timeRange = metadata['time_range'] as Map<String, dynamic>?;
    if (timeRange == null) return null;

    final startTime = timeRange['start'] as DateTime?;
    final endTime = timeRange['end'] as DateTime?;

    if (endTime == null || startTime == null) return null;

    final now = DateTime.now();
    if (now.isBefore(startTime)) return null;
    if (now.isAfter(endTime)) return Duration.zero;

    return endTime.difference(now);
  }
}

@immutable
final class MaintenanceItem
    extends PresentumItem<MaintenancePayload, AppSurface, AppVariant> {
  const MaintenanceItem({required this.payload, required this.option});

  @override
  final MaintenancePayload payload;

  @override
  final MaintenanceOption option;
}
