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

    // Process diff operations
    for (final insertion in diffOps.insertions) {
      final feature = newFeatureList[insertion.position];
      _currentFeatures[feature.key] = feature;
      await _addFeature(feature);
    }

    for (final removal in diffOps.removals) {
      final feature = oldFeatureList[removal.position];
      _currentFeatures.remove(feature.key);
      await _removeFeature(feature);
    }

    for (final change in diffOps.changes) {
      final newFeature = change.payload as FeatureDefinition?;
      if (newFeature != null) {
        _currentFeatures[newFeature.key] = newFeature;
        await _updateFeature(newFeature);
      }
    }

    diffOps.clear();
  }

  /// Add a new feature to the engine.
  Future<void> _addFeature(FeatureDefinition feature) async {
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
    if (feature.key == FeatureId.newYear) {
      final bannerPayload = FeaturePayload(
        id: FeatureId.newYear,
        featureKey: feature.key,
        priority: 50,
        metadata: {
          'year': '2026',
          // Any of the following conditions must be met to show the banner
          'any_of': [
            // Scheduling window (UTC ISO)
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
            surface: AppSurface.homeHeader,
            variant: AppVariant.banner,
            isDismissible: true,
            alwaysOnIfEligible: true,
          ),
          FeatureOption(
            surface: AppSurface.popup,
            variant: AppVariant.fullscreenDialog,
            isDismissible: true,
            stage: 0,
            maxImpressions: 1,
            cooldownMinutes: 24 * 60,
            alwaysOnIfEligible: false,
          ),
        ],
      );

      for (final opt in bannerPayload.options) {
        candidates.add(FeatureItem(payload: bannerPayload, option: opt));
      }
    }

    await engine.setCandidatesWithDiff((state) => candidates);
  }

  /// Remove a feature from the engine.
  Future<void> _removeFeature(FeatureDefinition feature) async {
    // Remove all candidates related to this feature
    engine.setCandidates((state, currentCandidates) {
      return currentCandidates
          .where((item) => item.payload.featureKey != feature.key)
          .toList();
    });
  }

  /// Update an existing feature in the engine.
  Future<void> _updateFeature(FeatureDefinition feature) async {
    // For updates, we remove and re-add to ensure all properties are updated
    await _removeFeature(feature);
    await _addFeature(feature);
  }

  @override
  void dispose() {
    catalog.removeListener(_sync);
    super.dispose();
  }
}
