import 'dart:developer' as dev;

import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Local payloads for the New Year theme and banner features
///
/// Use Firebase Remote Config to manage the payloads and conditions in
/// real-time or else whatever you want: Supabase, Appwrite, local API, etc.
final _payloads = <String, FeaturePayload>{
  FeatureId.newYearTheme: const FeaturePayload(
    id: FeatureId.newYearTheme,
    featureKey: FeatureId.newYearTheme,
    priority: 50,
    metadata: {
      // Any of the following conditions must be met to make this payload visible
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
    options: [
      FeatureOption(
        surface: AppSurface.background,
        variant: AppVariant.snow,
        stage: 0,
        isDismissible: false,
        alwaysOnIfEligible: true,
      ),
    ],
  ),
  FeatureId.newYearBanner: const FeaturePayload(
    id: FeatureId.newYearBanner,
    featureKey: FeatureId.newYearBanner,
    // This payload depends on the new year banner feature being enabled
    dependsOnFeatureKey: FeatureId.newYearBanner,
    priority: 50,
    metadata: {
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
    options: [
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
  ),
};

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

  /// Current list of candidates.
  final List<FeatureItem> _currentCandidates = <FeatureItem>[];

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

    // Track if any changes were made
    var hasChanges = false;

    // Process diff operations
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

    // Only recalculate candidates once after all changes are applied
    if (hasChanges) {
      _recalculateCandidates();
    }
  }

  /// Recalculate all candidates based on current features.
  void _recalculateCandidates() {
    _currentCandidates.clear();

    // 1) Add settings toggles for all current features
    for (final feature in _currentFeatures.values) {
      _currentCandidates.addAll(_createSettingsCandidates(feature));
    }

    // 2) Add payload-driven candidates, checking dependencies
    for (final payload in _payloads.values) {
      // Check if this payload depends on a feature being enabled
      if (payload.dependsOnFeatureKey case final dependsOnFeatureKey?) {
        // If the feature it depends on doesn't exist, skip this payload
        if (!_currentFeatures.containsKey(dependsOnFeatureKey)) {
          dev.log(
            'Skipping payload ${payload.id} because dependent '
            'feature "$dependsOnFeatureKey" is not in current features',
          );
          continue;
        }
      }
      // If dependsOnFeatureKey is null, always include the payload

      // Add all options from this payload
      for (final opt in payload.options) {
        _currentCandidates.add(FeatureItem(payload: payload, option: opt));
      }
    }

    // Update the engine with the new candidates
    engine.setCandidates((_, _) => _currentCandidates);
  }

  /// Create settings toggle candidates for a feature.
  List<FeatureItem> _createSettingsCandidates(FeatureDefinition feature) {
    final candidates = <FeatureItem>[];

    // Settings toggle for this feature
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

    return candidates;
  }

  @override
  void dispose() {
    catalog.removeListener(_sync);
    super.dispose();
  }
}
