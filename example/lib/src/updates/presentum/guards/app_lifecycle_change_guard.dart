import 'dart:async';

import 'package:example/src/updates/presentum/payload.dart';
import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';
import 'package:shared/shared.dart';

final class AppLifecycleChangedGuard
    extends PresentumGuard<AppUpdatesItem, AppSurface, AppVariant> {
  AppLifecycleChangedGuard({super.refresh});
}

/// Refresh listener for app lifecycle changes.
class AppLifecycleChangedRefresh extends ChangeNotifier {
  AppLifecycleChangedRefresh() {
    _listener = AppLifecycleListener(
      onStateChange: (state) {
        switch (state) {
          case AppLifecycleState.resumed:
            _scheduleNotification();
          case AppLifecycleState.inactive:
          case AppLifecycleState.paused:
          case AppLifecycleState.detached:
          case AppLifecycleState.hidden:
            _cancelTimer();
        }
      },
    );
  }

  late final AppLifecycleListener _listener;
  Timer? _timer;

  void _scheduleNotification() {
    _cancelTimer();
    _timer = Timer(const Duration(seconds: 3), notifyListeners);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    _listener.dispose();
    super.dispose();
  }
}
