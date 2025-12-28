import 'dart:async';

import 'package:example/src/app/router/routes.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

class MaintenanceModeGuard extends OctopusGuard {
  MaintenanceModeGuard({
    required this.maintenanceStateObserver,
    required this.eligibilityResolver,
  }) : super(refresh: maintenanceStateObserver);

  final PresentumStateObserver<MaintenanceItem, AppSurface, AppVariant>
  maintenanceStateObserver;
  final EligibilityResolver<MaintenanceItem> eligibilityResolver;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) async {
    final maintenanceState = maintenanceStateObserver.value;
    final maintenanceSlot = maintenanceState.slots[AppSurface.maintenanceView];
    if (maintenanceSlot?.active case final item?) {
      final isEligible = await eligibilityResolver.isEligible(item, context);
      if (isEligible) {
        context['maintenance_mode'] = true;
        return state
          ..clear()
          ..putIfAbsent(
            Routes.maintenance.name,
            () => Routes.maintenance.node()..extra = {'item': item},
          );
      }
    }
    context['maintenance_mode'] = false;
    return state;
  }
}
