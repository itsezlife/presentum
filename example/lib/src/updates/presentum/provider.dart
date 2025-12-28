import 'dart:async';

import 'package:example/src/updates/data/updated_store.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Provider that manages app updates and maintenance mode using Shorebird
final class AppUpdatesProvider extends ChangeNotifier {
  AppUpdatesProvider({required this.engine, required this.updatesStore}) {
    _initialize();
  }

  final PresentumEngine<AppUpdatesItem, AppSurface, AppVariant> engine;
  final ShorebirdUpdatesStore updatesStore;

  late final AppLifecycleListener _lifecycleListener;

  UpdateStatus? _currentStatus;
  Timer? _statusCheckTimer;

  UpdateStatus? get currentStatus => _currentStatus;

  Future<void> _initialize() async {
    // Check for updates when the app is resumed
    _lifecycleListener = AppLifecycleListener(onResume: _checkForUpdates);

    // Check for updates immediately
    await _checkForUpdates();

    // Set up periodic update checks (every 30 minutes in production)
    _statusCheckTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkForUpdates(),
    );

    // Initial candidates setup
    _refreshCandidates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final status = await updatesStore.checkForUpdate();

      if (status == _currentStatus) return;
      _currentStatus = status;

      _refreshCandidates();
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AppUpdatesProvider',
          context: ErrorSummary('Error checking for updates'),
        ),
      );
    }
  }

  void _refreshCandidates() {
    final candidates = <AppUpdatesItem>[];

    // Add update snackbar if restart is required
    if (_currentStatus == UpdateStatus.restartRequired) {
      const updatePayload = AppUpdatesPayload(
        id: 'app_update_required',
        priority: 100, // High priority
        metadata: {'required_update_status': 'restartRequired'},
        options: [
          AppUpdatesOption(
            surface: AppSurface.updateSnackbar,
            variant: AppVariant.snackbar,
            isDismissible: false,
            alwaysOnIfEligible: true,
          ),
        ],
      );

      for (final option in updatePayload.options) {
        candidates.add(AppUpdatesItem(payload: updatePayload, option: option));
      }
    }

    // Add maintenance mode if configured
    // if (_maintenancePayload case final payload?) {
    //   for (final option in payload.options) {
    //     candidates.add(MaintenanceItem(payload: payload, option: option));
    //   }
    // }

    // Update engine with new candidates
    engine.setCandidates((_, _) => candidates);

    notifyListeners();
  }

  /// Force check for updates (can be called manually)
  Future<void> checkForUpdates() => _checkForUpdates();

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }
}
