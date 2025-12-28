// ignore_for_file: dart-format

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get languageEn => 'English';

  @override
  String bottomNavBarTabLabel(String tab) {
    String _temp0 = intl.Intl.selectLogic(tab, {
      'main': 'Home',
      'settings': 'Settings',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String featureName(String featureKey) {
    String _temp0 = intl.Intl.selectLogic(featureKey, {
      'newYearTheme': 'New Year Theme',
      'newYearBanner': 'New Year Banner',
      'other': 'Unknown Feature',
    });
    return '$_temp0';
  }

  @override
  String settingsFeatureEnabledDescription(String featureName) {
    return 'Enable the $featureName feature for the app.';
  }

  @override
  String get settingsCatalogFeaturesTitle => 'Catalog Features';

  @override
  String get settingsCatalogFeaturesDescription =>
      'Enable or disable catalog feature from both settings and the app.';

  @override
  String toggleFeatureTitle(String featureName) {
    return '$featureName feature';
  }

  @override
  String removeCatalogFeatureDescription(String featureName) {
    return 'Add or completely remove $featureName feature from the settings and the app.';
  }

  @override
  String get resetFeaturePresentumItemsStorageTitle =>
      'Reset feature presentum items storage';

  @override
  String get resetFeaturePresentumItemsStorageSubtitle =>
      'Tap to reset storage for specific item';

  @override
  String resetFeaturePresentumItemSurfaceVariant(
    String surface,
    String variant,
  ) {
    return 'Surface: $surface, Variant: $variant';
  }

  @override
  String resetFeaturePresentumItemId(String id) {
    return 'ID: $id';
  }

  @override
  String get newYearBannerTitle => 'Happy New Year!';

  @override
  String newYearBannerTitleWithYear(String year) {
    return 'Happy New $year Year!';
  }

  @override
  String get newYearBannerSubtitleSmallVersion => 'Wishing you wins ✨';

  @override
  String get newYearBannerSubtitleLargeVersion =>
      'Wishing you a year full of wins ✨';

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get maintenanceDescription =>
      'We\'re currently performing maintenance to improve your experience.';

  @override
  String get maintenanceEstimatedTimeRemaining => 'Estimated time remaining:';

  @override
  String get maintenanceComplete => 'Maintenance complete!';

  @override
  String get maintenanceRestartApp => 'Restart App';

  @override
  String get maintenancePleaseCheckBack => 'Please check back soon.';

  @override
  String get restartingApp => 'Restarting App';

  @override
  String get restartNotification => 'Please tap here to open the app again.';
}
