import 'package:example/src/campaigns/camapigns.dart';
import 'package:presentum/presentum.dart';

final class CampaignPresentumOption
    extends PresentumOption<CampaignSurface, CampaignVariant> {
  const CampaignPresentumOption({
    required this.surface,
    required this.variant,
    required this.isDismissible,
    this.stage,
    this.maxImpressions,
    this.cooldownMinutes,
    this.alwaysOnIfEligible = false,
  });

  @override
  final CampaignSurface surface;

  @override
  final CampaignVariant variant;

  @override
  final bool isDismissible;

  @override
  final int? stage;

  @override
  final int? maxImpressions;

  @override
  final int? cooldownMinutes;

  @override
  final bool alwaysOnIfEligible;
}

/// Domain payload for campaigns used by the presentum engine.
///
/// Sample JSON payload:
/// ```json
/// [
///   {
///     "id": "cyber_monday_2025",
///     "priority": 1000,
///     "metadata": {
///       "any_of": [
///         {
///           "time_range": {
///             "start": "2025-12-14T16:14:00Z",
///             "end": "2025-12-25T15:55:00Z"
///           }
///         },
///         {
///           "is_active": true
///         }
///       ],
///       "discount": {
///         "max_discount": 80
///       }
///     },
///     "options": [
///       {
///         "surface": "homeTopBanner",
///         "variant": "inline",
///         "is_dismissible": true,
///         "stage": 0,
///         "always_on_if_eligible": true
///       },
///       {
///         "surface": "popup",
///         "variant": "fullscreenDialog",
///         "is_dismissible": true,
///         "stage": 1,
///         "max_impressions": 1,
///         "always_on_if_eligible": false
///       },
///       {
///         "surface": "popup",
///         "variant": "dialog",
///         "is_dismissible": true,
///         "stage": 2,
///         "cooldown_minutes": 10,
///         "always_on_if_eligible": false
///       },
///       {
///         "surface": "homeFooterBanner",
///         "variant": "inline",
///         "is_dismissible": false,
///         "always_on_if_eligible": true
///       },
///       {
///         "surface": "menuTile",
///         "variant": "inline",
///         "is_dismissible": false,
///         "always_on_if_eligible": true
///       }
///     ]
///   }
/// ]
/// ```
class CampaignPayload extends PresentumPayload<CampaignSurface, CampaignVariant>
    implements HasMetadata {
  const CampaignPayload({
    required this.id,
    required this.priority,
    required this.metadata,
    required this.options,
  });

  /// Create payload from JSON with pattern matching.
  factory CampaignPayload.fromJson(Map<String, Object?> json) {
    final String id;
    if (json['id'] case final String v) {
      id = v;
    } else {
      throw ArgumentError.value(json['id'], 'id', 'Expected string id');
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

    final List<CampaignPresentumOption> options;
    // ignore: strict_raw_type
    if (json['options'] case final Iterable list) {
      options = <CampaignPresentumOption>[
        for (final item in list)
          if (item case <String, Object?>{
            'surface': final String surface,
            'variant': final String variant,
            'is_dismissible': final bool isDismissible,
          })
            CampaignPresentumOption(
              surface: CampaignSurface.fromName(surface),
              variant: CampaignVariant.fromName(variant),
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
      options = const <CampaignPresentumOption>[];
    }

    return CampaignPayload(
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
  final List<CampaignPresentumOption> options;
}

extension type CampaignId(String value) {
  static const blackFriday2025 = 'black_friday_2025';
  static const cyberMonday2025 = 'cyber_monday_2025';

  static const values = <String>[blackFriday2025, cyberMonday2025];

  static bool isSupported(String id) => values.contains(id);
}

class CampaignPresentumItem
    extends PresentumItem<CampaignPayload, CampaignSurface, CampaignVariant> {
  const CampaignPresentumItem({required this.payload, required this.option});

  @override
  final CampaignPayload payload;

  @override
  final CampaignPresentumOption option;
}
