import 'dart:async';

import 'package:example/src/updates/data/updates_store.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:flutter/cupertino.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Provider that manages app updates and maintenance mode using Shorebird
final class AppUpdatesProvider extends ChangeNotifier {
  AppUpdatesProvider({required this.engine, required this.updatesStore}) {
    // Check for updates when the app is resumed
    _lifecycleListener = AppLifecycleListener(onResume: _onUpdatesStoreChanged);
    // Listen for updates store changes
    updatesStore.addListener(_onUpdatesStoreChanged);
    // Initial check for updates
    _onUpdatesStoreChanged();
  }

  final PresentumEngine<AppUpdatesItem, AppSurface, AppVariant> engine;
  final ShorebirdUpdatesStore updatesStore;

  late final AppLifecycleListener _lifecycleListener;

  UpdateStatus? _currentStatus;
  void _onUpdatesStoreChanged() {
    final status = updatesStore.status;
    if (status == UpdateStatus.outdated) {
      updatesStore.update();
    }
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final status = await updatesStore.checkForUpdate();

      if (status == _currentStatus) return;
      _currentStatus = status;

      if (status == UpdateStatus.outdated) {
        await updatesStore.update();
      }

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

    // Update engine with new candidates
    engine.setCandidates((_, _) => candidates);

    notifyListeners();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    updatesStore.removeListener(_onUpdatesStoreChanged);
    super.dispose();
  }
}
