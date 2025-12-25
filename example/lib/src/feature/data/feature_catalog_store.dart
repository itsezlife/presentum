import 'dart:developer' as dev;

import 'package:example/src/feature/data/feature_catalog_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

const Map<String, FeatureDefinition> existingFeatures = {
  FeatureId.newYear: FeatureDefinition(
    key: FeatureId.newYear,
    defaultEnabled: true,
  ),
};

final class FeatureCatalogStore extends ChangeNotifier {
  FeatureCatalogStore({required IFeatureCatalogRepository repository})
    : _repository = repository;

  final IFeatureCatalogRepository _repository;

  Map<String, FeatureDefinition> _features = const {};

  Map<String, FeatureDefinition> get features => _features;
  bool exists(String key) => _features.containsKey(key);

  Future<void> init() async {
    final savedFeatures = await _repository.getFeatures();
    if (savedFeatures != null) {
      _features = savedFeatures;
      notifyListeners();
    } else {
      _features = existingFeatures;
      notifyListeners();
      _saveFeatures();
    }
  }

  void replaceAll(Iterable<FeatureDefinition> list) {
    _features = {for (final f in list) f.key: f};
    notifyListeners();
    _saveFeatures();
  }

  void add(String key, {FeatureDefinition? feature}) {
    final newFeature = feature ?? existingFeatures[key];
    if (newFeature == null) {
      dev.log(
        'Feature $key not found in existing features',
        level: 500,
        name: 'FeatureCatalogStore',
      );
      return;
    }
    _features = {..._features, newFeature.key: newFeature};
    notifyListeners();
    _saveFeatures();
  }

  void remove(String key) {
    _features = Map.from(_features)..remove(key);
    notifyListeners();
    _saveFeatures();
  }

  void _saveFeatures() {
    _repository.updateFeatures(_features);
  }
}
