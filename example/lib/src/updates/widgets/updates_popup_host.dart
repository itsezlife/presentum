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
        PresentumActiveSurfaceItemObserverMixin<
          AppUpdatesItem,
          AppSurface,
          AppVariant,
          AppUpdatesPopupHost
        > {
  late final UpdateSnackbar _updateSnackbar;

  @override
  void initState() {
    _updateSnackbar = UpdateSnackbar();
    super.initState();
  }

  @override
  AppSurface get surface => AppSurface.updateSnackbar;

  @override
  void onActiveItemChanged({
    required AppUpdatesItem? current,
    required AppUpdatesItem? previous,
  }) {
    if (current case final _? when previous == null) {
      _updateSnackbar.show(context);
    }
    if (previous case final _? when current == null) {
      _updateSnackbar.hide();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
