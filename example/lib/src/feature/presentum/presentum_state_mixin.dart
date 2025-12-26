import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/feature/presentum/feature_presentum_storage.dart';
import 'package:example/src/feature/presentum/guards/feature_scheduling_guard.dart';
import 'package:example/src/feature/presentum/guards/sync_state_with_candidates.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/feature/presentum/provider.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

mixin FeaturePresentumStateMixin<T extends StatefulWidget> on State<T> {
  late final Presentum<FeatureItem, AppSurface, AppVariant> featurePresentum;
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
          library: 'FeaturePresentum',
        ),
      );
    });

    final deps = Dependencies.of(context);

    // Presentum storage used to store the state(dismissed, shown, converted)
    // of the feature items.
    _storage = FeaturePresentumStorage(prefs: deps.sharedPreferences);

    final eligibility = DefaultEligibilityResolver<FeatureItem>(
      // Standar set of rules that covers most of the common cases.
      rules: createStandardRules(),
      extractors: [
        /// Extracts the `time_range` from the feature item.
        const TimeRangeExtractor(),

        /// Extracts the `user_segments` from the feature item.
        const AnySegmentExtractor(),

        /// Extracts the `is_active` from the feature item.
        const ConstantExtractor(metadataKey: 'is_active'),

        /// Extracts the `any_of` from the feature item.
        const AnyOfExtractor(
          nestedExtractors: [
            TimeRangeExtractor(),
            ConstantExtractor(metadataKey: 'is_active'),
          ],
        ),
      ],
    );

    featurePresentum = Presentum<FeatureItem, AppSurface, AppVariant>(
      storage: _storage,
      eventHandlers: [PresentumStorageEventHandler(storage: _storage)],
      guards: [
        // Syncs the state with the candidates.
        SyncStateWithCandidatesGuard(),
        // Schedules the feature items.
        FeatureSchedulingGuard(
          catalog: deps.featureCatalog,
          prefs: deps.featurePreferences,
          eligibilityResolver: eligibility,
        ),
      ],
      onError: (error, stackTrace) =>
          _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ..._errorsObserver.value,
          ],
    );

    // Initialize the provider and internally it will start the sync process.
    final _ = FeatureDrivenProvider(
      engine: featurePresentum.config.engine,
      catalog: deps.featureCatalog,
      prefs: deps.featurePreferences,
    );
  }
}
