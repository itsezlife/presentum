// ignore_for_file: dart-format
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// The label for the bottom navigation bar tab.
  ///
  /// In en, this message translates to:
  /// **'{tab, select, main{Home} settings{Settings} other{Other}}'**
  String bottomNavBarTabLabel(String tab);

  /// The name of the feature.
  ///
  /// In en, this message translates to:
  /// **'{featureKey, select, newYearTheme{New Year Theme} newYearBanner{New Year Banner} other{Unknown Feature}}'**
  String featureName(String featureKey);

  /// The description for the feature enabled button.
  ///
  /// In en, this message translates to:
  /// **'Enable the {featureName} feature for the app.'**
  String settingsFeatureEnabledDescription(String featureName);

  /// No description provided for @settingsCatalogFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog Features'**
  String get settingsCatalogFeaturesTitle;

  /// No description provided for @settingsCatalogFeaturesDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable catalog feature from both settings and the app.'**
  String get settingsCatalogFeaturesDescription;

  /// The title for the toggle feature button.
  ///
  /// In en, this message translates to:
  /// **'{featureName} feature'**
  String toggleFeatureTitle(String featureName);

  /// The description for the remove feature button.
  ///
  /// In en, this message translates to:
  /// **'Add or completely remove {featureName} feature from the settings and the app.'**
  String removeCatalogFeatureDescription(String featureName);

  /// No description provided for @resetFeaturePresentumItemsStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset feature presentum items storage'**
  String get resetFeaturePresentumItemsStorageTitle;

  /// No description provided for @resetFeaturePresentumItemsStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to reset storage for specific item'**
  String get resetFeaturePresentumItemsStorageSubtitle;

  /// The surface and variant information for a presentum item.
  ///
  /// In en, this message translates to:
  /// **'Surface: {surface}, Variant: {variant}'**
  String resetFeaturePresentumItemSurfaceVariant(
    String surface,
    String variant,
  );

  /// The ID of the presentum item.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String resetFeaturePresentumItemId(String id);

  /// No description provided for @newYearBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Happy New Year!'**
  String get newYearBannerTitle;

  /// The title for the New Year banner with year included.
  ///
  /// In en, this message translates to:
  /// **'Happy New {year} Year!'**
  String newYearBannerTitleWithYear(String year);

  /// No description provided for @newYearBannerSubtitleSmallVersion.
  ///
  /// In en, this message translates to:
  /// **'Wishing you wins ✨'**
  String get newYearBannerSubtitleSmallVersion;

  /// No description provided for @newYearBannerSubtitleLargeVersion.
  ///
  /// In en, this message translates to:
  /// **'Wishing you a year full of wins ✨'**
  String get newYearBannerSubtitleLargeVersion;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'re currently performing maintenance to improve your experience.'**
  String get maintenanceDescription;

  /// No description provided for @maintenanceEstimatedTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Estimated time remaining:'**
  String get maintenanceEstimatedTimeRemaining;

  /// No description provided for @maintenanceComplete.
  ///
  /// In en, this message translates to:
  /// **'Maintenance complete!'**
  String get maintenanceComplete;

  /// No description provided for @maintenanceRestartApp.
  ///
  /// In en, this message translates to:
  /// **'Restart App'**
  String get maintenanceRestartApp;

  /// No description provided for @maintenancePleaseCheckBack.
  ///
  /// In en, this message translates to:
  /// **'Please check back soon.'**
  String get maintenancePleaseCheckBack;

  /// No description provided for @restartingApp.
  ///
  /// In en, this message translates to:
  /// **'Restarting App'**
  String get restartingApp;

  /// No description provided for @restartNotification.
  ///
  /// In en, this message translates to:
  /// **'Please tap here to open the app again.'**
  String get restartNotification;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
