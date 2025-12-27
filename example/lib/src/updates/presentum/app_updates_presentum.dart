import 'package:example/src/updates/presentum/presentum_state_mixin.dart';
import 'package:example/src/updates/widgets/updates_popup_host.dart';
import 'package:flutter/material.dart';

/// Main widget that provides app updates and maintenance mode functionality
/// using Presentum.
class AppUpdatesPresentum extends StatefulWidget {
  const AppUpdatesPresentum({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdatesPresentum> createState() => _AppUpdatesPresentumState();
}

class _AppUpdatesPresentumState extends State<AppUpdatesPresentum>
    with AppUpdatesPresentumStateMixin {
  @override
  Widget build(BuildContext context) => appUpdatesPresentum.config.engine.build(
    context,
    AppUpdatesPopupHost(child: widget.child),
  );
}
