import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/campaigns_storage.dart';
import 'package:example/src/campaigns/presentum/guards/app_opened_count_guard.dart';
import 'package:example/src/campaigns/presentum/guards/remove_ineligible_candidates_guard.dart';
import 'package:example/src/campaigns/presentum/guards/scheduling_guard.dart';
import 'package:example/src/campaigns/presentum/guards/sync_state_with_candidates_guard.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/app_lifecycle_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';

mixin CampaignsPresentumStateMixin<T extends StatefulWidget> on State<T> {
  late final Presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  campaignPresentum;
  late final CampaignsProvider _provider;
  late final EligibilityResolver<HasMetadata> _eligibility;
  late final CampaignPersistentStorage _storage;

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
          library: 'CampaignsPresentum',
        ),
      );
    });

    final deps = Dependencies.of(context);

    _storage = CampaignPersistentStorage(prefs: deps.sharedPreferences);

    _eligibility = DefaultEligibilityResolver<HasMetadata>(
      rules: [...createStandardRules()],
      extractors: const [
        TimeRangeExtractor(),
        ConstantExtractor(metadataKey: 'is_active'),
        AnyOfExtractor(
          nestedExtractors: [
            TimeRangeExtractor(),
            ConstantExtractor(metadataKey: 'is_active'),
          ],
        ),
      ],
    );

    campaignPresentum =
        Presentum<CampaignPresentumItem, CampaignSurface, CampaignVariant>(
          storage: _storage,
          eventHandlers: [PresentumStorageEventHandler(storage: _storage)],
          guards: [
            AppOpenedCountGuard(
              appOpenedCount: deps.userRepository.fetchAppOpenedCount,
            ),
            AppLifecycleGuard<
              CampaignPresentumItem,
              CampaignSurface,
              CampaignVariant
            >(refresh: AppLifecycleRefresh()),
            SyncCampaignsStateWithCandidatesGuard(),
            CampaignSchedulingGuard(eligibility: _eligibility),
            RemoveIneligibleCampaignsGuard(eligibility: _eligibility),
          ],
          onError: (error, stackTrace) =>
              _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
                (error: error, stackTrace: stackTrace),
                ..._errorsObserver.value,
              ],
        );

    final remoteConfigRepository = deps.remoteConfigRepository;

    _provider = CampaignsProvider(
      storage: _storage,
      engine: campaignPresentum.config.engine,
      eligibility: _eligibility,
      remoteConfigRepository: remoteConfigRepository,
      onError: (error, stackTrace) =>
          _errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ..._errorsObserver.value,
          ],
    );

    unawaited(_provider.init());
  }
}
