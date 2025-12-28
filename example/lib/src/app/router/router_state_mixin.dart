import 'package:example/src/app/router/home_guard.dart';
import 'package:example/src/app/router/maintenance_mode_guard.dart';
import 'package:example/src/app/router/route_tracker.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs_guard.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/maintenance/presentum/provider.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

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

    final maintenancePresentum = context
        .presentum<MaintenanceItem, AppSurface, AppVariant>();

    final provider = MaintenanceProvider.of(context);

    final observer = maintenancePresentum.observer;

    // Create router.
    router = Octopus(
      routes: Routes.values,
      defaultRoute: Routes.home,
      transitionDelegate: const DefaultTransitionDelegate<void>(),
      guards: [
        // Maintenance guard to check if the maintenance mode is active.
        MaintenanceModeGuard(
          eligibilityResolver: provider.eligibilityResolver,
          // Get the maintenance state from the observer.
          maintenanceState: () => observer.value,

          /// We must evaluate initial candidates to effectively identify
          /// initial maintenance mode. Further updates would be delvivered
          /// via the observer, if the maintenance payload changes
          /// in the [MaintenanceProvider].
          initialMaintenanceCandidates: () => provider.candidates,
          // Refresh the guard when the maintenance state changes.
          refresh: observer,
        ),
        // Home route should be always on top.
        HomeGuard(),
        // Home tabs guard.
        HomeTabsGuard(),
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
