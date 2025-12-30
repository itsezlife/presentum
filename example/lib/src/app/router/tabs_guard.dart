import 'dart:async';

import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/shop/data/shop_tabs_cache_service.dart';
import 'package:octopus/octopus.dart';

abstract class ITabsGuard extends OctopusGuard {
  ITabsGuard({required this.tab, ShopTabsCacheService? cache}) : _cache = cache;

  final AppTab tab;

  List<OctopusRoute> get tabs => tab.tabs;

  String _tabRouteName(OctopusRoute route) => tab.tabRouteName(route);

  final ShopTabsCacheService? _cache;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) {
    final root = state.findByName(tab.root.name);

    if (root == null) return state; // Do nothing if `root` not found.

    if (!root.hasChildren) {
      _cache?.restore(state);
    }

    // Keep only branches matching our tabs, remove others.
    final validNames = tabs.map(_tabRouteName).toSet();
    root.removeWhere(
      (node) => !validNames.contains(node.name),
      recursive: false,
    );

    // Ensure each tab branch exists under root.
    for (final tab in tabs) {
      final bucketName = _tabRouteName(tab);
      final branch = root.putIfAbsent(
        bucketName,
        () => OctopusNode.mutable(bucketName),
      );
      if (!branch.hasChildren) branch.add(OctopusNode.mutable(tab.name));
    }

    _cache?.save(state);
    return state;
  }
}

class HomeTabsGuard extends ITabsGuard {
  HomeTabsGuard({super.tab = _tab, super.cache});

  static const _tab = HomeAppTab();
}
