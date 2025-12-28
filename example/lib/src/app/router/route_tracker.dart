import 'dart:developer';

import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs.dart';
import 'package:flutter/widgets.dart';
import 'package:octopus/octopus.dart';

/// SAFELY IGNORE FOR WEB, NO ALTERNATIVE OR REFACTOR NEEDED, MOBILE ONLY
///
/// A service that tracks the current route and provides utilities
/// for checking if we're on specific routes from anywhere in the app.
class RouteTracker extends ChangeNotifier {
  RouteTracker._();

  static final RouteTracker _instance = RouteTracker._();
  static RouteTracker get instance => _instance;

  String _currentUrl = '/';
  String _currentNodeName = '/';
  Map<String, dynamic> _currentNodeArguments = {};

  /// The current full location (including query parameters)
  String get currentLocation => _currentUrl;

  /// The current node name
  String get currentNodeName => _currentNodeName;

  /// Current node arguments (e.g., ticker symbol from /symbols/:ticker)
  Map<String, dynamic> get currentNodeArguments =>
      Map.unmodifiable(_currentNodeArguments);

  /// Updates the current route information from a GoRouterState
  void updateRoute(OctopusState state) {
    try {
      final previousLocation = _currentUrl;

      _currentUrl = state.uri.toString();
      _currentNodeArguments = state.arguments;

      const homeTab = HomeAppTab();
      final homeRoot = homeTab.root;

      // Check if we're in auth (first root child is not 'home')
      if (state.children.first.name != homeRoot.name) {
        _currentNodeName = state.children.first.name;
      } else if (state.children.any((child) => child.name == homeRoot.name) &&
          state.children.length > 1) {
        /// We are in the state when we have home and we have pushed a node
        /// as a root node:
        /// home
        ///   watchlist-tab
        ///     watchlist...
        /// symbols
        final lastNode = state.children.last;
        _currentNodeName = lastNode.name;
      } else {
        // We're in the main app, need to determine current route based on tab
        final tabName = state.arguments[homeTab.identifier];

        if (tabName != null) {
          // Find the tab node (e.g., 'watchlist-tab', 'explore-tab', etc.)
          final tabNodeName = '$tabName-${homeTab.identifier}';

          // Recursively find the deepest child route
          var currentNode = state.children.first; // home node

          // Find the tab node among home's children
          final tabNode = currentNode.children.firstWhere(
            (child) => child.name == tabNodeName,
          );

          currentNode = tabNode;

          // Navigate to the deepest child
          while (currentNode.children.isNotEmpty == true) {
            currentNode = currentNode.children.last;
          }

          _currentNodeName = currentNode.name;
        } else {
          // Fallback if no tab is specified
          _currentNodeName = state.children.first.name;
        }
      }

      log('currentNodeName: $_currentNodeName', name: 'RouteTracker');

      // Only notify listeners if the route actually changed
      if (previousLocation != _currentUrl) {
        notifyListeners();
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RouteTracker',
          context: ErrorDescription('Error updating route tracking'),
        ),
      );
    }
  }

  /// Check if currently on a specific route
  bool isOnRoute(String route) => _currentNodeName == route;

  /// Check if currently on main route
  bool get isOnMain => isOnRoute(Routes.main.name);

  /// Check if the current route matches a specific pattern
  bool matchesRoute(String pattern) {
    final regex = RegExp(pattern);
    return regex.hasMatch(_currentNodeName);
  }
}

/// A data class containing route information
class RouteInfo {
  const RouteInfo({
    required this.location,
    required this.matchedLocation,
    this.pathParameters = const {},
    this.queryParameters = const {},
  });

  final String location;
  final String matchedLocation;
  final Map<String, dynamic> pathParameters;
  final Map<String, dynamic> queryParameters;

  @override
  String toString() =>
      'RouteInfo(location: $location, matchedLocation: $matchedLocation, '
      'pathParameters: $pathParameters, queryParameters: $queryParameters)';
}
