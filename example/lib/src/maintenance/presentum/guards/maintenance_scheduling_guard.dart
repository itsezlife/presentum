import 'package:example/src/common/presentum/eligibility_scheduling_guard.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:shared/shared.dart';

/// {@template maintenance_scheduling_guard}
/// This guard extends the [IEligibilitySchedulingGuard] to filter maintenance
/// items based on eligibility and adds them as active.
///
/// - See [IEligibilitySchedulingGuard] for more details.
/// {@endtemplate}
final class MaintenanceSchedulingGuard
    extends
        IEligibilitySchedulingGuard<MaintenanceItem, AppSurface, AppVariant> {
  /// {@macro maintenance_scheduling_guard}
  MaintenanceSchedulingGuard({required super.eligibilityResolver});
}
