import 'package:example/src/maintenance/presentum/presentum_state_mixin.dart';
import 'package:flutter/material.dart';

/// {@template maintenance_presentum}
/// MaintenancePresentum widget that initializes the maintenance presentum
/// and wraps the child widget with the [InheritedPresentum] widget.
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
      maintenancePresentum.config.engine.build(context, widget.child);
}
