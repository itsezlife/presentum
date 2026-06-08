import 'dart:async';

import 'package:collection/collection.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/maintenance/controller/maintenance_state.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/eligibility.dart';
import 'package:shared/shared.dart';

class MaintenanceModeGuard extends OctopusGuard {
  MaintenanceModeGuard({
    required this.slots,
    required this.candidates,
    required this.eligibilityResolver,
    super.refresh,
  });

  final FutureOr<MaintenanceSlots> Function() slots;
  final List<MaintenanceItem> Function() candidates;
  final EligibilityResolver<MaintenanceItem> eligibilityResolver;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    final maintenanceSlots = await slots();
    final maintenanceItem = maintenanceSlots.activeFor(
      AppSurface.maintenanceView,
    );
    final candidateList = candidates();
    final hasMaintenanceMode = candidateList.isNotEmpty;

    if (maintenanceItem != null || hasMaintenanceMode) {
      final item =
          maintenanceItem ??
          candidateList.firstWhereOrNull(
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
