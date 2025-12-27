import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template update_required_snackbar}
/// An undismissible snackbar that informs the user that an app update
/// is available and requires a restart to take effect.
/// {@endtemplate}
class UpdateRequiredSnackbar {
  /// {@macro update_required_snackbar}
  const UpdateRequiredSnackbar._();

  /// Shows an undismissible snackbar with a restart button.
  static void show(BuildContext context, {required VoidCallback onRestart}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Update available'),
          action: SnackBarAction(
            label: 'RESTART',
            textColor: context.theme.colorScheme.onInverseSurface,
            onPressed: onRestart,
          ),
          duration: const Duration(days: 365), // Effectively permanent
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.none, // Prevents swipe to dismiss
        ),
      );
}
