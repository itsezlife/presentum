import 'package:example/src/app/router/home_guard.dart';
import 'package:example/src/app/router/maintenance_mode_guard.dart';
import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs_guard.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/shop/data/shop_tabs_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

mixin RouterStateMixin<T extends StatefulWidget> on State<T> {
  late final Octopus router;
  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>>
  errorsObserver;

  @override
  void initState() {
    // Observe all errors.
    errorsObserver =
        ValueNotifier<List<({Object error, StackTrace stackTrace})>>(
          <({Object error, StackTrace stackTrace})>[],
        );

    final deps = Dependencies.of(context);
    final maintenanceController = deps.maintenanceController;

    // Create cache for shop tabs.
    final shopTabCache = ShopTabsCacheService(
      sharedPreferences: deps.sharedPreferences,
    );

    // Create router.
    router = Octopus(
      routes: Routes.values,
      defaultRoute: Routes.home,
      transitionDelegate: const DefaultTransitionDelegate<void>(),
      duplicateStrategy: OctopusDuplicateStrategy.allow,
      guards: [
        // Maintenance guard to check if the maintenance mode is active.
        MaintenanceModeGuard(
          eligibilityResolver: maintenanceController.eligibilityResolver,
          slots: () => maintenanceController.state.slots,
          candidates: () => maintenanceController.state.candidates,
          refresh: maintenanceController,
        ),
        // Home route should be always on top.
        HomeGuard(),
        // Home tabs guard.
        HomeTabsGuard(cache: shopTabCache),
      ],
      onError: (error, stackTrace) =>
          errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ...errorsObserver.value,
          ],
    );

    setupRouteTracking(router);
    super.initState();
  }

  void setupRouteTracking(Octopus router) {
    try {
      // Track initial route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = router.state;
        RouteTracker.instance.updateRoute(state);
      });

      // Listen to route changes
      router.observer.addListener(() {
        final state = router.state;
        RouteTracker.instance.updateRoute(state);
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RouterStateMixin',
          context: ErrorDescription('Error setting up route tracking'),
        ),
      );
    }
  }
}
