import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IFeaturePreferencesRepository {
  Future<Map<String, bool>> loadOverrides();
  Future<void> saveOverrides(Map<String, bool> overrides);
}

class FeaturePreferencesRepositoryImpl
    implements IFeaturePreferencesRepository {
  FeaturePreferencesRepositoryImpl({required this.prefs});

  final SharedPreferencesWithCache prefs;

  static const _storageKey = 'presentum.feature_overrides.v1';

  @override
  Future<Map<String, bool>> loadOverrides() async {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, bool>{};

    final decoded = jsonDecode(raw) as Map<String, Object?>;
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  @override
  Future<void> saveOverrides(Map<String, bool> overrides) async {
    await prefs.setString(_storageKey, jsonEncode(overrides));
  }
}
