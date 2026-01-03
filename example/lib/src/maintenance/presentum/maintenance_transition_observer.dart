import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/updates/data/updates_store.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// {@template maintenance_transition_observer}
/// Transition observer that watches for maintenance mode changes and
/// automatically handles app updates when maintenance ends.
///
/// **How it works:**
///
/// During maintenance mode:
/// - Stops checking for updates to avoid interrupting the maintenance flow
///
/// After maintenance mode ends:
/// - Immediately starts checking for app updates using a progressive timer
/// - Timer starts at 5 seconds and doubles each check (5s → 10s → 20s → 40s → 60s max)
/// - This prevents overwhelming the update service while staying responsive
///
/// **Update workflow:**
///
/// 1. When maintenance surface is deactivated, this observer schedules update checks
/// 2. The AppUpdatesProvider listens to updates store status changes
/// 3. If status is outdated, provider automatically executes the update
/// 4. Provider resolves the next status and updates candidates continuously
/// 5. When restart is required, provider shows a snackbar via AppUpdatesPopupHost
/// 6. The snackbar prompts user to restart the app to complete the update
///
/// This creates a seamless flow from maintenance mode to app updates without
/// requiring app restart or manual intervention.
/// {@endtemplate}
class MaintenanceTransitionObserver
    implements
        IPresentumTransitionObserver<MaintenanceItem, AppSurface, AppVariant> {
  /// Creates a maintenance transition observer.
  MaintenanceTransitionObserver(this.updatesStore);

  /// The Shorebird updates store for checking and managing app updates.
  final ShorebirdUpdatesStore updatesStore;

  Timer? _updatesCheckTimer;
  int _checkInterval = 5; // Start with 5 seconds

  @override
  void call(
    PresentumStateTransition<MaintenanceItem, AppSurface, AppVariant>
    transition,
  ) {
    final diff = transition.diff;

    // Check if maintenance surface was deactivated
    final maintenanceDeactivated = diff.itemsDeactivated.any(
      (change) => change.surface == AppSurface.maintenanceView,
    );

    if (maintenanceDeactivated) {
      dev.log(
        'Maintenance mode ended - initiating update checks',
        name: 'MaintenanceTransitionObserver',
      );
      _startUpdateChecks();
      return;
    }

    // Check if maintenance surface was activated
    final maintenanceActivated = diff.itemsActivated.any(
      (change) => change.surface == AppSurface.maintenanceView,
    );

    if (maintenanceActivated) {
      dev.log(
        'Maintenance mode active - cancelling update checks',
        name: 'MaintenanceTransitionObserver',
      );
      _stopUpdateChecks();
    }
  }

  /// Starts checking for app updates immediately and schedules progressive checks.
  void _startUpdateChecks() {
    updatesStore.checkForUpdate();
    _scheduleProgressiveUpdateCheck();
  }

  /// Stops all update checks and resets the check interval.
  void _stopUpdateChecks() {
    _updatesCheckTimer?.cancel();
    _checkInterval = 5; // Reset interval
  }

  /// Schedules a progressive update check timer that gradually increases
  /// the interval between checks.
  ///
  /// Starts at 5s, increases to 10s, 20s, etc., capping at 60 seconds.
  /// Handles different update statuses appropriately.
  void _scheduleProgressiveUpdateCheck() {
    _updatesCheckTimer?.cancel();

    _updatesCheckTimer = Timer(Duration(seconds: _checkInterval), () async {
      // Check current update status
      final status = updatesStore.status;

      switch (status) {
        case UpdateStatus.unavailable:
          _updatesCheckTimer?.cancel();
          dev.log(
            'Update check cancelled - updates are unavailable',
            name: 'MaintenanceTransitionObserver',
          );
          return;

        case UpdateStatus.upToDate:
          // Check for new updates when app is up to date
          dev.log(
            'Checking for updates (interval: ${_checkInterval}s)',
            name: 'MaintenanceTransitionObserver',
          );
          await updatesStore.checkForUpdate();

        case UpdateStatus.outdated:
          // Update is available but not downloaded yet - continue checking
          dev.log(
            'Update available but not downloaded - continuing checks',
            name: 'MaintenanceTransitionObserver',
          );

        case UpdateStatus.restartRequired:
          // Update is downloaded and ready - no need to check further
          dev.log(
            'Update ready for restart - stopping checks',
            name: 'MaintenanceTransitionObserver',
          );
          _updatesCheckTimer?.cancel();
          return;
        case null:
          dev.log(
            'Update status is null - continuing checks',
            name: 'MaintenanceTransitionObserver',
          );
      }

      // Increase interval progressively: 5s → 10s → 20s → 40s → 60s (cap)
      _checkInterval = (_checkInterval * 2).clamp(5, 60);

      // Schedule next check
      _scheduleProgressiveUpdateCheck();
    });
  }

  /// Dispose resources when no longer needed.
  void dispose() {
    _updatesCheckTimer?.cancel();
  }
}
