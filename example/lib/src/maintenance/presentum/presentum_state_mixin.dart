import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/common/presentum/remove_ineligible_candidates_guard.dart';
import 'package:example/src/maintenance/presentum/guards/maintenance_scheduling_guard.dart';
import 'package:example/src/maintenance/presentum/guards/sync_maintenance_state_guard.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/maintenance/presentum/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Mixin that provides Presentum for maintenance mode
mixin MaintaincePresentumStateMixin<T extends StatefulWidget> on State<T> {
  late final Presentum<MaintenanceItem, AppSurface, AppVariant>
  maintenancePresentum;
  late final PresentumStorage<AppSurface, AppVariant> _storage;
  late final MaintenanceProvider provider;

  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>>
  _errorsObserver;

  void _onError(Object error, StackTrace stackTrace) {
    _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
      (error: error, stackTrace: stackTrace),
      ..._errorsObserver.value,
    ];
  }

  @override
  void initState() {
    super.initState();

    // Observe all errors
    _errorsObserver =
        ValueNotifier<List<({Object error, StackTrace stackTrace})>>(
          <({Object error, StackTrace stackTrace})>[],
        );

    _errorsObserver.addListener(() {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: _errorsObserver.value.lastOrNull?.error ?? 'Unknown error',
          stack: _errorsObserver.value.lastOrNull?.stackTrace,
          library: 'AppUpdatesPresentum',
        ),
      );
    });

    final deps = Dependencies.of(context);

    // Presentum storage
    _storage = PersistentPresentumStorage(prefs: deps.sharedPreferences);

    final eligibilityResolver = DefaultEligibilityResolver<MaintenanceItem>(
      rules: [...createStandardRules()],
      extractors: [
        const TimeRangeExtractor(),
        const ConstantExtractor(metadataKey: 'is_active'),
        const AnyOfExtractor(
          nestedExtractors: [
            TimeRangeExtractor(),
            ConstantExtractor(metadataKey: 'is_active'),
          ],
        ),
      ],
    );

    // Create Presentum instance
    maintenancePresentum = Presentum<MaintenanceItem, AppSurface, AppVariant>(
      storage: _storage,
      eventHandlers: [PresentumStorageEventHandler(storage: _storage)],
      guards: [
        SyncMaintenanceStateGuard(),
        MaintenanceSchedulingGuard(eligibilityResolver: eligibilityResolver),
        // Always put this last to ensure we remove ineligible items from the state
        RemoveIneligibleCandidatesGuard<
          MaintenanceItem,
          AppSurface,
          AppVariant
        >(eligibility: eligibilityResolver),
      ],
      onError: _onError,
    );

    // Create provider
    provider = MaintenanceProvider(
      maintenanceStore: deps.maintenanceStore,
      engine: maintenancePresentum.config.engine,
      eligibilityResolver: eligibilityResolver,
      onError: _onError,
    );
  }

  @override
  void dispose() {
    provider.dispose();
    _errorsObserver.dispose();
    super.dispose();
  }
}
