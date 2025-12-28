import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:example/src/updates/data/updates_store.dart';
import 'package:example/src/updates/presentum/provider.dart';
import 'package:example/src/updates/widgets/updates_popup_host.dart' show AppUpdatesPopupHost;
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// {@template maintenance_surface_observer}
/// This observer watches for maintenance mode changes and automatically handles
/// app updates when maintenance ends.
///
/// Here's how it works:
///
/// During maintenance mode:
/// - Stops checking for updates to avoid interrupting the maintenance flow
///
/// After maintenance mode ends:
/// - Immediately starts checking for app updates using a progressive timer
/// - Timer starts at 5 seconds and doubles each check (5s -> 10s -> 20s -> 40s -> 60s max)
/// - This prevents overwhelming the update service while staying responsive
///
/// The update workflow is fully continuous within the same app runtime:
/// 1. When maintenance surface is removed, this observer schedules update checks
/// 2. The [AppUpdatesProvider] listens to updates store status changes
/// 3. If status is outdated, provider automatically executes the update
/// 4. Provider resolves the next status and updates candidates continuously
/// 5. When restart is required, provider shows a snackbar via [AppUpdatesPopupHost]
/// 6. The snackbar prompts user to restart the app to complete the update
///
/// This creates a seamless flow from maintenance mode to app updates without
/// requiring app restart or manual intervention.
///
/// If the user instead clicks on "Restart app" button, the app will shutdown,
/// exiting current app runtime. On next app startup the default updates
/// workflow will be active, not being dependent on the maintenance presentum.
/// {@endtemplate}
class MaintenanceSurfaceObserver extends StatefulWidget {
  const MaintenanceSurfaceObserver({required this.child, super.key});

  final Widget child;

  @override
  State<MaintenanceSurfaceObserver> createState() =>
      _MaintenanceSurfaceObserverState();
}

class _MaintenanceSurfaceObserverState extends State<MaintenanceSurfaceObserver>
    with
        PresentumActiveSurfaceItemObserverMixin<
          MaintenanceItem,
          AppSurface,
          AppVariant,
          MaintenanceSurfaceObserver
        > {
  late final Dependencies _deps;
  late final ShorebirdUpdatesStore _updatesStore;

  Timer? _updatesCheckTimer;
  int _checkInterval = 5; // Start with 5 seconds

  @override
  void initState() {
    super.initState();
    _deps = Dependencies.of(context);

    _updatesStore = _deps.shorebirdUpdatesStore;
  }

  @override
  void dispose() {
    _updatesCheckTimer?.cancel();
    super.dispose();
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
      final status = _updatesStore.status;

      switch (status) {
        case UpdateStatus.unavailable:
          _updatesCheckTimer?.cancel();
          dev.log(
            'Update check cancelled - updates are unavailable',
            name: 'MaintenanceSurfaceObserver',
          );
          return;

        case UpdateStatus.upToDate:
          // Check for new updates when app is up to date
          dev.log(
            'Checking for updates (interval: ${_checkInterval}s)',
            name: 'MaintenanceSurfaceObserver',
          );
          await _updatesStore.checkForUpdate();

        case UpdateStatus.outdated:
          // Update is available but not downloaded yet - continue checking
          dev.log(
            'Update available but not downloaded - continuing checks',
            name: 'MaintenanceSurfaceObserver',
          );

        case UpdateStatus.restartRequired:
          // Update is downloaded and ready - no need to check further
          dev.log(
            'Update ready for restart - stopping checks',
            name: 'MaintenanceSurfaceObserver',
          );
          _updatesCheckTimer?.cancel();
          return;
        case null:
          dev.log(
            'Update status is null - continuing checks',
            name: 'MaintenanceSurfaceObserver',
          );
      }

      // Increase interval progressively: 5s -> 10s -> 20s -> 40s -> 60s (cap)
      _checkInterval = (_checkInterval * 2).clamp(5, 60);

      // Schedule next check if still mounted
      if (mounted) {
        _scheduleProgressiveUpdateCheck();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void onActiveItemChanged({
    required MaintenanceItem? current,
    required MaintenanceItem? previous,
  }) {
    // When maintenance mode was active and became inactive, check for app
    // app updates immediately and start progressive checking.
    if (previous case final _? when current == null) {
      dev.log(
        'Maintenance mode ended - initiating update checks',
        name: 'MaintenanceSurfaceObserver',
      );
      _updatesStore.checkForUpdate();
      _scheduleProgressiveUpdateCheck();
      return;
    }

    // When maintenance mode becomes active, cancel update checks
    if (current case final _? when previous == null) {
      dev.log(
        'Maintenance mode active - cancelling update checks',
        name: 'MaintenanceSurfaceObserver',
      );
      _updatesCheckTimer?.cancel();
      _checkInterval = 5; // Reset interval
    }
  }

  @override
  PresentumSurface get surface => AppSurface.maintenanceView;
}
