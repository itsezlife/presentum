import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/state.dart';

/// {@template presentum_variant}
/// One renderable option of an item for a given `surface` and `variant`.
/// {@endtemplate}
@immutable
abstract class PresentumVariant<
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro presentum_variant}
  const PresentumVariant();

  /// The surface where the variant can be presented.
  abstract final S surface;

  /// The variant of the payload, e.g dialog, banner, inline, etc.
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
      'PresentumVariant(surface: $surface, variant: $variant, stage: $stage, '
      'maxImpressions: $maxImpressions, cooldownMinutes: $cooldownMinutes, '
      'alwaysOnIfEligible: $alwaysOnIfEligible, isDismissible: $isDismissible)';
}

/// {@template presentum_payload}
/// Generic payload that contain variants that can be presented across
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

  /// All possible variants of this item.
  abstract final List<PresentumVariant<S, V>> variants;

  @override
  String toString() =>
      'PresentumPayload(id: $id, priority: $priority, metadata: $metadata, '
      'variants: $variants)';
}

/// {@template resolved_presentum_variant}
/// A concrete decision: "show `payload` with `variant` on `surface` now".
/// {@endtemplate}
abstract class ResolvedPresentumVariant<
  TPayload extends PresentumPayload<S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
> {
  /// {@macro resolved_presentum_variant}
  const ResolvedPresentumVariant();

  /// The payload that was resolved.
  abstract final TPayload payload;

  /// The variant that was resolved.
  abstract final PresentumVariant<S, V> variant;

  /// The unique identifier of the resolved variant.
  String get id =>
      '${payload.id}::${visualVariant.name}::${variant.surface.name}';

  /// The priority of the item.
  int get priority => payload.priority;

  /// Arbitrary domain metadata.
  Map<String, Object?> get metadata => payload.metadata;

  /// The surface where the variant can be presented.
  S get surface => variant.surface;

  /// The variant of the payload, e.g dialog, banner, inline, etc.
  V get visualVariant => variant.variant;

  /// Sequence hint within a surface (e.g. fullscreen -> dialog).
  int? get stage => variant.stage;

  @override
  String toString() =>
      'ResolvedPresentumVariant(payload: $payload, variant: $variant)';
}
