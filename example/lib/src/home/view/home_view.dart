// ignore_for_file: use_setters_to_change_properties

import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/feature/feature_presentum.dart';
import 'package:example/src/home/widgets/home_tabs_mixin.dart';
import 'package:example/src/updates/presentum/app_updates_presentum.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

class HomeController {
  factory HomeController() => _instance;

  HomeController._();

  static final HomeController _instance = HomeController._();

  static const _tab = HomeAppTab();

  Octopus get octopus => Octopus.instance;

  bool handleBackPressed() {
    final currentTab = octopus.state.arguments[_tab.identifier];

    if (currentTab == Routes.main.name || currentTab == null) {
      return _maybeGoToMain();
    } else {
      octopus.setArguments((args) => args[_tab.identifier] = Routes.main.name);
      return false;
    }
  }

  bool _maybeGoToMain() {
    final isOnMain = RouteTracker.instance.isOnMain;
    if (isOnMain) {
      octopus.setArguments((args) => args[_tab.identifier] = Routes.main.name);
    }
    return isOnMain;
  }
}

/// {@template home_view}
/// HomeView widget.
/// {@endtemplate}
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with HomeTabsMixin {
  @override
  AppTab get tab => const HomeAppTab();

  @override
  Widget build(BuildContext context) =>
      AppUpdatesPresentum(child: FeaturePresentum(child: buildTabs(context)));
}
