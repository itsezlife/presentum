// ignore_for_file: deprecated_member_use

import 'package:animations/animations.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// {@template app_theme}
/// The Default App [ThemeData].
/// {@endtemplate}
class AppTheme {
  /// {@macro app_theme}
  const AppTheme();

  /// Defines the color scheme of the theme.
  ColorScheme get colorScheme => _colorSchemeLightM3;

  /// Defines light [ThemeData].
  ThemeData get theme => ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    hintColor: AppColors.lightHintColor,
    dividerColor: const Color(0xFFCAC4D0),
    listTileTheme: const ListTileThemeData(
      horizontalTitleGap: AppSpacing.lg,
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      modalBarrierColor: AppColors.scrim,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.lg),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
      },
    ),
    extensions: const [
      SkeletonizerConfigData(
        enableSwitchAnimation: true,
        effect: ShimmerEffect(
          baseColor: Color(0xFFF3EDF7), // surfaceContainer
          highlightColor: Color(0xFFF6F3FA),
        ),
        containersColor: Color(0xFFF3EDF7), // surfaceContainer
        switchAnimationConfig: SwitchAnimationConfig(
          duration: kThemeAnimationDuration,
        ),
      ),
    ],
  );
}

/// {@template app_dark_theme}
/// Dark Mode App [ThemeData].
/// {@endtemplate}
class AppDarkTheme extends AppTheme {
  /// {@macro app_dark_theme}
  const AppDarkTheme();

  @override
  ColorScheme get colorScheme => _colorSchemeDarkM3;

  @override
  ThemeData get theme => super.theme.copyWith(
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(),
    ),
    hintColor: AppColors.darkHintColor,
    dividerColor: const Color(0xFF49454F),
    extensions: [
      const SkeletonizerConfigData.dark(
        enableSwitchAnimation: true,
        effect: ShimmerEffect(
          baseColor: Color(0xFF211F26), // surfaceContainer
          highlightColor: Color(0xFF2A2630),
        ),
        containersColor: Color(0xFF211F26), // surfaceContainer
        switchAnimationConfig: SwitchAnimationConfig(
          duration: kThemeAnimationDuration,
        ),
      ),
    ],
  );
}

/// Theme for the [SystemUiOverlayStyle]
class SystemUiOverlayTheme {
  /// {@macro system_ui_overlay_theme}
  const SystemUiOverlayTheme._();

  /// Defines iOS light SystemUiOverlayStyle.
  static const SystemUiOverlayStyle iOSLightSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  /// Defines iOS dark SystemUiOverlayStyle.
  static const SystemUiOverlayStyle iOSDarkSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  /// Defines Android light SystemUiOverlayStyle.
  static const SystemUiOverlayStyle androidLightSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // systemNavigationBarColor: Color(0xFFFEF7FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  /// Defines light SystemUiOverlayStyle.
  static const SystemUiOverlayStyle androidDarkSystemBarTheme =
      SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        // systemNavigationBarColor: Color(0xFF141218),
        systemNavigationBarIconBrightness: Brightness.light,
      );
}

/// {@template skeletonizer_copy_with_extension}
/// Extension methods for the [SkeletonizerConfigData] extension.
/// {@endtemplate}
extension SkeletonizerCopyWithExtension on Iterable<ThemeExtension<dynamic>> {
  /// Get the [SkeletonizerConfigData] extension from the theme extensions.
  SkeletonizerConfigData get skeletonizerConfigData =>
      firstWhere(
            (extension) => extension is SkeletonizerConfigData,
          )
          as SkeletonizerConfigData;
}

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
const ColorScheme _colorSchemeLightM3 = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF6750A4),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEADDFF),
  onPrimaryContainer: Color(0xFF4F378B),
  primaryFixed: Color(0xFFEADDFF),
  primaryFixedDim: Color(0xFFD0BCFF),
  onPrimaryFixed: Color(0xFF21005D),
  onPrimaryFixedVariant: Color(0xFF4F378B),
  secondary: Color(0xFF625B71),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF4A4458),
  secondaryFixed: Color(0xFFE8DEF8),
  secondaryFixedDim: Color(0xFFCCC2DC),
  onSecondaryFixed: Color(0xFF1D192B),
  onSecondaryFixedVariant: Color(0xFF4A4458),
  tertiary: Color(0xFF7D5260),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF633B48),
  tertiaryFixed: Color(0xFFFFD8E4),
  tertiaryFixedDim: Color(0xFFEFB8C8),
  onTertiaryFixed: Color(0xFF31111D),
  onTertiaryFixedVariant: Color(0xFF633B48),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF8C1D18),
  background: Color(0xFFFEF7FF),
  onBackground: Color(0xFF1D1B20),
  surface: Color(0xFFFEF7FF),
  surfaceBright: Color(0xFFFEF7FF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF7F2FA),
  surfaceContainer: Color(0xFFF3EDF7),
  surfaceContainerHigh: Color(0xFFECE6F0),
  surfaceContainerHighest: Color(0xFFE6E0E9),
  surfaceDim: Color(0xFFDED8E1),
  onSurface: Color(0xFF1D1B20),
  surfaceVariant: Color(0xFFE7E0EC),
  onSurfaceVariant: Color(0xFF49454F),
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF322F35),
  onInverseSurface: Color(0xFFF5EFF7),
  inversePrimary: Color(0xFFD0BCFF),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(0xFF6750A4),
);

const ColorScheme _colorSchemeDarkM3 = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFEADDFF),
  primaryFixed: Color(0xFFEADDFF),
  primaryFixedDim: Color(0xFFD0BCFF),
  onPrimaryFixed: Color(0xFF21005D),
  onPrimaryFixedVariant: Color(0xFF4F378B),
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  secondaryFixed: Color(0xFFE8DEF8),
  secondaryFixedDim: Color(0xFFCCC2DC),
  onSecondaryFixed: Color(0xFF1D192B),
  onSecondaryFixedVariant: Color(0xFF4A4458),
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  tertiaryFixed: Color(0xFFFFD8E4),
  tertiaryFixedDim: Color(0xFFEFB8C8),
  onTertiaryFixed: Color(0xFF31111D),
  onTertiaryFixedVariant: Color(0xFF633B48),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  background: Color(0xFF141218),
  onBackground: Color(0xFFE6E0E9),
  surface: Color(0xFF141218),
  surfaceBright: Color(0xFF3B383E),
  surfaceContainerLowest: Color(0xFF0F0D13),
  surfaceContainerLow: Color(0xFF1D1B20),
  surfaceContainer: Color(0xFF211F26),
  surfaceContainerHigh: Color(0xFF2B2930),
  surfaceContainerHighest: Color(0xFF36343B),
  surfaceDim: Color(0xFF141218),
  onSurface: Color(0xFFE6E0E9),
  surfaceVariant: Color(0xFF49454F),
  onSurfaceVariant: Color(0xFFCAC4D0),
  outline: Color(0xFF938F99),
  outlineVariant: Color(0xFF49454F),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE6E0E9),
  onInverseSurface: Color(0xFF322F35),
  inversePrimary: Color(0xFF6750A4),
  // The surfaceTint color is set to the same color as the primary.
  surfaceTint: Color(0xFFD0BCFF),
);
// dart format on
