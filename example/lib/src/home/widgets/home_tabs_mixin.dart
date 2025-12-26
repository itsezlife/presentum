import 'package:example/src/app/router/tabs.dart';
import 'package:example/src/navigation/view/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

mixin HomeTabsMixin<T extends StatefulWidget> on State<T> {
  AppTab get tab;

  OctopusOnBackButtonPressed get onBackButtonPressed => (context, navigator) {
    // First check if the current navigator can pop
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return Future.value(true);
    }

    // Then check if the Octopus navigator can pop
    if (navigator.canPop()) {
      navigator.pop();
      return Future.value(true);
    }
    return Future.value(false);
  };

  OctopusTabBuilder get tabBuilder =>
      (context, route, tabIdentifier, onBackButtonPressed) =>
          TabBucketNavigator(
            route: route,
            tabIdentifier: tabIdentifier,
            onBackButtonPressed: onBackButtonPressed,
          );
  OctopusOnTabChanged get onTabChanged => (index, tab) {
    currentIndex = index;
  };

  void onTabPressed(int index, VoidCallback innerOnTabPressed) {
    innerOnTabPressed();
  }

  int currentIndex = 0;

  Widget buildTabs(BuildContext context) => OctopusTabs.lazy(
    root: tab.root,
    tabs: tab.tabs,
    onBackButtonPressed: onBackButtonPressed,
    tabBuilder: tabBuilder,
    onTabChanged: onTabChanged,
    builder: (context, child, currentIndex, innerOnTabPressed) => Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        tabs: tab.bottomTabs,
        currentIndex: currentIndex,
        onTap: (index) => onTabPressed(index, () => innerOnTabPressed(index)),
      ),
    ),
  );
}
