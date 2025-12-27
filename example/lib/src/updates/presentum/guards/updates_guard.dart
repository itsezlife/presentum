import 'dart:async';

import 'package:example/src/updates/data/updated_store.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Guard that filters update items based on eligibility
final class AppUpdatesGuard
    extends PresentumGuard<AppUpdatesItem, AppSurface, AppVariant> {
  AppUpdatesGuard({
    required this.eligibilityResolver,
    required this.updatesStore,
  }) : super(refresh: updatesStore);

  final ShorebirdUpdatesStore updatesStore;
  final EligibilityResolver<AppUpdatesItem> eligibilityResolver;

  @override
  Future<PresentumState<AppUpdatesItem, AppSurface, AppVariant>> call(
    PresentumStorage<AppSurface, AppVariant> storage,
    List<PresentumHistoryEntry<AppUpdatesItem, AppSurface, AppVariant>> history,
    PresentumState$Mutable<AppUpdatesItem, AppSurface, AppVariant> state,
    List<AppUpdatesItem> candidates,
    Map<String, Object?> context,
  ) async {
    context['update_status'] = updatesStore.status;
    final filtered = <AppUpdatesItem>[];

    for (final item in candidates) {
      // Check eligibility
      final isEligible = await eligibilityResolver.isEligible(item, context);
      if (!isEligible) continue;

      filtered.add(item);
    }

    // Set active items for their respective surfaces
    for (final item in filtered) {
      state.setActive(item.surface, item);
    }

    return state;
  }
}
