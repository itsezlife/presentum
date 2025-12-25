import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class FeatureSchedulingGuard
    extends PresentumGuard<FeatureItem, AppSurface, AppVariant> {
  FeatureSchedulingGuard({
    required this.catalog,
    required this.prefs,
    required this.eligibilityResolver,
  }) : super(refresh: Listenable.merge([catalog, prefs]));

  final FeatureCatalogStore catalog;
  final FeaturePreferencesStore prefs;
  final EligibilityResolver<FeatureItem> eligibilityResolver;

  bool _enabled(String key) =>
      (prefs.overrideFor(key) ??
      (catalog.features[key]?.defaultEnabled ?? true));

  @override
  Future<PresentumState<FeatureItem, AppSurface, AppVariant>> call(
    storage,
    history,
    PresentumState$Mutable<FeatureItem, AppSurface, AppVariant> state,
    List<FeatureItem> candidates,
    context,
  ) async {
    // 1) Filter: if feature is gone, disabled, ineligible, or dismissed,
    // exclude it from UI.
    final filtered = <FeatureItem>[];
    final eligibilityContext = _buildEligibilityContext(context);

    for (final item in candidates) {
      final key = item.payload.featureKey;

      // Check if feature exists in catalog
      if (!catalog.exists(key)) continue;

      // Check if feature is enabled (except settings toggles)
      if (!_enabled(key) && !item.id.startsWith('settings_toggle:')) {
        continue;
      }

      // Check eligibility (time ranges, segments, etc.)
      final isEligible = await eligibilityResolver.isEligible(
        item,
        eligibilityContext,
      );
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

  /// Builds the eligibility evaluation context.
  ///
  /// This context is passed to the eligibility resolver to evaluate conditions
  /// like time ranges, user segments, etc.
  Map<String, dynamic> _buildEligibilityContext(
    Map<String, dynamic> guardContext,
  ) {
    return {
      'now': DateTime.now(),
      'catalog': catalog,
      'prefs': prefs,
      ...guardContext,
    };
  }
}
