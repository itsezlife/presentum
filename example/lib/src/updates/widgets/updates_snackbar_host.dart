import 'package:example/src/updates/presentum/payload.dart';
import 'package:example/src/updates/widgets/update_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

/// Shows/hides the update snackbar based on [slots] active item.
class UpdatesSnackbarHost extends StatefulWidget {
  const UpdatesSnackbarHost({
    required this.slots,
    required this.child,
    super.key,
  });

  final PresentumSlotState<AppUpdatesItem, AppSurface, AppVariant> slots;
  final Widget child;

  @override
  State<UpdatesSnackbarHost> createState() => _UpdatesSnackbarHostState();
}

class _UpdatesSnackbarHostState extends State<UpdatesSnackbarHost> {
  late final UpdateSnackbar _updateSnackbar;
  AppUpdatesItem? _trackedActive;

  @override
  void initState() {
    super.initState();
    _updateSnackbar = UpdateSnackbar();
    _trackedActive = widget.slots.activeFor(AppSurface.updateSnackbar);
    _syncSnackbar(previous: null, current: _trackedActive);
  }

  @override
  void didUpdateWidget(UpdatesSnackbarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots == oldWidget.slots) return;

    final previous = _trackedActive;
    final current = widget.slots.activeFor(AppSurface.updateSnackbar);
    if (previous?.id == current?.id) return;

    _trackedActive = current;
    _syncSnackbar(previous: previous, current: current);
  }

  void _syncSnackbar({
    required AppUpdatesItem? previous,
    required AppUpdatesItem? current,
  }) {
    if (current != null && previous == null) {
      _updateSnackbar.show(context);
    }
    if (previous != null && current == null) {
      _updateSnackbar.hide();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
