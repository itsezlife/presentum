import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/shop/presentum/guards/recommendation_quality_filter_guard.dart';
import 'package:example/src/shop/presentum/guards/recommendation_scheduling_guard.dart';
import 'package:example/src/shop/presentum/guards/recommendation_sync_guard.dart';
import 'package:example/src/shop/presentum/recommendation_payload.dart';
import 'package:example/src/shop/presentum/recommendation_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

mixin RecommendationPresentumStateMixin<T extends StatefulWidget> on State<T> {
  late final Presentum<RecommendationItem, AppSurface, AppVariant>
  recommendationPresentum;
  late final PresentumStorage<AppSurface, AppVariant> _storage;

  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>>
  _errorsObserver;

  @override
  void initState() {
    super.initState();
    // Observe all errors.
    _errorsObserver =
        ValueNotifier<List<({Object error, StackTrace stackTrace})>>(
          <({Object error, StackTrace stackTrace})>[],
        );

    _errorsObserver.addListener(() {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: _errorsObserver.value.lastOrNull?.error ?? 'Unknown error',
          stack: _errorsObserver.value.lastOrNull?.stackTrace,
          library: 'RecommendationPresentum',
        ),
      );
    });

    final deps = Dependencies.of(context);

    // Presentum storage used to store the state(dismissed, shown, converted)
    // of the feature items.
    _storage = PersistentPresentumStorage(prefs: deps.sharedPreferences);

    // final eligibility = RecommendationEligibilityResolver();

    final recommendationStore = Dependencies.of(context).recommendationStore;

    recommendationPresentum =
        Presentum<RecommendationItem, AppSurface, AppVariant>(
          storage: _storage,
          eventHandlers: [PresentumStorageEventHandler(storage: _storage)],
          guards: [
            // Sync with store state
            RecommendationSyncGuard(store: recommendationStore),
            // Schedule items
            RecommendationSchedulingGuard(),
            // Filter by quality
            RecommendationQualityFilterGuard(minScore: 0.3),
          ],
          onError: (error, stackTrace) =>
              _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
                (error: error, stackTrace: stackTrace),
                ..._errorsObserver.value,
              ],
        );

    // Initialize the provider and internally it will start the sync process.
    final _ = RecommendationProvider(
      engine: recommendationPresentum.config.engine,
      store: recommendationStore,
    );
  }
}
