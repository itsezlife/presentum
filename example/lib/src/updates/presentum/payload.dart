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
final class MaintenancePayload
    extends PresentumPayload<AppSurface, AppVariant> {
  const MaintenancePayload({
    required this.id,
    required this.priority,
    required this.options,
    required this.isActive,
    this.startTime,
    this.endTime,
    this.enableRestartButton = false,
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

  /// Whether maintenance mode is explicitly active
  final bool isActive;

  /// Optional maintenance window start time
  final DateTime? startTime;

  /// Optional maintenance window end time
  final DateTime? endTime;

  /// Whether to show the restart button after countdown reaches 00
  final bool enableRestartButton;

  /// Whether we're currently in the maintenance window
  bool get isInMaintenanceWindow {
    if (!isActive) return false;

    // If no time window is specified, just check isActive flag
    if (startTime == null || endTime == null) return true;

    final now = DateTime.now();
    return now.isAfter(startTime!) && now.isBefore(endTime!);
  }

  /// Time remaining until maintenance starts (null if already started or no window)
  Duration? get timeUntilStart {
    if (startTime == null) return null;

    final now = DateTime.now();
    if (now.isAfter(startTime!)) return null;

    return startTime!.difference(now);
  }

  /// Time remaining until maintenance ends (null if not started or no window)
  Duration? get timeUntilEnd {
    if (endTime == null || startTime == null) return null;

    final now = DateTime.now();
    if (now.isBefore(startTime!)) return null;
    if (now.isAfter(endTime!)) return Duration.zero;

    return endTime!.difference(now);
  }
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

@immutable
final class MaintenanceItem
    extends PresentumItem<MaintenancePayload, AppSurface, AppVariant> {
  const MaintenanceItem({required this.payload, required this.option});

  @override
  final MaintenancePayload payload;

  @override
  final AppUpdatesOption option;
}
