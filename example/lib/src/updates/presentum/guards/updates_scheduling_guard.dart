import 'dart:async';

import 'package:example/src/common/presentum/eligibility_scheduling_guard.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// {@template app_updates_guard}
/// This guard uses [IEligibilitySchedulingGuard] to filter update items based on
/// eligibility and evaluates the value of the update status and passes it down
/// to the context, that will be used by the [eligibilityResolver] resolver to
/// determine if the update is eligible.
/// {@endtemplate}
final class AppUpdatesGuard
    extends
        IEligibilitySchedulingGuard<AppUpdatesItem, AppSurface, AppVariant> {
  /// {@macro app_updates_guard}
  AppUpdatesGuard({
    required super.eligibilityResolver,
    required this.getUpdateStatus,
    super.refresh,
  });

  /// Get the current update status.
  final FutureOr<UpdateStatus?> Function() getUpdateStatus;

  @override
  Future<PresentumState<AppUpdatesItem, AppSurface, AppVariant>> call(
    PresentumStorage<AppSurface, AppVariant> storage,
    List<PresentumHistoryEntry<AppUpdatesItem, AppSurface, AppVariant>> history,
    PresentumState$Mutable<AppUpdatesItem, AppSurface, AppVariant> state,
    List<AppUpdatesItem> candidates,
    Map<String, Object?> context,
  ) async {
    /// Evaluates the value of the update status and passed it down to the
    /// context, that can be used by the [eligibility] resolver and by
    /// other guards.
    context['update_status'] = await getUpdateStatus();

    return super.call(storage, history, state, candidates, context);
  }
}
