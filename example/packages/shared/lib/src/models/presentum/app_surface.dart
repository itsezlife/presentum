import 'package:presentum/presentum.dart';

/// Surfaces are the locations where presentations can appear.
enum AppSurface with PresentumSurface {
  /// The header of the home screen.
  homeHeader,

  /// The popup surface.
  popup,

  /// The snow background surface.
  background,

  /// The list of settings toggles.
  settingsToggles, // "settings list" is a Presentum surface too
  /// The update snackbar surface.
  updateSnackbar,

  /// The maintenance view surface.
  maintenanceView;

  /// The name of the surface.
  /// 
  /// Throws [ArgumentError] if the name is not valid.
  static AppSurface fromName(
    String name, {
    AppSurface? fallback,
  }) {
    return switch (name) {
      'popup' => AppSurface.popup,
      'homeHeader' => AppSurface.homeHeader,
      'background' => AppSurface.background,
      'settingsToggles' => AppSurface.settingsToggles,
      'updateSnackbar' => AppSurface.updateSnackbar,
      'maintenanceView' => AppSurface.maintenanceView,
      _ => fallback ?? (throw ArgumentError.value(name)),
    };
  }
}
