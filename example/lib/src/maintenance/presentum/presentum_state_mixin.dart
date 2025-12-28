import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/presentum/persistent_presentum_storage.dart';
import 'package:example/src/maintenance/presentum/guards/maintenance_guard.dart';
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
  late final MaintenanceProvider _provider;

  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>>
  _errorsObserver;

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
      guards: [MaintenanceGuard(eligibilityResolver: eligibilityResolver)],
      onError: (error, stackTrace) =>
          _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ..._errorsObserver.value,
          ],
    );

    // Create provider
    _provider = MaintenanceProvider(engine: maintenancePresentum.config.engine);
  }

  @override
  void dispose() {
    _provider.dispose();
    _errorsObserver.dispose();
    super.dispose();
  }
}
