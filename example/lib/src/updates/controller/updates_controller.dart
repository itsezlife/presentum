import 'dart:async';

import 'package:control/control.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/updates/controller/updates_state.dart';
import 'package:example/src/updates/data/updates_store.dart';
import 'package:example/src/updates/presentum/eligibility/update_status_eligibility.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:example/src/updates/presentum/steps/updates_scheduling_step.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class UpdatesController extends StateController<UpdatesState>
    with DroppableControllerHandler {
  UpdatesController({
    required PersistentPresentumStorage<AppSurface, AppVariant> storage,
    required ShorebirdUpdatesStore updatesStore,
    super.initialState = const UpdatesState.initial(),
  }) : _storage = storage,
       _updatesStore = updatesStore {
    _pipeline = PresentumStepsPipeline<AppUpdatesItem, AppSurface, AppVariant>(
      storage: _storage,
      steps: [UpdatesSchedulingStep(eligibilityResolver: _eligibilityResolver)],
    );
    _lifecycleListener = AppLifecycleListener(onResume: _onUpdatesStoreChanged);
    _updatesStore.addListener(_onUpdatesStoreChanged);
    _onUpdatesStoreChanged();
  }

  final PersistentPresentumStorage<AppSurface, AppVariant> _storage;
  final ShorebirdUpdatesStore _updatesStore;

  late final PresentumStepsPipeline<AppUpdatesItem, AppSurface, AppVariant>
  _pipeline;
  late final AppLifecycleListener _lifecycleListener;

  final _eligibilityResolver = EligibilityResolver<AppUpdatesItem>(
    rules: const [UpdateStatusRule()],
    extractors: [
      const TimeRangeExtractor(),
      const ConstantExtractor(metadataKey: 'is_active'),
      const UpdateStatusExtractor(),
    ],
  );

  UpdateStatus? _currentStatus;

  void _onUpdatesStoreChanged() {
    final status = _updatesStore.status;
    if (status == UpdateStatus.outdated) {
      _updatesStore.update();
    }
    handle(_checkForUpdates);
  }

  Future<void> _checkForUpdates() async {
    final status = await _updatesStore.checkForUpdate();

    if (status == _currentStatus) return;
    _currentStatus = status;

    if (status == UpdateStatus.outdated) {
      await _updatesStore.update();
    }

    _refreshCandidates();
    await _resolveAndCommit();
  }

  void _refreshCandidates() {
    final candidates = <AppUpdatesItem>[];

    if (_currentStatus == UpdateStatus.restartRequired) {
      const updatePayload = AppUpdatesPayload(
        id: 'app_update_required',
        priority: 100,
        metadata: {'required_update_status': 'restartRequired'},
        options: [
          AppUpdatesOption(
            surface: AppSurface.updateSnackbar,
            variant: AppVariant.snackbar,
            isDismissible: false,
            alwaysOnIfEligible: true,
          ),
        ],
      );

      for (final option in updatePayload.options) {
        candidates.add(AppUpdatesItem(payload: updatePayload, option: option));
      }
    }

    setState(state.copyWith(candidates: candidates));
  }

  void revalidate() => handle(_resolveAndCommit);

  Future<void> _resolveAndCommit() async {
    final context = await _buildContext();
    final newSlots = await _pipeline(
      candidates: state.candidates,
      context: context,
      current: state.slots,
      history: state.history,
    );
    setState(
      state.copyWith(
        slots: newSlots,
        history: state.history.record(slots: newSlots, current: state.slots),
      ),
    );
  }

  Future<PresentumContext> _buildContext() async => <String, Object?>{
    'update_status': _updatesStore.status,
  };

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _updatesStore.removeListener(_onUpdatesStoreChanged);
    super.dispose();
  }
}
