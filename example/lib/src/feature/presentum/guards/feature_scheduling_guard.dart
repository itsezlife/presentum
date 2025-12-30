import 'package:example/src/common/presentum/remove_ineligible_candidates_guard.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// {@template feature_scheduling_guard}
/// This guard rebuilds the entire feature state from scratch by filtering
/// candidates and repopulating all slots. It clears existing state and
/// rebuilds based on current feature catalog, preferences, and eligibility.
///
/// This approach differs from incremental guards (like [RemoveIneligibleCandidatesGuard])
/// that preserve existing state structure and only remove ineligible items.
///
/// This guard is useful when:
/// - You need complete state rebuilds based on external data changes
/// - Feature catalog or preferences have changed significantly
/// - You want deterministic ordering and fresh state on each evaluation
/// - The cost of full rebuild is acceptable for your use case
///
/// Performance consideration: This does full eligibility checks on all
/// candidates and rebuilds all slots from scratch, which can be more expensive
/// than incremental updates but ensures consistency with current data sources.
/// {@endtemplate}
final class FeatureSchedulingGuard
    extends PresentumGuard<FeatureItem, AppSurface, AppVariant> {
  /// {@macro feature_scheduling_guard}
  FeatureSchedulingGuard({
    required this.catalog,
    required this.prefs,
    required this.eligibilityResolver,
  }) : super(refresh: Listenable.merge([catalog, prefs]));

  final FeatureCatalogStore catalog;
  final FeaturePreferencesStore prefs;
  final EligibilityResolver<FeatureItem> eligibilityResolver;

  bool _enabled(String key) =>
      prefs.overrideFor(key) ?? (catalog.features[key]?.defaultEnabled ?? true);

  @override
  Future<PresentumState<FeatureItem, AppSurface, AppVariant>> call(
    PresentumStorage<AppSurface, AppVariant> storage,
    List<PresentumHistoryEntry<FeatureItem, AppSurface, AppVariant>> history,
    PresentumState$Mutable<FeatureItem, AppSurface, AppVariant> state,
    List<FeatureItem> candidates,
    Map<String, Object?> context,
  ) async {
    // 1) Filter: if feature is gone, disabled, ineligible, or dismissed,
    // exclude it from UI.
    final filtered = <FeatureItem>[];

    for (final item in candidates) {
      final key = item.payload.featureKey;

      final isDependentFeature = item.payload.dependsOnFeatureKey != null;

      /// Only check against catalog if the feature is dependent
      ///
      /// Meaning if the dependsOnFeatureKey is null and payload in the
      /// provider exists, even when the feature does not in the exists,
      /// the payload will be shown only if eligible AND enabled.
      if (isDependentFeature) {
        // Check if feature exists in catalog
        if (!catalog.exists(key)) continue;
      }

      // Check if feature is enabled (except settings toggles)
      if (!_enabled(key) && !item.id.startsWith('settings_toggle:')) {
        continue;
      }

      // Check eligibility (time ranges, segments, etc.)
      final isEligible = await eligibilityResolver.isEligible(item, context);
      if (!isEligible) continue;

      // Check if feature is dismissed
      final dismissedAt = await storage.getDismissedAt(
        item.id,
        surface: item.surface,
        variant: item.variant,
      );
      if (dismissedAt != null) continue;

      filtered.add(item);
    }

    // 3) Project candidates -> slots (active + queue)
    // This is what makes Settings rows and UI banners actually appear.
    state.clearAll();

    final bySurface = <AppSurface, List<FeatureItem>>{};
    for (final item in filtered) {
      (bySurface[item.surface] ??= <FeatureItem>[]).add(item);
    }

    for (final entry in bySurface.entries) {
      final surface = entry.key;
      final items = entry.value;

      int stageOf(FeatureItem i) => i.stage ?? 0;

      // Deterministic ordering (localization-safe):
      // - primary: option.stage (catalog order)
      // - tie-breaker: stable feature key (not localized title)
      if (surface == AppSurface.settingsToggles) {
        items.sort((a, b) {
          final stageCmp = stageOf(a).compareTo(stageOf(b));
          if (stageCmp != 0) return stageCmp;
          return a.payload.featureKey.compareTo(b.payload.featureKey);
        });
      } else {
        items.sort((a, b) {
          final stageCmp = stageOf(a).compareTo(stageOf(b));
          if (stageCmp != 0) return stageCmp;
          return b.priority.compareTo(a.priority);
        });
      }

      state.addAll(surface, items);
    }

    return state;
  }
}
