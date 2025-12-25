import 'package:app_ui/app_ui.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarTab> tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final tabs = this.tabs
        .map((tab) => tab.item((type) => l10n.bottomNavBarTabLabel(type.name)))
        .toList(growable: false);

    return BottomNavigationBar(
      iconSize: 28,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      showSelectedLabels: true,
      selectedItemColor: colorScheme.onSurface,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: AppFontWeight.medium,
      ),
      unselectedLabelStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.outline,
        fontWeight: AppFontWeight.regular,
      ),
      items: tabs,
    );
  }
}
