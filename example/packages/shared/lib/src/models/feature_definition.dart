// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';

/// {@template feature_id}
/// A stable identifier for a feature.
/// {@endtemplate}
extension type FeatureId(String value) {
  /// New Year theme feature id.
  static const String newYear = 'newYear';

  /// All feature ids.
  static const List<String> all = [newYear];
}

/// {@template feature_definition}
/// A definition of a feature. It is used to define a feature in the feature
/// catalog.
/// {@endtemplate}
@immutable
final class FeatureDefinition {
  /// {@macro feature_definition}
  const FeatureDefinition({
    required this.key,
    this.defaultEnabled = true,
    this.order = 0,
  });

  /// Create a feature definition from a JSON map.
  factory FeatureDefinition.fromJson(Map<String, dynamic> json) {
    if (json case <String, dynamic>{
      'key': final String key,
      'defaultEnabled': final bool? defaultEnabled,
      'order': final int? order,
    }) {
      return FeatureDefinition(
        key: key,
        defaultEnabled: defaultEnabled ?? true,
        order: order ?? 0,
      );
    } else {
      throw FormatException('Invalid feature definition JSON: $json');
    }
  }

  /// Stable identifier (also safe as a sort tie-breaker).
  final String key;

  /// Whether the feature is enabled by default.
  final bool defaultEnabled;

  /// Optional ordering hint for Settings (0 by default).
  /// Lower comes first. Avoid ordering by localized titles.
  final int order;

  /// Convert the feature definition to a JSON map.
  Map<String, dynamic> toJson() => {
    'key': key,
    'defaultEnabled': defaultEnabled,
    'order': order,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureDefinition &&
          key == other.key &&
          defaultEnabled == other.defaultEnabled &&
          order == other.order;

  @override
  int get hashCode => Object.hash(key, defaultEnabled, order);

  @override
  String toString() =>
      'FeatureDefinition(key: $key, defaultEnabled: $defaultEnabled, order: $order)';
}
