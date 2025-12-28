import 'package:example/src/app/router/home_guard.dart';
import 'package:example/src/app/router/maintenance_mode_guard.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/app/router/tabs_guard.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:flutter/widgets.dart'
    show DefaultTransitionDelegate, State, StatefulWidget, ValueNotifier;
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

    final eligibilityResolver = DefaultEligibilityResolver<MaintenanceItem>(
      rules: [...createStandardRules()],
      extractors: [
        const TimeRangeExtractor(),
        const ConstantExtractor(metadataKey: 'is_active'),
      ],
    );

    // Create router.
    router = Octopus(
      routes: Routes.values,
      defaultRoute: Routes.home,
      transitionDelegate: const DefaultTransitionDelegate<void>(),
      guards: [
        // Maintenance guard to check if the maintenance mode is active.
        MaintenanceModeGuard(
          maintenanceStateObserver: maintenancePresentum.observer,
          eligibilityResolver: eligibilityResolver,
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
    super.initState();
  }
}
