import 'package:flutter/foundation.dart';
import 'package:presentum/src/state/state.dart';

/// Simple identity contract used by the engine to deduplicate items.
abstract interface class Identifiable {
  /// The unique identifier of the item.
  String get id;
}

/// {@template presentum_variant}
/// One renderable option of an item for a given `surface` and `variant`.
/// {@endtemplate}
@immutable
class PresentumVariant<S extends PresentumSurface, V extends Enum> {
  /// {@macro presentum_variant}
  const PresentumVariant({
    required this.surface,
    required this.variant,
    required this.isDismissible,
    this.stage,
    this.maxImpressions,
    this.cooldownMinutes,
    this.alwaysOnIfEligible = false,
  });

  /// The surface where the variant can be presented.
  final S surface;

  /// The variant of the payload, e.g dialog, banner, inline, etc.
  final V variant;

  /// Sequence hint within a surface (e.g. fullscreen -> dialog).
  final int? stage;

  /// Optional cap on impressions for this presentation.
  final int? maxImpressions;

  /// Optional cooldown in minutes between impressions.
  final int? cooldownMinutes;

  /// Whether this presentation should be shown if it is eligible.
  final bool alwaysOnIfEligible;

  /// Whether this presentation can be dismissed or always enabled (can't be
  /// dismissed)
  ///
  /// [isDismissible] is required, otherwise it is uncertain if the presentation
  /// should can be dismissed or not. It is not reasonable to make it always
  /// false by default, so make sure to provide a value for it.
  final bool isDismissible;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresentumVariant<S, V> &&
        other.surface == surface &&
        other.variant == variant &&
        other.stage == stage &&
        other.maxImpressions == maxImpressions &&
        other.cooldownMinutes == cooldownMinutes &&
        other.alwaysOnIfEligible == alwaysOnIfEligible &&
        other.isDismissible == isDismissible;
  }

  @override
  int get hashCode => Object.hash(
    surface,
    variant,
    stage,
    maxImpressions,
    cooldownMinutes,
    alwaysOnIfEligible,
    isDismissible,
  );
}

/// {@template presentum_payload}
/// Generic payload that contain variants that can be presented across
/// multiple surfaces.
/// {@endtemplate}
abstract class PresentumPayload<S extends PresentumSurface, V extends Enum>
    implements Identifiable {
  /// The unique identifier of the item.
  @override
  abstract final String id;

  /// The priority of the item.
  abstract final int priority;

  /// Arbitrary domain metadata.
  abstract final Map<String, Object?> metadata;

  /// All possible variants of this item.
  abstract final List<PresentumVariant<S, V>> variants;
}

/// {@template resolved_presentum_variant}
/// A concrete decision: "show `payload` with `variant` on `surface` now".
/// {@endtemplate}
@immutable
class ResolvedPresentumVariant<
  TPayload extends PresentumPayload<S, V>,
  S extends PresentumSurface,
  V extends Enum
>
    implements Identifiable {
  /// {@macro resolved_presentum_variant}
  const ResolvedPresentumVariant({
    required this.payload,
    required this.variant,
  });

  /// The payload that was resolved.
  final TPayload payload;

  /// The variant that was resolved.
  final PresentumVariant<S, V> variant;

  @override
  String get id => payload.id;

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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResolvedPresentumVariant<TPayload, S, V> &&
        other.payload == payload &&
        other.variant == variant;
  }

  @override
  int get hashCode => Object.hash(payload, variant);
}
