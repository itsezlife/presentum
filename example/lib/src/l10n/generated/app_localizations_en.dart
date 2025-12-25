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
      'newYear': 'New Year',
      'other': 'Unknown Feature',
    });
    return '$_temp0';
  }

  @override
  String get settingsNewYearDescription => 'Enable the New Year for the app.';

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
  String get newYearBannerSubtitle => 'Wishing you a year full of wins ✨';
}
