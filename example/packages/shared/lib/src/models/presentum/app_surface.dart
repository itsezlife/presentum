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
  maintenanceView,
}
