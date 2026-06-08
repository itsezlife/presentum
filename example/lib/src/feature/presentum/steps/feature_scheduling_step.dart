import 'package:example/src/feature/controller/feature_state.dart';
import 'package:example/src/feature/data/feature_catalog_store.dart';
import 'package:example/src/feature/data/feature_store.dart';
import 'package:example/src/feature/presentum/payload.dart';
import 'package:presentum/eligibility.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Full rebuild of feature slots from filtered candidates.
final class FeatureSchedulingStep
    implements PresentumResolverStep<FeatureItem, AppSurface, AppVariant> {
  const FeatureSchedulingStep({
    required this.catalog,
    required this.prefs,
    required this.eligibilityResolver,
  });

  final FeatureCatalogStore catalog;
  final FeaturePreferencesStore prefs;
  final EligibilityResolver<FeatureItem> eligibilityResolver;

  bool _enabled(String key) =>
      prefs.overrideFor(key) ?? (catalog.features[key]?.defaultEnabled ?? true);

  @override
  Future<FeatureSlots> call(
    PresentumStepInput<FeatureItem, AppSurface, AppVariant> input,
  ) async {
    final filtered = <FeatureItem>[];

    for (final item in input.candidates) {
      final key = item.payload.featureKey;
      final isDependentFeature = item.payload.dependsOnFeatureKey != null;

      if (isDependentFeature && !catalog.exists(key)) continue;

      if (!_enabled(key) && !item.id.startsWith('settings_toggle:')) {
        continue;
      }

      final isEligible = await eligibilityResolver.isEligible(
        item,
        input.context,
      );
      if (!isEligible) continue;

      final dismissedAt = await input.storage.getDismissedAt(
        item.id,
        surface: item.surface,
        variant: item.variant,
      );
      if (dismissedAt != null) continue;

      filtered.add(item);
    }

    var slots =
        const PresentumSlotState<FeatureItem, AppSurface, AppVariant>.empty();
    final bySurface = <AppSurface, List<FeatureItem>>{};
    for (final item in filtered) {
      (bySurface[item.surface] ??= <FeatureItem>[]).add(item);
    }

    for (final entry in bySurface.entries) {
      final surface = entry.key;
      final items = entry.value;

      int stageOf(FeatureItem i) => i.stage ?? 0;

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

      slots = slots.withActive(surface, items.first);
      if (items.length > 1) {
        slots = slots.withReorderedQueue(surface, items.sublist(1));
      }
    }

    return slots;
  }
}
