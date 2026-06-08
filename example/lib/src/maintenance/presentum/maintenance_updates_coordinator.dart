import 'dart:async';
import 'dart:developer' as dev;

import 'package:example/src/updates/data/updates_store.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Progressive Shorebird update checks after maintenance mode ends.
final class MaintenanceUpdatesCoordinator {
  MaintenanceUpdatesCoordinator({required this.updatesStore});

  final ShorebirdUpdatesStore updatesStore;

  Timer? _updatesCheckTimer;
  int _checkInterval = 5;

  void onMaintenanceEnded() {
    dev.log(
      'Maintenance mode ended - initiating update checks',
      name: 'MaintenanceUpdatesCoordinator',
    );
    _startUpdateChecks();
  }

  void onMaintenanceStarted() {
    dev.log(
      'Maintenance mode active - cancelling update checks',
      name: 'MaintenanceUpdatesCoordinator',
    );
    _stopUpdateChecks();
  }

  void _startUpdateChecks() {
    updatesStore.checkForUpdate();
    _scheduleProgressiveUpdateCheck();
  }

  void _stopUpdateChecks() {
    _updatesCheckTimer?.cancel();
    _checkInterval = 5;
  }

  void _scheduleProgressiveUpdateCheck() {
    _updatesCheckTimer?.cancel();

    _updatesCheckTimer = Timer(Duration(seconds: _checkInterval), () async {
      final status = updatesStore.status;

      switch (status) {
        case UpdateStatus.unavailable:
          _updatesCheckTimer?.cancel();
          return;
        case UpdateStatus.upToDate:
          await updatesStore.checkForUpdate();
        case UpdateStatus.outdated:
          break;
        case UpdateStatus.restartRequired:
          _updatesCheckTimer?.cancel();
          return;
        case null:
          break;
      }

      _checkInterval = (_checkInterval * 2).clamp(5, 60);
      _scheduleProgressiveUpdateCheck();
    });
  }

  void dispose() {
    _updatesCheckTimer?.cancel();
  }
}
