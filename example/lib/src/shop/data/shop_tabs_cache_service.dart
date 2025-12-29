import 'dart:convert';

import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs.dart';
import 'package:octopus/octopus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Restore cached nested navigation on tab switch
class ShopTabsCacheService {
  ShopTabsCacheService({required SharedPreferencesWithCache sharedPreferences})
    : _prefs = sharedPreferences;

  static const String _key = 'shop.tabs';

  final SharedPreferencesWithCache _prefs;

  static const _homeTab = HomeAppTab();

  static final _catalogTab = _homeTab.tabRouteName(Routes.catalog);
  static final _basketTab = _homeTab.tabRouteName(Routes.basket);
  static final _settingsRoute = Routes.settings.name;

  /// Save nested navigation to cache
  Future<void> save(OctopusState state) async {
    try {
      final argument = state.arguments[_homeTab.identifier];
      final home = state.findByName(_homeTab.root.name);
      if (home == null) return;
      final catalog = home.findByName(_catalogTab);
      final basket = home.findByName(_basketTab);
      final json = <String, Object?>{
        if (argument case final arg when arg != _settingsRoute) 'tab': argument,
        if (catalog != null) 'catalog': catalog.toJson(),
        if (basket != null) 'basket': basket.toJson(),
      };
      if (json.isEmpty) return;
      await _prefs.setString(_key, jsonEncode(json));
    } on Object {
      /* ignore */
    }
  }

  /// Restore nested navigation from cache
  Future<OctopusState$Mutable?> restore(OctopusState$Mutable state) async {
    final home = state.findByName(_homeTab.root.name);
    if (home == null) return null; // Do nothing if `home` not found.
    try {
      final jsonRaw = _prefs.getString(_key);
      if (jsonRaw == null) return null;
      final json = jsonDecode(jsonRaw);
      if (json case Map<String, Object?> data) {
        if (data['tab'] case String tab)
          state.arguments[_homeTab.identifier] = tab;
        if (data['catalog'] case Map<String, Object?> catalog)
          home.putIfAbsent(_catalogTab, () => OctopusNode.fromJson(catalog));
        if (data['basket'] case Map<String, Object?> basket)
          home.putIfAbsent(_basketTab, () => OctopusNode.fromJson(basket));
        return state;
      }
    } on Object {
      /* ignore */
    }
    return null;
  }

  Future<void> clear() => _prefs.remove(_key);
}
