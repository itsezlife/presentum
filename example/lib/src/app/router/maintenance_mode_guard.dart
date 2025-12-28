import 'dart:async';

import 'package:collection/collection.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class MaintenanceModeGuard extends OctopusGuard {
  MaintenanceModeGuard({
    required this.maintenanceState,
    required this.initialMaintenanceCandidates,
    required this.eligibilityResolver,
    super.refresh,
  });

  final FutureOr<
    PresentumState$Immutable<MaintenanceItem, AppSurface, AppVariant>
  >
  Function()
  maintenanceState;
  final List<MaintenanceItem> Function() initialMaintenanceCandidates;
  final EligibilityResolver<MaintenanceItem> eligibilityResolver;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    final maintenanceState = await this.maintenanceState();
    final maintenanceItem =
        maintenanceState.slots[AppSurface.maintenanceView]?.active;
    final candidates = initialMaintenanceCandidates();
    final hasMaintenanceMode = candidates.isNotEmpty;
    if (maintenanceItem != null || hasMaintenanceMode) {
      final item =
          maintenanceItem ??
          candidates.firstWhereOrNull(
            (c) => c.surface == AppSurface.maintenanceView,
          );
      if (item == null) return state..removeByName(Routes.maintenance.name);

      final isEligible = await eligibilityResolver.isEligible(item, context);
      if (isEligible) {
        context['maintenance_mode'] = true;
        return state
          ..clear()
          ..putIfAbsent(
            Routes.maintenance.name,
            () => Routes.maintenance.node(),
          );
      }
    }
    context['maintenance_mode'] = false;
    return state..removeByName(Routes.maintenance.name);
  }
}
