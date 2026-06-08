import 'package:control/control.dart';
import 'package:example/src/common/model/dependencies.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';
import 'package:example/src/updates/controller/updates_controller.dart';
import 'package:example/src/updates/controller/updates_state.dart';
import 'package:example/src/updates/widgets/updates_snackbar_host.dart';
import 'package:flutter/material.dart';

class AppUpdatesPresentum extends StatefulWidget {
  const AppUpdatesPresentum({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdatesPresentum> createState() => _AppUpdatesPresentumState();
}

class _AppUpdatesPresentumState extends State<AppUpdatesPresentum> {
  late final UpdatesController _controller;

  @override
  void initState() {
    super.initState();
    final deps = Dependencies.of(context);
    _controller = UpdatesController(
      storage: PersistentPresentumStorage(prefs: deps.sharedPreferences),
      updatesStore: deps.shorebirdUpdatesStore,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ControllerScope.value(
    _controller,
    child: ValueListenableBuilder<UpdatesSlots>(
      valueListenable: _controller.select((s) => s.slots),
      builder: (context, slots, child) =>
          UpdatesSnackbarHost(slots: slots, child: child!),
      child: widget.child,
    ),
  );
}
