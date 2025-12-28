import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// The main outlined icon.
const mainInactiveIcon = Icon(Icons.home_outlined);

/// The main rounded icon.
const mainActiveIcon = Icon(Icons.home_rounded);

/// The settings outlined icon.
const settingsInactiveIcon = Icon(Icons.settings_outlined);

/// The settings rounded icon.
const settingsActiveIcon = Icon(Icons.settings_rounded, weight: 100);

/// The type of bottom navigation bar item.
enum BottomNavBarTab with NavBarTab {
  /// The main page.
  main,

  /// The settings page.
  settings;

  /// Creates a new instance of [BottomNavBarTab] from a given string.
  static BottomNavBarTab fromValue(
    String? value, {
    BottomNavBarTab? fallback,
  }) => switch (value?.trim().toLowerCase()) {
    'main' => main,
    'settings' => settings,
    _ => fallback ?? (throw ArgumentError.value(value)),
  };

  @override
  String label(String Function(BottomNavBarTab type) l10n) => l10n(this);

  @override
  String tooltip(String Function(BottomNavBarTab type) l10n) => label(l10n);

  @override
  Widget get icon => switch (this) {
    main => mainInactiveIcon,
    settings => settingsInactiveIcon,
  };

  @override
  Widget get activeIcon => switch (this) {
    main => mainActiveIcon,
    settings => settingsActiveIcon,
  };

  @override
  BottomNavigationBarItem item(
    String Function(BottomNavBarTab type) labelL10n, {
    String Function(BottomNavBarTab type)? tooltipL10n,
  }) => BottomNavigationBarItem(
    icon: icon,
    activeIcon: activeIcon,
    label: label(labelL10n),
    tooltip: tooltipL10n != null ? tooltipL10n(this) : tooltip(labelL10n),
  );
}

/// The bottom navigation bar item.
mixin NavBarTab {
  /// The label of the bottom navigation bar item.
  String label(String Function(BottomNavBarTab type) l10n);

  /// The tooltip of the bottom navigation bar item.
  String tooltip(String Function(BottomNavBarTab type) l10n);

  /// The icon of the bottom navigation bar item.
  Widget get icon;

  /// The active icon of the bottom navigation bar item.
  Widget get activeIcon;

  /// The item of the bottom navigation bar item.
  BottomNavigationBarItem item(
    String Function(BottomNavBarTab type) labelL10n, {
    String Function(BottomNavBarTab type)? tooltipL10n,
  });
}
