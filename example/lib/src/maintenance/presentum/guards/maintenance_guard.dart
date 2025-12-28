import 'dart:async';

import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Guard that filters maintenance items based on eligibility
final class MaintenanceGuard
    extends PresentumGuard<MaintenanceItem, AppSurface, AppVariant> {
  MaintenanceGuard({required this.eligibilityResolver});

  final EligibilityResolver<MaintenanceItem> eligibilityResolver;

  @override
  Future<PresentumState<MaintenanceItem, AppSurface, AppVariant>> call(
    PresentumStorage<AppSurface, AppVariant> storage,
    List<PresentumHistoryEntry<MaintenanceItem, AppSurface, AppVariant>>
    history,
    PresentumState$Mutable<MaintenanceItem, AppSurface, AppVariant> state,
    List<MaintenanceItem> candidates,
    Map<String, Object?> context,
  ) async {
    final filtered = <MaintenanceItem>[];

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
