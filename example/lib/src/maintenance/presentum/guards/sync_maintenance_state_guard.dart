import 'package:example/src/common/presentum/sync_state_with_candidates_guard.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:shared/shared.dart';

/// {@template sync_maintenance_state_guard}
/// This guard keeps the maintenance state in sync with the latest candidates.
///
/// - See [ISyncStateWithCandidatesGuard] for more details.
/// {@endtemplate}
final class SyncMaintenanceStateGuard
    extends
        ISyncStateWithCandidatesGuard<MaintenanceItem, AppSurface, AppVariant> {
  /// {@macro sync_maintenance_state_guard}
  SyncMaintenanceStateGuard({super.refresh});
}
