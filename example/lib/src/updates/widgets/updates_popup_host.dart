import 'package:example/src/updates/presentum/payload.dart';
import 'package:example/src/updates/widgets/update_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Popup host for app update snackbars
class AppUpdatesPopupHost extends StatefulWidget {
  const AppUpdatesPopupHost({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdatesPopupHost> createState() => _AppUpdatesPopupHostState();
}

class _AppUpdatesPopupHostState extends State<AppUpdatesPopupHost>
    with
        PresentumPopupSurfaceStateMixin<
          AppUpdatesItem,
          AppSurface,
          AppVariant,
          AppUpdatesPopupHost
        > {
  @override
  AppSurface get surface => AppSurface.updateSnackbar;

  @override
  PopupConflictStrategy get conflictStrategy => PopupConflictStrategy.replace;

  @override
  bool get ignoreDuplicates => true;

  @override
  Duration? get duplicateThreshold => const Duration(seconds: 10);

  @override
  Future<void> markDismissed({required AppUpdatesItem entry}) async {
    final presentum = context
        .presentum<AppUpdatesItem, AppSurface, AppVariant>();
    await presentum.markDismissed(entry);
  }

  @override
  Future<PopupPresentResult> present(AppUpdatesItem entry) async {
    if (!mounted) return PopupPresentResult.notPresented;

    final presentum = context
        .presentum<AppUpdatesItem, AppSurface, AppVariant>();

    // Mark as shown
    await presentum.markShown(entry);

    if (!mounted) return PopupPresentResult.notPresented;

    // Show the update snackbar
    UpdateSnackbar.show(context);

    // Snackbars are persistent until user action, so we return userDismissed
    // The snackbar will stay visible until restart
    return PopupPresentResult.userDismissed;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
