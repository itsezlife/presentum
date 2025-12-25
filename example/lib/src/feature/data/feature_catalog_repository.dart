import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IFeatureCatalogRepository {
  Future<Map<String, FeatureDefinition>?> getFeatures();
  Future<void> updateFeatures(Map<String, FeatureDefinition> features);
}

final class FeatureCatalogRepositoryImpl implements IFeatureCatalogRepository {
  FeatureCatalogRepositoryImpl({required SharedPreferencesWithCache prefs})
    : _prefs = prefs;

  static const String _featuresKey = 'feature_catalog_features';

  final SharedPreferencesWithCache _prefs;

  @override
  Future<Map<String, FeatureDefinition>?> getFeatures() async {
    final featuresJson = _prefs.getString(_featuresKey);

    if (featuresJson == null) return null;

    try {
      final decoded = jsonDecode(featuresJson) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, FeatureDefinition.fromJson(value)),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateFeatures(Map<String, FeatureDefinition> features) async {
    final featuresJson = jsonEncode(
      features.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _prefs.setString(_featuresKey, featuresJson);
  }
}
