import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/presentum/persistent_presentum_storage.dart';
import 'package:example/src/updates/presentum/eligibility/update_status_eligibility.dart';
import 'package:example/src/updates/presentum/guards/updates_scheduling_guard.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:example/src/updates/presentum/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Mixin that provides Presentum for app updates and maintenance mode
mixin AppUpdatesPresentumStateMixin<T extends StatefulWidget> on State<T> {
  late final Presentum<AppUpdatesItem, AppSurface, AppVariant>
  appUpdatesPresentum;
  late final PresentumStorage<AppSurface, AppVariant> _storage;
  late final AppUpdatesProvider _provider;

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

    // Eligibility resolver
    final eligibilityResolver = DefaultEligibilityResolver<AppUpdatesItem>(
      rules: [...createStandardRules(), const UpdateStatusRule()],
      extractors: [
        const TimeRangeExtractor(),
        const ConstantExtractor(metadataKey: 'is_active'),
        const UpdateStatusExtractor(),
      ],
    );

    final updatesStore = deps.shorebirdUpdatesStore;

    // Create Presentum instance
    appUpdatesPresentum = Presentum<AppUpdatesItem, AppSurface, AppVariant>(
      storage: _storage,
      eventHandlers: [PresentumStorageEventHandler(storage: _storage)],
      guards: [
        AppUpdatesGuard(
          eligibilityResolver: eligibilityResolver,
          getUpdateStatus: () => updatesStore.status,
          refresh: updatesStore,
        ),
      ],
      onError: (error, stackTrace) =>
          _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ..._errorsObserver.value,
          ],
    );

    // Create provider
    _provider = AppUpdatesProvider(
      engine: appUpdatesPresentum.config.engine,
      updatesStore: updatesStore,
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    _errorsObserver.dispose();
    super.dispose();
  }
}
