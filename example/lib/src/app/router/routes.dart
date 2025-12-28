import 'package:example/src/common/widgets/app_retain.dart';
import 'package:example/src/home/view/home_view.dart';
import 'package:example/src/main/view/main_view.dart';
import 'package:example/src/maintenance/view/maintenance_view.dart';
import 'package:example/src/settings/view/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

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
        return _buildHomeShell(context, state, node);
      case Routes.main:
        return const MainView();
      case Routes.maintenance:
        return const MaintenanceView();
      case Routes.settings:
        return const SettingsView();
    }
  }

  @override
  Page<Object?> pageBuilder(
    BuildContext context,
    OctopusState state,
    OctopusNode node,
  ) {
    if (node.name.startsWith(Routes.home.name)) {
      return super.pageBuilder(context, state, node);
    }
    if (node.name.endsWith(Routes.maintenance.name)) {
      return const NoAnimationPage(child: MaintenanceView());
    }
    return super.pageBuilder(context, state, node);
  }

  Widget _buildHomeShell(
    BuildContext context,
    OctopusState state,
    OctopusNode node,
  ) => const AppRetain(child: HomeView());
}
