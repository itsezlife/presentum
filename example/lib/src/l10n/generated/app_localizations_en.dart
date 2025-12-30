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
      'catalog': 'Catalog',
      'favorites': 'Favorites',
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
      'catalogCategoriesSection': 'Catalog Categories Section',
      'catalogRecentlyViewedProductsSection':
          'Catalog Recently Viewed Products Section',
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
  String get resetPresentumItemsStorageTitle => 'Reset presentum items storage';

  @override
  String get resetPresentumItemsStorageSubtitle =>
      'Tap to reset storage for specific item';

  @override
  String get resetAllPresentumItemsStorageTitle =>
      'Reset all presentum items storage';

  @override
  String resetPresentumItemSurfaceVariant(String surface, String variant) {
    return 'Surface: $surface, Variant: $variant';
  }

  @override
  String resetPresentumItemId(String id) {
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

  @override
  String get copied => 'Copied';

  @override
  String get aboutDialogNameTitle => 'Name';

  @override
  String get aboutDialogVersionTitle => 'Version';

  @override
  String get aboutDialogDescriptionTitle => 'Description';

  @override
  String get aboutDialogHomepageTitle => 'Homepage';

  @override
  String get aboutDialogRepositoryTitle => 'Repository';

  @override
  String categoryDescription(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'groceries': 'Fresh food and daily essentials',
      'electronics': 'Tech gadgets and devices',
      'fashion': 'Clothing and accessories',
      'other': 'Miscellaneous items',
    });
    return '$_temp0';
  }

  @override
  String get settingsCatalogFeatureNotDependentDescription =>
      'Disabling this feature will only disable it from settings, but associated payload wouldn\'t be disabled';
}
