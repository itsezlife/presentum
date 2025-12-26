import 'dart:developer' as dev;

import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class FeatureDrivenProvider extends ChangeNotifier {
  FeatureDrivenProvider({
    required this.engine,
    required this.catalog,
    required this.prefs,
  }) {
    catalog.addListener(_sync);
    // Initial sync so the Settings list is immediately populated.
    Future.microtask(_sync);
  }

  final PresentumEngine<FeatureItem, AppSurface, AppVariant> engine;
  final FeatureCatalogStore catalog;
  final FeaturePreferencesStore prefs;

  /// Current list of feature definitions.
  final Map<String, FeatureDefinition> _currentFeatures =
      <String, FeatureDefinition>{};

  Future<void> _sync() async {
    // If features were removed upstream, prune user overrides too.
    await prefs.pruneTo(catalog.features.keys.toSet());

    final newFeatures = Map<String, FeatureDefinition>.from(catalog.features);

    // Diff the new features against stored features.
    await _diffAndUpdateFeatures(newFeatures);

    notifyListeners();
  }

  /// Diff new features against stored features and update accordingly.
  Future<void> _diffAndUpdateFeatures(
    Map<String, FeatureDefinition> newFeatures,
  ) async {
    final oldFeatures = Map<String, FeatureDefinition>.from(_currentFeatures);
    final oldFeatureList = List<FeatureDefinition>.from(oldFeatures.values);
    final newFeatureList = List<FeatureDefinition>.from(newFeatures.values);

    // Calculate diff operations
    final diffOps = DiffUtils.calculateListDiffOperations<FeatureDefinition>(
      oldFeatureList,
      newFeatureList,
      (feature) => feature.key,
      detectMoves: false,
      customContentsComparison: (oldFeature, newFeature) {
        // Compare feature properties to detect content changes
        if (oldFeature.key != newFeature.key) return false;
        if (oldFeature.defaultEnabled != newFeature.defaultEnabled) {
          return false;
        }
        if (oldFeature.order != newFeature.order) return false;
        return true;
      },
    );

    dev.log('diffOps: $diffOps');

    // Process diff operations
    for (final insertion in diffOps.insertions) {
      final features = newFeatureList.sublist(
        insertion.position,
        insertion.position + insertion.count,
      );
      final candidates = <FeatureItem>[...engine.currentCandidates];
      for (final feature in features) {
        _currentFeatures[feature.key] = feature;
        candidates.addAll(_addFeature(feature));
      }
      engine.setCandidatesWithDiff((state) => candidates);
    }

    for (final removal in diffOps.removals) {
      final candidates = <FeatureItem>[];
      for (var i = 0; i < removal.count; i++) {
        final feature = oldFeatureList[removal.position + i];
        _currentFeatures.remove(feature.key);
        candidates.addAll(_removeFeature(feature));
      }
      engine.setCandidatesWithDiff((state) => candidates);
    }

    for (final change in diffOps.changes) {
      final updatedFeature = change.payload as FeatureDefinition?;
      if (updatedFeature case final feature?) {
        _currentFeatures[feature.key] = feature;
        final currentCandidates = [...engine.currentCandidates];
        final newCandidates = <FeatureItem>[];

        // Remove old candidates for this feature
        for (final candidate in currentCandidates) {
          if (candidate.payload.featureKey != feature.key) {
            newCandidates.add(candidate);
          }
        }

        // Add updated candidates for this feature
        newCandidates.addAll(_addFeature(feature));

        engine.setCandidatesWithDiff((state) => newCandidates);
      }
    }

    diffOps.clear();
  }

  /// Add a new feature to the engine.
  List<FeatureItem> _addFeature(FeatureDefinition feature) {
    final candidates = <FeatureItem>[];

    // 1) Settings toggle for this feature
    final settingsPayload = FeaturePayload(
      id: 'settings_toggle:${feature.key}',
      featureKey: feature.key,
      priority: 0,
      options: const [
        FeatureOption(
          surface: AppSurface.settingsToggles,
          variant: AppVariant.settingToggleRow,
          isDismissible: false,
          stage: null, // stage comes from catalog order (below)
          alwaysOnIfEligible: true,
        ),
      ],
    );

    for (final opt in settingsPayload.options) {
      // Use option.stage for ordering (Settings ordering is catalog-driven).
      final orderedOpt = FeatureOption(
        surface: opt.surface,
        variant: opt.variant,
        isDismissible: opt.isDismissible,
        stage: feature.order,
        maxImpressions: opt.maxImpressions,
        cooldownMinutes: opt.cooldownMinutes,
        alwaysOnIfEligible: opt.alwaysOnIfEligible,
      );

      candidates.add(FeatureItem(payload: settingsPayload, option: orderedOpt));
    }

    // 2) Special case: New Year Theme banner
    if (feature.key == FeatureId.newYearTheme) {
      final bannerPayload = FeaturePayload(
        id: FeatureId.newYearTheme,
        featureKey: feature.key,
        priority: 50,
        metadata: const {
          // Any of the following conditions must be met to active this payload
          'any_of': [
            // Scheduling window (UTC ISO)
            {
              'time_range': {
                'start': '2025-12-01T18:00:00Z',
                'end': '2026-01-03T23:59:59Z',
              },
            },
            // Explicitly enable the feature
            {'is_active': true},
          ],
        },
        options: const [
          FeatureOption(
            surface: AppSurface.background,
            variant: AppVariant.snow,
            stage: 0,
            isDismissible: false,
            alwaysOnIfEligible: true,
          ),
        ],
      );

      for (final opt in bannerPayload.options) {
        candidates.add(FeatureItem(payload: bannerPayload, option: opt));
      }
    }

    // 3) Special case: New Year Theme banner
    if (feature.key == FeatureId.newYearBanner) {
      final bannerPayload = FeaturePayload(
        id: FeatureId.newYearBanner,
        featureKey: feature.key,
        priority: 50,
        metadata: const {
          'year': '2026',
          // Any of the following conditions must be met to show the banner
          'any_of': [
            // Scheduling window (UTC ISO) from 31st December 2025 to 3rd January 2026
            {
              'time_range': {
                'start': '2025-12-31T18:00:00Z',
                'end': '2026-01-03T23:59:59Z',
              },
            },
            // Explicitly enable the feature
            {'is_active': true},
          ],
        },
        options: const [
          FeatureOption(
            surface: AppSurface.popup,
            variant: AppVariant.fullscreenDialog,
            isDismissible: true,
            stage: 0,
            maxImpressions: 1,
            alwaysOnIfEligible: false,
          ),
          FeatureOption(
            surface: AppSurface.homeHeader,
            variant: AppVariant.banner,
            isDismissible: true,
            alwaysOnIfEligible: true,
          ),
        ],
      );

      for (final opt in bannerPayload.options) {
        candidates.add(FeatureItem(payload: bannerPayload, option: opt));
      }
    }

    return candidates;
  }

  /// Remove a feature from the engine.
  List<FeatureItem> _removeFeature(FeatureDefinition feature) {
    final currentCandidates = engine.currentCandidates;
    return currentCandidates
        .where((item) => item.payload.featureKey != feature.key)
        .toList();
  }

  @override
  void dispose() {
    catalog.removeListener(_sync);
    super.dispose();
  }
}
