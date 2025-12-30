import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IFeatureCatalogRepository {
  Future<Map<String, FeatureDefinition>?> getFeatures();
  Future<void> updateFeatures(Map<String, FeatureDefinition> features);
  Future<void> markAsRemoved(String featureKey);
  Future<bool> isRemoved(String featureKey);
  Future<void> pruneTo(Set<String> remoteFeatureKeys);
}

final class FeatureCatalogRepositoryImpl implements IFeatureCatalogRepository {
  FeatureCatalogRepositoryImpl({required SharedPreferencesWithCache prefs})
    : _prefs = prefs;

  static const String _featuresKey = 'feature_catalog_features';
  static const String _removedFeaturesKey = 'feature_catalog_removed';

  final SharedPreferencesWithCache _prefs;

  @override
  Future<Map<String, FeatureDefinition>?> getFeatures() async {
    final featuresJson = _prefs.getString(_featuresKey);

    if (featuresJson == null) return null;

    try {
      final decoded = jsonDecode(featuresJson) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          FeatureDefinition.fromJson(value as Map<String, dynamic>),
        ),
      );
    } on Object catch (error, stackTrace) {
      await ErrorUtil.logError(error, stackTrace);
      return null;
    }
  }

  @override
  Future<void> updateFeatures(Map<String, FeatureDefinition> features) async {
    final featuresJson = jsonEncode(
      features.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _prefs.setString(_featuresKey, featuresJson);

    // Remove any of these features from the removed list
    // (user re-added them)
    final removedKeys = await _getRemovedFeatureKeys();
    final updatedRemovedKeys = removedKeys.difference(features.keys.toSet());
    await _saveRemovedKeys(updatedRemovedKeys);
  }

  @override
  Future<void> markAsRemoved(String featureKey) async {
    // Add to removed list
    final removedKeys = await _getRemovedFeatureKeys();
    removedKeys.add(featureKey);
    await _saveRemovedKeys(removedKeys);

    // Remove from active features
    final currentFeatures = await getFeatures() ?? {}
      ..remove(featureKey);
    final featuresJson = jsonEncode(
      currentFeatures.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _prefs.setString(_featuresKey, featuresJson);
  }

  @override
  Future<bool> isRemoved(String featureKey) async {
    final removedKeys = await _getRemovedFeatureKeys();
    return removedKeys.contains(featureKey);
  }

  Future<Set<String>> _getRemovedFeatureKeys() async {
    final removedJson = _prefs.getString(_removedFeaturesKey);

    if (removedJson == null) return {};

    try {
      final decoded = jsonDecode(removedJson) as List<dynamic>;
      return decoded.cast<String>().toSet();
    } on Object catch (error, stackTrace) {
      await ErrorUtil.logError(error, stackTrace);
      return {};
    }
  }

  Future<void> _saveRemovedKeys(Set<String> keys) async {
    final removedJson = jsonEncode(keys.toList());
    await _prefs.setString(_removedFeaturesKey, removedJson);
  }

  @override
  Future<void> pruneTo(Set<String> remoteFeatureKeys) async {
    final removedKeys = await _getRemovedFeatureKeys();

    // Remove overrides for features not in remote config
    final cleanedRemoved = removedKeys.intersection(remoteFeatureKeys);

    await _saveRemovedKeys(cleanedRemoved);
  }
}
