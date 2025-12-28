import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

extension type MaintenanceId(String id) {
  static const maintenance = 'maintenance';

  static const all = [maintenance];
}

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

/// Maintenance payload supports various eligibility conditions in metadata:
/// 
/// If you want, you can add platform specific conditions, versions, 
/// feature flags, etc:
/// 
/// Show maintenance only on iOS and Android:
/// ```json
/// {
///   "platform_pattern": {
///     "context_key": "platform",
///     "pattern": "^(ios|android)$",
///     "case_sensitive": false
///   }
/// }
/// ```
/// 
/// Show maintenance only for versions 1.0.0 and 1.1.0:
/// ```json
/// {
///   "string_match": {
///     "context_key": "app_version",
///     "pattern": "^1\\.(0|1)\\.",
///     "case_sensitive": true
///   }
/// }
/// ```
///
/// Sample payload for maintenance, that you can publish to remote config:
/// 
/// Note: this payload uses the `any_of` rule, which means that the maintenance 
/// will be shown if either time range matches or `is_active` is explicitly set
/// to true. Consider using `is_active` primarily for testing purposes, 
/// it is totally up to you.
/// ```json
/// {
///   "id": "maintenance",
///   "priority": 1000,
///   "metadata": {
///     "any_of": [
///       {
///         "time_range": {
///           "start": "2025-12-28T00:00:00Z",
///           "end": "2025-12-28T16:28:00Z"
///         }
///       },
///       {"is_active": true}
///     ]
///   },
///   "options": [
///     {
///       "surface": "maintenanceView",
///       "variant": "maintenanceScreen",
///       "is_dismissible": false,
///       "always_on_if_eligible": true
///     },
///     {
///       "surface": "maintenanceView",
///       "variant": "maintenanceScreenRestartButton",
///       "is_dismissible": false,
///       "always_on_if_eligible": true
///     }
///   ]
/// }
/// ```
@immutable
final class MaintenancePayload
    extends PresentumPayload<AppSurface, AppVariant> {
  const MaintenancePayload({
    required this.id,
    required this.priority,
    required this.options,
    required this.metadata,
  });

  factory MaintenancePayload.fromJson(Map<String, dynamic> json) {
    final String id;
    if (json['id'] case final String v when MaintenanceId.all.contains(v)) {
      id = v;
    } else {
      throw ArgumentError.value(
        json['id'],
        'id',
        'Expected valid string, supported ids: ${MaintenanceId.all.join(', ')}',
      );
    }

    final priority = (json['priority'] as num?)?.toInt() ?? 0;

    final Map<String, Object?> metadata;
    // ignore: strict_raw_type
    if (json['metadata'] case final Map m) {
      metadata = <String, Object?>{
        for (final e in m.entries) e.key.toString(): e.value,
      };
    } else {
      metadata = const <String, Object?>{};
    }

    final List<MaintenanceOption> options;
    // ignore: strict_raw_type
    if (json['options'] case final Iterable list) {
      options = <MaintenanceOption>[
        for (final item in list)
          if (item case <String, Object?>{
            'surface': final String surface,
            'variant': final String variant,
            'is_dismissible': final bool isDismissible,
          })
            MaintenanceOption(
              surface: AppSurface.fromName(surface),
              variant: AppVariant.fromName(variant),
              isDismissible: isDismissible,
              stage: item['stage'] as int?,
              maxImpressions: item['max_impressions'] as int?,
              cooldownMinutes: item['cooldown_minutes'] as int?,
              alwaysOnIfEligible:
                  item['always_on_if_eligible'] as bool? ?? false,
            )
          else
            throw FormatException('Invalid campaign json: $item'),
      ];
    } else {
      options = const <MaintenanceOption>[];
    }

    return MaintenancePayload(
      id: id,
      priority: priority,
      metadata: metadata,
      options: options,
    );
  }

  @override
  final String id;

  @override
  final int priority;

  @override
  final Map<String, Object?> metadata;

  @override
  final List<MaintenanceOption> options;

  /// Time remaining until maintenance ends (null if not started or no window)
  ///
  /// Tries to extract the time remaining from the flat metadata first,
  /// then falls back to extracting from the nested structure.
  Duration? get timeUntilEnd => metadata.maybeGetFlatOrNested<Duration>(
    MetadataKeys.anyOf,
    (map) => map.timeUntilEnd,
  );

  /// Tries to extract the active flag from the flat metadata first,
  /// then falls back to extracting from the nested structure.
  bool? get isActive => metadata.maybeGetFlatOrNested<bool>(
    MetadataKeys.anyOf,
    (map) => map.getBoolFlag(MetadataKeys.isActive),
  );
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
