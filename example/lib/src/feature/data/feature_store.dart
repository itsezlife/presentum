import 'package:example/src/feature/data/feature_repository.dart';
import 'package:flutter/foundation.dart';

final class FeaturePreferencesStore extends ChangeNotifier {
  FeaturePreferencesStore({required this.repo});

  final IFeaturePreferencesRepository repo;

  Map<String, bool> _overrides = <String, bool>{};

  bool? overrideFor(String featureKey) => _overrides[featureKey];

  Future<void> init() async {
    _overrides = await repo.loadOverrides();
    notifyListeners();
  }

  Future<void> setEnabled(String featureKey, bool enabled) async {
    _overrides[featureKey] = enabled;
    await repo.saveOverrides(_overrides);
    notifyListeners();
  }

  /// Cleanup: if a feature disappears from the catalog, remove its override too.
  Future<void> pruneTo(Set<String> existingFeatureKeys) async {
    final before = _overrides.length;
    _overrides.removeWhere((k, _) => !existingFeatureKeys.contains(k));
    if (_overrides.length == before) return;
    notifyListeners();
    await repo.saveOverrides(_overrides);
  }
}
