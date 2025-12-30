import 'package:shared_preferences/shared_preferences.dart';

/// {@template user_repository}
/// Very simple and dummy user repository just to get app opened count.
/// {@endtemplate}
class UserRepository {
  const UserRepository({required SharedPreferencesWithCache prefs})
    : _prefs = prefs;

  static const _appOpenedCountKey = 'user.app.opened_count';

  final SharedPreferencesWithCache _prefs;

  Future<int> fetchAppOpenedCount() async =>
      _prefs.getInt(_appOpenedCountKey) ?? 0;

  Future<void> incrementAppOpenedCount() async {
    final count = await fetchAppOpenedCount();
    await _prefs.setInt(_appOpenedCountKey, count + 1);
  }

  Future<void> resetAppOpenedCount() async =>
      await _prefs.setInt(_appOpenedCountKey, 0);
}
