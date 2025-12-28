import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

/// {@template update_snackbar}
/// An undismissible snackbar that informs the user that an app update
/// is available and requires a restart to take effect.
/// {@endtemplate}
class UpdateSnackbar {
  /// {@macro update_snackbar}
  const UpdateSnackbar._();

  /// Shows an undismissible snackbar with a restart button.
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Update available'),
          action: SnackBarAction(
            label: 'RESTART',
            textColor: context.theme.colorScheme.onInverseSurface,
            onPressed: () => _restartApp(context),
          ),
          duration: const Duration(days: 365), // Effectively permanent
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.none, // Prevents swipe to dismiss
        ),
      );
  }

  static Future<void> _restartApp(BuildContext context) async {
    final l10n = context.l10n;

    // Restart the app
    await Restart.restartApp(
      webOrigin: Config.websiteUrl,
      notificationTitle: l10n.restartingApp,
      notificationBody: l10n.restartNotification,
    );

    // Force kill the process to ensure Shorebird patch loads
    if (!kIsWeb) {
      exit(0);
    }
  }
}
