import 'package:example/src/maintenance/presentum/inherited_provider.dart';
import 'package:example/src/maintenance/presentum/maintenance_transition_observer.dart'
    show MaintenanceTransitionObserver;
import 'package:example/src/maintenance/presentum/presentum_state_mixin.dart';
import 'package:flutter/material.dart';

/// {@template maintenance_presentum}
/// MaintenancePresentum widget that initializes the maintenance presentum
/// and wraps the child widget with the [MaintenanceProviderScope].
///
/// The [MaintenanceTransitionObserver] is registered when creating the
/// Presentum instance (see [MaintaincePresentumStateMixin]) to handle
/// app update checks based on maintenance mode state changes.
/// {@endtemplate}
class MaintenancePresentum extends StatefulWidget {
  const MaintenancePresentum({required this.child, super.key});

  final Widget child;

  @override
  State<MaintenancePresentum> createState() => _MaintenancePresentumState();
}

class _MaintenancePresentumState extends State<MaintenancePresentum>
    with MaintaincePresentumStateMixin {
  @override
  Widget build(BuildContext context) =>
      maintenancePresentum.config.engine.build(
        context,
        MaintenanceProviderScope(provider: provider, child: widget.child),
      );
}
