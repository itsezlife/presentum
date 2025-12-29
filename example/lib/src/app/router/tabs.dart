import 'package:example/src/app/router/routes.dart';
import 'package:octopus/octopus.dart';
import 'package:shared/shared.dart';

mixin AppTab {
  OctopusRoute get root;
  List<OctopusRoute> get tabs;
  List<NavBarTab> get bottomTabs;
  String get identifier;

  String tabRouteName(OctopusRoute route) => '${route.name}-$identifier';

  List<String> get tabRouteNames => [for (final tab in tabs) tabRouteName(tab)];
}

class HomeAppTab with AppTab {
  const HomeAppTab();

  static const _identifier = 'tab';

  @override
  String get identifier => _identifier;

  static const _root = Routes.home;

  static const mainTab = Routes.main;
  static const catalogTab = Routes.catalog;
  static const favoritesTab = Routes.favorites;
  static const settingsTab = Routes.settings;

  @override
  OctopusRoute get root => _root;

  static const _tabs = <OctopusRoute>[
    mainTab,
    catalogTab,
    favoritesTab,
    settingsTab,
  ];

  @override
  List<OctopusRoute> get tabs => _tabs;

  static const _bottomTabs = <NavBarTab>[
    HomeTabsEnum.main,
    HomeTabsEnum.catalog,
    HomeTabsEnum.favorites,
    HomeTabsEnum.settings,
  ];

  @override
  List<NavBarTab> get bottomTabs => _bottomTabs;

  @override
  String toString() => 'HomeAppTab(identifier: $identifier)';
}
