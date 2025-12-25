import 'package:presentum/presentum.dart';

/// Variants are the visual styles that presentations can appear in.
enum AppVariant with PresentumVisualVariant {
  /// A banner presentation.
  banner,

  /// A row of setting toggles.
  settingToggleRow,

  /// A fullscreen greeting.
  fullscreenDialog,
}
