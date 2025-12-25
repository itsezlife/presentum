import 'package:example/src/home/view/home_view.dart';
import 'package:example/src/main/view/main_view.dart';
import 'package:example/src/settings/view/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

enum Routes with OctopusRoute {
  home('home'),
  main('main'),
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
      case Routes.settings:
        return const SettingsView();
    }
  }
}
