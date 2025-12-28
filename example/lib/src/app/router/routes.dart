import 'package:example/src/home/view/home_view.dart';
import 'package:example/src/main/view/main_view.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/maintenance/view/maintenance_view.dart';
import 'package:example/src/settings/view/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

enum Routes with OctopusRoute {
  home('home'),
  main('main'),
  maintenance('maintenance'),
  settings('settings');

  const Routes(this.name);

  @override
  final String name;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) {
    switch (this) {
      case Routes.home:
        return const HomeView();
      case Routes.main:
        return const MainView();
      case Routes.maintenance:
        final item = node.extra['item'] as MaintenanceItem;
        return InheritedPresentumItem<MaintenanceItem, AppSurface, AppVariant>(
          item: item,
          child: const MaintenanceView(),
        );
      case Routes.settings:
        return const SettingsView();
    }
  }
}
