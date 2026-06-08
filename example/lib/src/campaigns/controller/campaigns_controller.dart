import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:collection/collection.dart';
import 'package:control/control.dart';
import 'package:example/src/app/data/user_repository.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/campaigns_storage.dart';
import 'package:example/src/campaigns/presentum/steps/campaign_scheduling_step.dart';
import 'package:example/src/campaigns/presentum/steps/remove_ineligible_campaigns_step.dart';
import 'package:example/src/campaigns/presentum/steps/sync_campaigns_slots_step.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:remote_config_repository/remote_config_repository.dart';

/// Owns campaign slots, history, candidates, and remote-config sync.
class CampaignsController extends StateController<CampaignsState>
    with DroppableControllerHandler {
  CampaignsController({
    required CampaignPersistentStorage storage,
    required EligibilityResolver<HasMetadata> eligibility,
    required RemoteConfigRepository remoteConfigRepository,
    required UserRepository userRepository,
    super.initialState = const CampaignsState.initial(),
  }) : _storage = storage,
       _eligibility = eligibility,
       _remoteConfigRepository = remoteConfigRepository,
       _userRepository = userRepository {
    _pipeline =
        PresentumStepsPipeline<
          CampaignPresentumItem,
          CampaignSurface,
          CampaignVariant
        >(
          storage: _storage,
          steps: [
            const SyncCampaignsSlotsStep(),
            CampaignSchedulingStep(eligibility: _eligibility),
            RemoveIneligibleCampaignsStep(eligibility: _eligibility),
          ],
        );
    _lifecycleListener = AppLifecycleListener(onResume: _revalidate);
  }

  final CampaignPersistentStorage _storage;
  final EligibilityResolver<HasMetadata> _eligibility;
  final RemoteConfigRepository _remoteConfigRepository;
  final UserRepository _userRepository;

  late final PresentumStepsPipeline<
    CampaignPresentumItem,
    CampaignSurface,
    CampaignVariant
  >
  _pipeline;
  late final AppLifecycleListener _lifecycleListener;

  final List<
    PresentumEventHandler<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >
  >
  _eventHandlers = [];

  final Map<String, Timer> _endTimers = <String, Timer>{};
  final Map<String, Timer> _startTimers = <String, Timer>{};
  final List<CampaignPayload> _campaigns = <CampaignPayload>[];

  StreamSubscription<RemoteConfigUpdate>? _remoteConfigSubscription;

  CampaignPersistentStorage get storage => _storage;

  /// Initialize by fetching campaigns and listening for remote-config updates.
  Future<void> init() async {
    _eventHandlers.add(PresentumStorageEventHandler(storage: _storage));
    await _fetchAndAddCampaign();

    _remoteConfigSubscription = _remoteConfigRepository
        .onConfigUpdated()
        .listen((update) async {
          await _remoteConfigRepository.activate();

          dev.log(
            'remote config updated: ${update.updatedKeys}',
            name: 'CampaignsController',
          );
          if (!update.updatedKeys.contains(RemoteConfigParameter.campaigns)) {
            return;
          }

          await _fetchAndAddCampaign();
        });
  }

  void _revalidate() => revalidate();

  /// Re-runs the campaigns pipeline and commits slot/history updates.
  void revalidate() => handle(_resolveAndCommit);

  Future<void> _resolveAndCommit({
    PresentumSlotState<CampaignPresentumItem, CampaignSurface, CampaignVariant>?
    current,
  }) async {
    final committed = current ?? state.slots;
    final context = await _buildContext();
    final newSlots = await _pipeline(
      candidates: state.candidates,
      context: context,
      current: committed,
      history: state.history,
    );
    setState(
      state.copyWith(
        slots: newSlots,
        history: state.history.record(slots: newSlots, current: state.slots),
      ),
    );
  }

  Future<PresentumContext> _buildContext() async {
    final count = await _userRepository.fetchAppOpenedCount();
    return <String, Object?>{'appOpenedCount': count};
  }

  Future<void> markShown(CampaignPresentumItem item) =>
      PresentumLifecycle.shown(
        item: item,
        storage: _storage,
        handlers: _eventHandlers,
      );

  Future<void> markDismissed(CampaignPresentumItem item) => handle(() async {
    final dismissedSlots = await PresentumLifecycle.dismiss(
      slots: state.slots,
      surface: item.surface,
      item: item,
      storage: _storage,
      handlers: _eventHandlers,
    );
    await _resolveAndCommit(current: dismissedSlots);
  });

  Future<void> _fetchAndAddCampaign() async {
    try {
      final campaignJsonString = await _remoteConfigRepository
          .fetchRemoteData<String>(RemoteConfigParameter.campaigns);

      dev.log(
        'campaignJsonString: $campaignJsonString',
        name: 'CampaignsController',
      );

      if (campaignJsonString case final json when json.isNotEmpty) {
        try {
          final jsonList = await compute(
            (json) => (jsonDecode(json) as List<dynamic>)
                .cast<Map<String, Object?>>(),
            json,
          );
          final newCampaigns = jsonList.map(CampaignPayload.fromJson).toList();
          await _diffAndUpdateCampaigns(newCampaigns);
        } on Object catch (error, stackTrace) {
          super.onError(error, stackTrace);
        }
      } else if (_campaigns.isNotEmpty) {
        dev.log(
          'Remote config is empty, removing all campaigns',
          name: 'CampaignsController',
        );
        await _removeAllCampaigns();
      }
    } on Object catch (error, stackTrace) {
      super.onError(error, stackTrace);
    }
  }

  Future<void> _diffAndUpdateCampaigns(
    List<CampaignPayload> newCampaigns,
  ) async {
    final oldCampaigns = List<CampaignPayload>.from(_campaigns);

    final diffOps = DiffUtils.calculateListDiffOperations<CampaignPayload>(
      oldCampaigns,
      newCampaigns,
      (campaign) => campaign.id,
      detectMoves: false,
      customContentsComparison: (oldItem, newItem) {
        if (oldItem.priority != newItem.priority) return false;
        if (!const MapEquality<String, Object?>().equals(
          oldItem.metadata,
          newItem.metadata,
        )) {
          return false;
        }

        if (!const ListEquality<CampaignPresentumOption>().equals(
          oldItem.options,
          newItem.options,
        )) {
          return false;
        }
        return true;
      },
    );

    for (final insertion in diffOps.insertions) {
      dev.log(
        'Campaign inserted: ${newCampaigns[insertion.position].id}',
        name: 'CampaignsController',
      );
      final campaign = newCampaigns[insertion.position];
      _campaigns.insert(insertion.position, campaign);
      await addCampaign(campaign);
    }

    for (final removal in diffOps.removals) {
      final campaign = oldCampaigns[removal.position];
      dev.log('Campaign removed: ${campaign.id}', name: 'CampaignsController');
      _campaigns.removeWhere((c) => c.id == campaign.id);
      await _removeCampaign(campaign);
    }

    for (final change in diffOps.changes) {
      final newCampaign = change.payload as CampaignPayload?;
      if (newCampaign != null) {
        dev.log(
          'Campaign changed: ${newCampaign.id}',
          name: 'CampaignsController',
        );
        final index = _campaigns.indexWhere((c) => c.id == newCampaign.id);
        if (index != -1) {
          _campaigns[index] = newCampaign;
        }
        await addCampaign(newCampaign);
      }
    }

    diffOps.clear();
  }

  Future<void> _removeCampaign(
    CampaignPayload campaign, {
    bool cancelStartTimer = true,
  }) async {
    _endTimers[campaign.id]?.cancel();
    _endTimers.remove(campaign.id);

    if (cancelStartTimer) {
      _startTimers[campaign.id]?.cancel();
      _startTimers.remove(campaign.id);
    }

    _campaigns.removeWhere((e) => e.id == campaign.id);

    final updatedCandidates = state.candidates
        .where((entry) => entry.payload.id != campaign.id)
        .toList();
    setState(state.copyWith(candidates: updatedCandidates));
    revalidate();
  }

  Future<void> _removeAllCampaigns() async {
    final campaignsToRemove = List<CampaignPayload>.from(_campaigns);
    _campaigns.clear();

    await Future.wait(campaignsToRemove.map(_removeCampaign));
  }

  Future<void> addCampaign(CampaignPayload campaign) async {
    try {
      if (!CampaignId.isSupported(campaign.id)) {
        await _removeCampaign(campaign);
        super.onError(
          'Campaign ${campaign.id} is not supported. '
          'Campaign ID must be one of: ${CampaignId.values.join(', ')}',
          StackTrace.current,
        );
        return;
      }

      final context = <String, Object?>{};
      final ineligibleCondition = await _eligibility.getIneligibleCondition(
        campaign,
        context,
      );

      if (ineligibleCondition case final condition?) {
        final isScheduledForFuture = condition is TimeRangeEligibility;
        if (isScheduledForFuture) {
          _scheduleForFuture(campaign);
        }

        await _removeCampaign(
          campaign,
          cancelStartTimer: !isScheduledForFuture,
        );
        return;
      }

      final newEntries = [
        for (final option in campaign.options)
          CampaignPresentumItem(payload: campaign, option: option),
      ];

      final updatedCandidates = [
        ...state.candidates.where((e) => e.payload.id != campaign.id),
        ...newEntries,
      ];
      setState(state.copyWith(candidates: updatedCandidates));
      revalidate();

      _scheduleRemovalAtEnd(campaign);
    } on Object catch (error, stackTrace) {
      super.onError(error, stackTrace);
    }
  }

  void _scheduleRemovalAtEnd(CampaignPayload campaign) {
    _endTimers[campaign.id]?.cancel();

    final timeRange = campaign.metadata.timeRange();
    if (timeRange == null) return;

    final endDate = timeRange.end.toUtc();
    final now = DateTime.now().toUtc();
    if (now.isAfter(endDate)) return;

    final endDelay = endDate.difference(now);
    final endTimer = Timer(endDelay, () {
      _campaigns.removeWhere((c) => c.id == campaign.id);
      final updatedCandidates = state.candidates
          .where((entry) => entry.id != campaign.id)
          .toList();
      setState(state.copyWith(candidates: updatedCandidates));
      revalidate();
      _endTimers.remove(campaign.id);
    });

    _endTimers[campaign.id] = endTimer;
  }

  void _scheduleForFuture(CampaignPayload campaign) {
    _startTimers[campaign.id]?.cancel();

    final timeRange = campaign.metadata['time_range'] as Map<String, Object?>?;
    if (timeRange == null) return;

    final startDateStr = timeRange['start'] as String?;
    if (startDateStr == null) return;

    final endDateStr = timeRange['end'] as String?;
    final endDate = endDateStr != null
        ? DateTime.tryParse(endDateStr)?.toUtc()
        : null;
    final now = DateTime.now().toUtc();

    if (endDate != null && now.isAfter(endDate)) return;

    final startDate = DateTime.parse(startDateStr).toUtc();

    if (now.isBefore(startDate)) {
      final delay = startDate.difference(now);
      final timer = Timer(delay, () {
        addCampaign(campaign);
        _startTimers.remove(campaign.id);
      });
      _startTimers[campaign.id] = timer;
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    for (final timer in _endTimers.values) {
      timer.cancel();
    }
    _endTimers.clear();
    for (final timer in _startTimers.values) {
      timer.cancel();
    }
    _startTimers.clear();
    _remoteConfigSubscription?.cancel();
    super.dispose();
  }
}
