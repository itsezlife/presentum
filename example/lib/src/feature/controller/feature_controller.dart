// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer' as dev;

import 'package:control/control.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/feature/controller/feature_state.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/local_payloads.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:example/src/feature/presentum/steps/feature_scheduling_step.dart';
import 'package:example/src/feature/presentum/steps/sync_feature_slots_step.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class FeatureController extends StateController<FeatureState>
    with DroppableControllerHandler {
  FeatureController({
    required PersistentPresentumStorage<AppSurface, AppVariant> storage,
    required FeatureCatalogStore catalog,
    required FeaturePreferencesStore prefs,
    super.initialState = const FeatureState.initial(),
  }) : _storage = storage,
       _catalog = catalog,
       _prefs = prefs {
    _pipeline = PresentumStepsPipeline<FeatureItem, AppSurface, AppVariant>(
      storage: _storage,
      steps: [
        const SyncFeatureSlotsStep(),
        FeatureSchedulingStep(
          catalog: _catalog,
          prefs: _prefs,
          eligibilityResolver: eligibilityResolver,
        ),
      ],
    );
    _catalog.addListener(_sync);
    _prefs.addListener(revalidate);
    Future.microtask(_sync);
  }

  final PersistentPresentumStorage<AppSurface, AppVariant> _storage;
  final FeatureCatalogStore _catalog;
  final FeaturePreferencesStore _prefs;

  late final PresentumStepsPipeline<FeatureItem, AppSurface, AppVariant>
  _pipeline;

  final eligibilityResolver = EligibilityResolver<FeatureItem>(
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

  final List<PresentumEventHandler<FeatureItem, AppSurface, AppVariant>>
  _eventHandlers = [];

  final Map<String, FeatureDefinition> _currentFeatures =
      <String, FeatureDefinition>{};

  PersistentPresentumStorage<AppSurface, AppVariant> get storage => _storage;

  void _sync() => handle(() async {
    await _prefs.pruneTo(_catalog.features.keys.toSet());
    final newFeatures = Map<String, FeatureDefinition>.from(_catalog.features);
    await _diffAndUpdateFeatures(newFeatures);
  });

  Future<void> _diffAndUpdateFeatures(
    Map<String, FeatureDefinition> newFeatures,
  ) async {
    final oldFeatures = Map<String, FeatureDefinition>.from(_currentFeatures);
    final oldFeatureList = List<FeatureDefinition>.from(oldFeatures.values);
    final newFeatureList = List<FeatureDefinition>.from(newFeatures.values);

    final diffOps = DiffUtils.calculateListDiffOperations<FeatureDefinition>(
      oldFeatureList,
      newFeatureList,
      (feature) => feature.key,
      detectMoves: false,
      customContentsComparison: (oldFeature, newFeature) {
        if (oldFeature.key != newFeature.key) return false;
        if (oldFeature.defaultEnabled != newFeature.defaultEnabled) {
          return false;
        }
        if (oldFeature.order != newFeature.order) return false;
        return true;
      },
    );

    var hasChanges = false;

    for (final insertion in diffOps.insertions) {
      final features = newFeatureList.sublist(
        insertion.position,
        insertion.position + insertion.count,
      );
      for (final feature in features) {
        _currentFeatures[feature.key] = feature;
        hasChanges = true;
      }
    }

    for (final removal in diffOps.removals) {
      for (var i = 0; i < removal.count; i++) {
        final feature = oldFeatureList[removal.position + i];
        _currentFeatures.remove(feature.key);
        hasChanges = true;
      }
    }

    for (final change in diffOps.changes) {
      final updatedFeature = change.payload as FeatureDefinition?;
      if (updatedFeature case final feature?) {
        _currentFeatures[feature.key] = feature;
        hasChanges = true;
      }
    }

    diffOps.clear();

    if (hasChanges) {
      await _recalculateCandidates();
    }
  }

  Future<void> _recalculateCandidates() async {
    final candidates = <FeatureItem>[];

    for (final feature in _currentFeatures.values) {
      candidates.addAll(_createSettingsCandidates(feature));
    }

    for (final payload in featureLocalPayloads.values) {
      if (payload.dependsOnFeatureKey case final dependsOnFeatureKey?) {
        if (!_currentFeatures.containsKey(dependsOnFeatureKey)) {
          dev.log(
            'Skipping payload ${payload.id} because dependent '
            'feature "$dependsOnFeatureKey" is not in current features',
            name: 'FeatureController',
          );
          continue;
        }
      }

      for (final opt in payload.options) {
        candidates.add(FeatureItem(payload: payload, option: opt));
      }
    }

    setState(state.copyWith(candidates: candidates));
    await _resolveAndCommit();
  }

  List<FeatureItem> _createSettingsCandidates(FeatureDefinition feature) {
    final settingsPayload = FeaturePayload(
      id: 'settings_toggle:${feature.key}',
      featureKey: feature.key,
      priority: 0,
      options: const [
        FeatureOption(
          surface: AppSurface.settingsToggles,
          variant: AppVariant.settingToggleRow,
          isDismissible: false,
          alwaysOnIfEligible: true,
        ),
      ],
    );

    return [
      for (final opt in settingsPayload.options)
        FeatureItem(
          payload: settingsPayload,
          option: FeatureOption(
            surface: opt.surface,
            variant: opt.variant,
            isDismissible: opt.isDismissible,
            stage: feature.order,
            maxImpressions: opt.maxImpressions,
            cooldownMinutes: opt.cooldownMinutes,
            alwaysOnIfEligible: opt.alwaysOnIfEligible,
          ),
        ),
    ];
  }

  void revalidate() => handle(_resolveAndCommit);

  Future<void> _resolveAndCommit() async {
    final newSlots = await _pipeline(
      candidates: state.candidates,
      context: const {},
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

  Future<void> markShown(FeatureItem item) => PresentumLifecycle.shown(
    item: item,
    storage: _storage,
    handlers: _eventHandlers,
  );

  Future<void> markDismissed(FeatureItem item) => handle(() async {
    final dismissedSlots =
        await PresentumLifecycle.dismiss<FeatureItem, AppSurface, AppVariant>(
          slots: state.slots,
          surface: item.surface,
          item: item,
          storage: _storage,
          handlers: _eventHandlers,
        );
    setState(
      state.copyWith(
        slots: dismissedSlots,
        history: state.history.record(
          slots: dismissedSlots,
          current: state.slots,
        ),
      ),
    );
    await _resolveAndCommit();
  });

  @override
  void dispose() {
    _catalog.removeListener(_sync);
    _prefs.removeListener(revalidate);
    super.dispose();
  }
}
