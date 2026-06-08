import 'dart:async';

import 'package:control/control.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/maintenance/controller/maintenance_state.dart';
import 'package:example/src/maintenance/data/maintenance_store.dart';
import 'package:example/src/maintenance/presentum/maintenance_updates_coordinator.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/maintenance/presentum/steps/maintenance_scheduling_step.dart';
import 'package:example/src/maintenance/presentum/steps/remove_ineligible_maintenance_step.dart';
import 'package:example/src/maintenance/presentum/steps/sync_maintenance_slots_step.dart';
import 'package:example/src/updates/data/updates_store.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class MaintenanceController extends StateController<MaintenanceState>
    with DroppableControllerHandler {
  MaintenanceController({
    required PersistentPresentumStorage<AppSurface, AppVariant> storage,
    required MaintenanceStore maintenanceStore,
    required ShorebirdUpdatesStore updatesStore,
    super.initialState = const MaintenanceState.initial(),
  }) : _storage = storage,
       _maintenanceStore = maintenanceStore,
       _updatesCoordinator = MaintenanceUpdatesCoordinator(
         updatesStore: updatesStore,
       ) {
    _pipeline = PresentumStepsPipeline<MaintenanceItem, AppSurface, AppVariant>(
      storage: _storage,
      steps: [
        const SyncMaintenanceSlotsStep(),
        MaintenanceSchedulingStep(eligibilityResolver: eligibilityResolver),
        RemoveIneligibleMaintenanceStep(eligibility: eligibilityResolver),
      ],
    );
    _maintenanceStore.addListener(_evaluateCandidates);
    _lifecycleListener = AppLifecycleListener(onResume: _evaluateCandidates);
    _evaluateCandidates();
  }

  final PersistentPresentumStorage<AppSurface, AppVariant> _storage;
  final MaintenanceStore _maintenanceStore;
  final MaintenanceUpdatesCoordinator _updatesCoordinator;

  late final PresentumStepsPipeline<MaintenanceItem, AppSurface, AppVariant>
  _pipeline;
  late final AppLifecycleListener _lifecycleListener;

  final eligibilityResolver = EligibilityResolver<MaintenanceItem>(
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

  void _evaluateCandidates() => handle(() async {
    final maintenancePayload = _maintenanceStore.maintenancePayload;

    if (maintenancePayload == null) {
      final updatedCandidates = state.candidates
          .where((c) => c.payload.id != MaintenanceId.maintenance)
          .toList();
      setState(state.copyWith(candidates: updatedCandidates));
      await _resolveAndCommit();
      return;
    }

    final maintenanceCandidates = [
      for (final option in maintenancePayload.options)
        MaintenanceItem(payload: maintenancePayload, option: option),
    ];

    final eligibleCandidates = <MaintenanceItem>[];
    for (final candidate in maintenanceCandidates) {
      if (await eligibilityResolver.isEligible(candidate, {})) {
        eligibleCandidates.add(candidate);
      }
    }

    final updatedCandidates = eligibleCandidates.isNotEmpty
        ? eligibleCandidates
        : state.candidates
              .where((c) => c.payload.id != maintenancePayload.id)
              .toList();

    setState(state.copyWith(candidates: updatedCandidates));
    await _resolveAndCommit();
  });

  void revalidate() => handle(_resolveAndCommit);

  Future<void> _resolveAndCommit() async {
    final newSlots = await _pipeline(
      candidates: state.candidates,
      context: const {},
      current: state.slots,
      history: state.history,
      onTransition: _onTransition,
    );
    setState(
      state.copyWith(
        slots: newSlots,
        history: state.history.record(slots: newSlots, current: state.slots),
      ),
    );
  }

  void _onTransition(
    PresentumSlotsTransition<MaintenanceItem, AppSurface, AppVariant>
    transition,
  ) {
    final diff = transition.diff;

    final maintenanceDeactivated = diff.itemsDeactivated.any(
      (item) => item.surface == AppSurface.maintenanceView,
    );
    if (maintenanceDeactivated) {
      _updatesCoordinator.onMaintenanceEnded();
      return;
    }

    final maintenanceActivated = diff.itemsActivated.any(
      (item) => item.surface == AppSurface.maintenanceView,
    );
    if (maintenanceActivated) {
      _updatesCoordinator.onMaintenanceStarted();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _maintenanceStore.removeListener(_evaluateCandidates);
    _updatesCoordinator.dispose();
    super.dispose();
  }
}
