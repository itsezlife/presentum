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
  maintenanceScreenRestartButton;

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
      _ => fallback ?? (throw ArgumentError.value(name)),
    };
  }
}
