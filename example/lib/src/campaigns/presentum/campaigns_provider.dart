// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/campaigns/presentum/campaigns_storage.dart';
import 'package:firebase_remote_config_client/firebase_remote_config_client.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:remote_config_repository/remote_config_repository.dart';

/// Mock campaign provider for testing and development.
class CampaignsProvider {
  CampaignsProvider({
    required CampaignPersistentStorage storage,
    required PresentumEngine<
      CampaignPresentumItem,
      CampaignSurface,
      CampaignVariant
    >
    engine,
    required EligibilityResolver<HasMetadata> eligibility,
    required RemoteConfigRepository remoteConfigRepository,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _storage = storage,
       _engine = engine,
       _eligibility = eligibility,
       _remoteConfigRepository = remoteConfigRepository,
       _onError = onError;

  // ignore: unused_field
  final CampaignPersistentStorage _storage;
  final RemoteConfigRepository _remoteConfigRepository;
  final PresentumEngine<CampaignPresentumItem, CampaignSurface, CampaignVariant>
  _engine;
  final EligibilityResolver<HasMetadata> _eligibility;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  final Map<String, Timer> _endTimers = <String, Timer>{};
  final Map<String, Timer> _startTimers = <String, Timer>{};

  /// Current list of campaign payloads.
  final List<CampaignPayload> _campaigns = <CampaignPayload>[];

  late StreamSubscription<RemoteConfigUpdate> _remoteConfigSubscription;

  Future<void> init() async {
    await _fetchAndAddCampaign();

    _remoteConfigSubscription = _remoteConfigRepository
        .onConfigUpdated()
        .listen((update) async {
          await _remoteConfigRepository.activate();

          dev.log(
            'remote config updated: ${update.updatedKeys}',
            name: 'CampaignProvider',
          );
          if (!update.updatedKeys.contains(RemoteConfigParameter.campaigns)) {
            return;
          }

          await _fetchAndAddCampaign();
        });
  }

  Future<void> _fetchAndAddCampaign() async {
    try {
      final campaignJsonString = await _remoteConfigRepository
          .fetchRemoteData<String>(RemoteConfigParameter.campaigns);

      dev.log(
        'campaignJsonString: $campaignJsonString',
        name: 'CampaignProvider',
      );

      if (campaignJsonString case final json when json.isNotEmpty) {
        try {
          final jsonList = await compute(
            (json) => (jsonDecode(json) as List<dynamic>)
                .cast<Map<String, Object?>>(),
            json,
          );
          final newCampaigns = jsonList.map(CampaignPayload.fromJson).toList();

          // Diff the new campaigns against stored campaigns.
          await _diffAndUpdateCampaigns(newCampaigns);
        } on Object catch (error, stackTrace) {
          _onError?.call(error, stackTrace);
        }
      } else {
        // Empty config - remove all campaigns.
        if (_campaigns.isNotEmpty) {
          dev.log(
            'Remote config is empty, removing all campaigns',
            name: 'CampaignProvider',
          );
          await _removeAllCampaigns();
        }
      }
    } on Object catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    }
  }

  /// Diff new campaign against stored campaigns and update accordingly.
  Future<void> _diffAndUpdateCampaigns(
    List<CampaignPayload> newCampaigns,
  ) async {
    final oldCampaigns = List<CampaignPayload>.from(_campaigns);

    // Calculate diff.
    final diffOps = DiffUtils.calculateListDiffOperations<CampaignPayload>(
      oldCampaigns,
      newCampaigns,
      (campaign) => campaign.id,
      detectMoves: false,
      customContentsComparison: (oldItem, newItem) {
        // Compare metadata and variants to detect content changes.
        if (oldItem.priority != newItem.priority) return false;
        if (oldItem.options.length != newItem.options.length) return false;

        // Compare metadata.
        if (!_areMetadataEqual(oldItem.metadata, newItem.metadata)) {
          return false;
        }

        // Compare variants.
        for (var i = 0; i < oldItem.options.length; i++) {
          final oldVariant = oldItem.options[i];
          final newVariant = newItem.options[i];

          if (oldVariant.surface != newVariant.surface) return false;
          if (oldVariant.variant != newVariant.variant) return false;
          if (oldVariant.stage != newVariant.stage) return false;
          if (oldVariant.maxImpressions != newVariant.maxImpressions) {
            return false;
          }
          if (oldVariant.cooldownMinutes != newVariant.cooldownMinutes) {
            return false;
          }
          if (oldVariant.isDismissible != newVariant.isDismissible) {
            return false;
          }
          if (oldVariant.alwaysOnIfEligible != newVariant.alwaysOnIfEligible) {
            return false;
          }
        }

        return true;
      },
    );

    // Process diff operations.
    for (final insertion in diffOps.insertions) {
      dev.log(
        'Campaign inserted: ${newCampaigns[insertion.position].id}',
        name: 'CampaignProvider',
      );
      final campaign = newCampaigns[insertion.position];
      _campaigns.insert(insertion.position, campaign);
      await addCampaign(campaign);
    }

    for (final removal in diffOps.removals) {
      final campaign = oldCampaigns[removal.position];
      dev.log('Campaign removed: ${campaign.id}', name: 'CampaignProvider');
      _campaigns.removeWhere((c) => c.id == campaign.id);
      await _removeCampaign(campaign);
    }

    for (final change in diffOps.changes) {
      final newCampaign = change.payload as CampaignPayload?;
      if (newCampaign != null) {
        dev.log(
          'Campaign changed: ${newCampaign.id}',
          name: 'CampaignProvider',
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

  /// Deep equality check for metadata maps.
  bool _areMetadataEqual(
    Map<String, Object?> oldMetadata,
    Map<String, Object?> newMetadata,
  ) {
    if (oldMetadata.length != newMetadata.length) return false;

    for (final entry in oldMetadata.entries) {
      if (!newMetadata.containsKey(entry.key)) return false;
      if (newMetadata[entry.key] != entry.value) return false;
    }

    return true;
  }

  /// Remove a specific campaign from the engine.
  ///
  /// [cancelStartTimer] - whether to cancel scheduled start timer.
  /// Set to false when removing an ineligible campaign that should start
  /// in the future.
  Future<void> _removeCampaign(
    CampaignPayload campaign, {
    bool cancelStartTimer = true,
  }) async {
    // Cancel any scheduled timers for this campaign.
    _endTimers[campaign.id]?.cancel();
    _endTimers.remove(campaign.id);

    if (cancelStartTimer) {
      _startTimers[campaign.id]?.cancel();
      _startTimers.remove(campaign.id);
    }

    if (_campaigns.map((e) => e.id).contains(campaign.id)) {
      _campaigns.removeWhere((e) => e.id == campaign.id);
    }

    // Remove from candidates.
    _engine.setCandidates(
      (state, currentCandidates) => currentCandidates
          .where((entry) => entry.payload.id != campaign.id)
          .toList(),
    );
  }

  /// Remove all campaigns.
  Future<void> _removeAllCampaigns() async {
    final campaignsToRemove = List<CampaignPayload>.from(_campaigns);
    _campaigns.clear();

    await Future.wait(campaignsToRemove.map(_removeCampaign));
  }

  /// Expand a [CampaignPayload] into concrete presentation entries and add
  /// them.
  Future<void> addCampaign(CampaignPayload campaign) async {
    try {
      if (!CampaignId.isSupported(campaign.id)) {
        await _removeCampaign(campaign);
        _onError?.call(
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
        // If the campaign is not eligible due to a date range condition,
        // schedule it for addition at start date.
        final isScheduledForFuture = condition is TimeRangeEligibility;
        if (isScheduledForFuture) {
          _scheduleForFuture(campaign);
        }

        /// Maybe remove the campaign, if it was eligible, but is now ineligible.
        ///
        /// For example, if the is_active flag was true and changed to false,
        /// or if now was in between start and end dates range, but now is not.
        ///
        /// In such cases, the campaign should be removed from the candidates
        /// and engine state.
        ///
        /// Don't cancel start timer if we just scheduled it for the future.
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

      _engine.setCandidatesWithDiff((state) => newEntries);

      _scheduleRemovalAtEnd(campaign);
    } on Object catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    }
  }

  // Schedule removal at end date
  void _scheduleRemovalAtEnd(CampaignPayload campaign) {
    // Cancel existing timer if any.
    _endTimers[campaign.id]?.cancel();

    final timeRange = campaign.metadata.timeRange();
    if (timeRange == null) return;

    final endDate = timeRange.end.toUtc();
    final now = DateTime.now().toUtc();
    if (now.isAfter(endDate)) return;

    final endDelay = endDate.difference(now);
    final endTimer = Timer(endDelay, () {
      _campaigns.removeWhere((c) => c.id == campaign.id);
      _engine.setCandidates(
        (state, currentCandidates) => currentCandidates
            .where((entry) => entry.id != campaign.id)
            .toList(),
      );
      _endTimers.remove(campaign.id);
    });

    _endTimers[campaign.id] = endTimer;
  }

  // Schedule addition at start date if not eligible now and is before end date
  void _scheduleForFuture(CampaignPayload campaign) {
    // Cancel existing timer if any.
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

    // If current time is before start date, schedule it
    if (now.isBefore(startDate)) {
      final delay = startDate.difference(now);
      final timer = Timer(delay, () {
        addCampaign(campaign);
        _startTimers.remove(campaign.id);
      });
      _startTimers[campaign.id] = timer;
    }
  }

  /// Dispose of resources.
  void dispose() {
    for (final timer in _endTimers.values) {
      timer.cancel();
    }
    _endTimers.clear();
    for (final timer in _startTimers.values) {
      timer.cancel();
    }
    _startTimers.clear();
    _remoteConfigSubscription.cancel();
  }
}
