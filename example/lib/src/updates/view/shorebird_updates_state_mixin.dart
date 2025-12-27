import 'dart:developer' as dev;
import 'dart:io';

import 'package:example/src/common/constant/config.dart';
import 'package:example/src/updates/widget/update_required_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// {@template shorebird_updates_state_mixin}
/// A mixin that manages and displays updates for the app using Shorebird.
/// {@endtemplate}
mixin ShorebirdUpdatesStateMixin<T extends StatefulWidget> on State<T> {
  // Create an instance of the updater class
  final updater = ShorebirdUpdater();

  /// Whether the update snackbar is currently showing.
  bool _isShowingUpdateSnackbar = false;

  @override
  void initState() {
    super.initState();

    checkForUpdates();
  }

  Future<void> checkForUpdates() async {
    // Check whether a new update is available.
    final status = await updater.checkForUpdate();

    if (!mounted) return;

    switch (status) {
      case UpdateStatus.outdated:
        // Download the update in the background
        try {
          await updater.update();

          // After downloading, check the status again
          if (!mounted) return;
          final newStatus = await updater.checkForUpdate();

          if (newStatus == UpdateStatus.restartRequired) {
            _showUpdateSnackbar();
          }
        } on UpdateException catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'ShorebirdUpdatesStateMixin',
              context: ErrorSummary('Error downloading Shorebird update'),
            ),
          );
        }

      case UpdateStatus.restartRequired:
        // Show the restart snackbar immediately
        _showUpdateSnackbar();

      case UpdateStatus.upToDate:
        dev.log('App is up to date');

      case UpdateStatus.unavailable:
        dev.log('Shorebird updates are unavailable in this build');
    }
  }

  void _showUpdateSnackbar() {
    if (_isShowingUpdateSnackbar) return;
    _isShowingUpdateSnackbar = true;

    UpdateRequiredSnackbar.show(
      context,
      onRestart: () async {
        // Restart the app
        await Restart.restartApp(
          webOrigin: Config.websiteUrl,

          // Customizing the restart notification message (only needed on iOS)
          notificationTitle: 'Restarting App',
          notificationBody: 'Please tap here to open the app again.',
        );

        if (!kIsWeb) {
          exit(0);
        }
      },
    );
  }
}
