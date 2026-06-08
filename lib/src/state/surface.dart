/// Marker for all presentum surfaces.
///
/// Implement this on your surface enums:
/// `enum AppSurface with PresentumSurface { ... }`
abstract mixin class PresentumSurface {
  /// The key of the surface.
  String get key;
}

/// Marker for all presentum visual styles.
///
/// Implement this on your visual enums:
/// `enum AppVariant with PresentumVisualVariant { ... }`
abstract mixin class PresentumVisualVariant {
  /// The key of the visual variant.
  String get key;
}
