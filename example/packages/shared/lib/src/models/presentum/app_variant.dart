import 'package:presentum/presentum.dart';

/// Variants are the visual styles that presentations can appear in.
enum AppVariant with PresentumVisualVariant {
  /// A banner presentation.
  banner,

  /// A row of setting toggles.
  settingToggleRow,

  /// A fullscreen greeting.
  fullscreenDialog,

  /// A snow
  snow,

  /// A snackbar presentation.
  snackbar,

  /// A maintenance screen presentation.
  maintenanceScreen,

  /// A restart button presentation in maintenance screen.
  maintenanceScreenRestartButton,

  /// A catalog view presentation.
  catalogCategoriesSection,

  /// A catalog recently viewed products section presentation.
  catalogRecentlyViewedProductsSection,

  /// Product recommendations grid presentation
  productRecommendationsGrid;

  /// A list of catalog sections.
  static const catalogSections = <AppVariant>[
    catalogCategoriesSection,
    catalogRecentlyViewedProductsSection,
  ];

  /// The name of the variant.
  ///
  /// Throws [ArgumentError] if the name is not valid.
  static AppVariant fromName(
    String name, {
    AppVariant? fallback,
  }) {
    return switch (name) {
      'banner' => AppVariant.banner,
      'settingToggleRow' => AppVariant.settingToggleRow,
      'fullscreenDialog' => AppVariant.fullscreenDialog,
      'snow' => AppVariant.snow,
      'snackbar' => AppVariant.snackbar,
      'maintenanceScreen' => AppVariant.maintenanceScreen,
      'maintenanceScreenRestartButton' =>
        AppVariant.maintenanceScreenRestartButton,
      'catalogCategoriesSection' => AppVariant.catalogCategoriesSection,
      'catalogRecentlyViewedProductsSection' =>
        AppVariant.catalogRecentlyViewedProductsSection,
      'productRecommendationsGrid' => AppVariant.productRecommendationsGrid,
      _ => fallback ?? (throw ArgumentError.value(name)),
    };
  }
}
