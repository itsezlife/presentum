import 'dart:async';

import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AppUpdatesStorageKey = (
  String itemId,
  AppSurface surface,
  AppVariant variant,
);

extension type AppUpdatesStorageKeys(AppUpdatesStorageKey key) {
  String get shownCount =>
      '__shown_${key.$1}_${key.$2.name}_${key.$3.name}_count_key__';
  String get lastShown =>
      '__shown_${key.$1}_${key.$2.name}_${key.$3.name}_last_shown_key__';
  String get timestamps =>
      '__shown_${key.$1}_${key.$2.name}_${key.$3.name}_timestamps_key__';
  String get dismissedAt =>
      '__dismissed_${key.$1}_${key.$2.name}_${key.$3.name}_at_key__';
  String get convertedAt =>
      '__converted_${key.$1}_${key.$2.name}_${key.$3.name}_at_key__';

  List<String> get allKeys => [
    shownCount,
    lastShown,
    timestamps,
    dismissedAt,
    convertedAt,
  ];
}

class AppUpdatesPresentumStorage
    implements PresentumStorage<AppSurface, AppVariant> {
  AppUpdatesPresentumStorage({required SharedPreferencesWithCache prefs})
    : _prefs = prefs;

  final SharedPreferencesWithCache _prefs;

  @override
  Future<void> clearItem(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
  }) => Future.wait(
    AppUpdatesStorageKeys((
      itemId,
      surface,
      variant,
    )).allKeys.map(_prefs.remove),
  );

  @override
  FutureOr<DateTime?> getLastShown(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
  }) async {
    final key = AppUpdatesStorageKeys((itemId, surface, variant)).lastShown;
    final timestampStr = _prefs.getString(key);
    return timestampStr != null ? DateTime.parse(timestampStr) : null;
  }

  @override
  FutureOr<void> recordShown(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
    required DateTime at,
  }) async {
    final keys = AppUpdatesStorageKeys((itemId, surface, variant));
    final countKey = keys.shownCount;
    final lastShownKey = keys.lastShown;
    final timestampsKey = keys.timestamps;

    final currentCount = _prefs.getInt(countKey) ?? 0;
    final currentTimestamps = _prefs.getStringList(timestampsKey) ?? [];

    await _prefs.setInt(countKey, currentCount + 1);
    await _prefs.setString(lastShownKey, at.toIso8601String());
    await _prefs.setStringList(timestampsKey, [
      ...currentTimestamps,
      at.toIso8601String(),
    ]);
  }

  @override
  FutureOr<int> getShownCount(
    String itemId, {
    required Duration period,
    required AppSurface surface,
    required AppVariant variant,
  }) async {
    final keys = AppUpdatesStorageKeys((itemId, surface, variant));
    final timestampsKey = keys.timestamps;
    final timestampStrings = _prefs.getStringList(timestampsKey) ?? [];
    final timestamps = timestampStrings.map(DateTime.parse).toList();
    final cutoff = DateTime.now().subtract(period);
    final count = timestamps.where((t) => t.isAfter(cutoff)).length;

    return count;
  }

  @override
  FutureOr<DateTime?> getDismissedAt(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
  }) async {
    final keys = AppUpdatesStorageKeys((itemId, surface, variant));
    final timestampStr = _prefs.getString(keys.dismissedAt);
    return timestampStr != null ? DateTime.parse(timestampStr) : null;
  }

  @override
  FutureOr<void> recordDismissed(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
    required DateTime at,
  }) async {
    final keys = AppUpdatesStorageKeys((itemId, surface, variant));
    await _prefs.setString(keys.dismissedAt, at.toIso8601String());
  }

  @override
  FutureOr<void> recordConverted(
    String itemId, {
    required AppSurface surface,
    required AppVariant variant,
    required DateTime at,
  }) async {
    final keys = AppUpdatesStorageKeys((itemId, surface, variant));
    await _prefs.setString(keys.convertedAt, at.toIso8601String());
  }
}
