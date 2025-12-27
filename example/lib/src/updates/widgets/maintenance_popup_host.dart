import 'package:example/src/app/router/routes.dart';
import 'package:example/src/updates/presentum/payload.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Popup host for maintenance mode screen
class MaintenancePopupHost extends StatefulWidget {
  const MaintenancePopupHost({required this.child, super.key});

  final Widget child;

  @override
  State<MaintenancePopupHost> createState() => _MaintenancePopupHostState();
}

class _MaintenancePopupHostState extends State<MaintenancePopupHost>
    with
        PresentumPopupSurfaceStateMixin<
          MaintenanceItem,
          AppSurface,
          AppVariant,
          MaintenancePopupHost
        > {
  @override
  AppSurface get surface => AppSurface.maintenanceView;

  @override
  PopupConflictStrategy get conflictStrategy => PopupConflictStrategy.replace;

  @override
  bool get ignoreDuplicates => false;

  @override
  Future<void> markDismissed({required MaintenanceItem entry}) async {
    final presentum = context
        .presentum<MaintenanceItem, AppSurface, AppVariant>();
    await presentum.markDismissed(entry);
  }

  @override
  Future<PopupPresentResult> present(MaintenanceItem entry) async {
    if (!mounted) return PopupPresentResult.notPresented;

    final presentum = context
        .presentum<MaintenanceItem, AppSurface, AppVariant>();

    // Mark as shown
    await presentum.markShown(entry);

    if (!mounted) return PopupPresentResult.notPresented;

    await context.octopus.setState(
      (state) => state
        ..clear()
        ..putIfAbsent(Routes.maintenance.name, () => Routes.maintenance.node()),
    );

    // If user dismissed it (shouldn't happen as it's blocking), mark as system dismissed
    return PopupPresentResult.notPresented;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
