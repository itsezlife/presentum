import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_option}
/// One renderable option of an item for a given `surface` and visual `variant` 
/// style.
/// {@endtemplate}
@immutable
abstract class PresentumOption<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_option}
  const PresentumOption();

  /// The surface where the option can be presented.
  abstract final S surface;

  /// The visual variant of presentation, e.g dialog, banner, inline, etc.
  abstract final V variant;

  /// Sequence hint within a surface (e.g. fullscreen -> dialog).
  abstract final int? stage;

  /// Optional cap on impressions for this presentation.
  abstract final int? maxImpressions;

  /// Optional cooldown in minutes between impressions.
  abstract final int? cooldownMinutes;

  /// Whether this presentation should be shown if it is eligible.
  abstract final bool alwaysOnIfEligible;

  /// Whether this presentation can be dismissed.
  abstract final bool isDismissible;

  @override
  String toString() =>
      'PresentumOption(surface: $surface, variant: $variant, stage: $stage, '
      'maxImpressions: $maxImpressions, cooldownMinutes: $cooldownMinutes, '
      'alwaysOnIfEligible: $alwaysOnIfEligible, isDismissible: $isDismissible)';
}

/// {@template presentum_payload}
/// Generic payload that contain options that can be presented across
/// multiple surfaces.
/// {@endtemplate}
abstract class PresentumPayload<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_payload}
  const PresentumPayload();

  /// The unique identifier of the item.
  abstract final String id;

  /// The priority of the item.
  abstract final int priority;

  /// Arbitrary domain metadata.
  abstract final Map<String, Object?> metadata;

  /// All possible presentation options for this item.
  abstract final List<PresentumOption<S, V>> options;

  @override
  String toString() =>
      'PresentumPayload(id: $id, priority: $priority, metadata: $metadata, '
      'options: $options)';
}

/// {@template presentum_item}
/// A concrete decision: "show `payload` with `option` on `surface` now".
/// {@endtemplate}
abstract class PresentumItem<
  TPayload extends PresentumPayload<S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_item}
  const PresentumItem();

  /// The payload that was resolved.
  abstract final TPayload payload;

  /// The exact option chosen to present the payload.
  abstract final PresentumOption<S, V> option;

  /// The unique identifier of the item.
  String get id =>
      '${payload.id}::${option.variant.name}::${option.surface.name}';

  /// The priority of the item.
  int get priority => payload.priority;

  /// Arbitrary domain metadata.
  Map<String, Object?> get metadata => payload.metadata;

  /// The surface where the option can be presented.
  S get surface => option.surface;

  /// The visual style of the presentation, e.g dialog, banner, inline, etc.
  V get variant => option.variant;

  /// Sequence hint within a surface (e.g. fullscreen -> dialog).
  int? get stage => option.stage;

  @override
  String toString() => 'PresentumItem(payload: $payload, option: $option)';
}
