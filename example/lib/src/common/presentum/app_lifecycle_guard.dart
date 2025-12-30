import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:presentum/presentum.dart';

/// {@template app_lifecycle_guard}
/// This guard runs when the app comes back to the foreground after being
/// in the background. It's useful for checking things like app updates,
/// maintenance windows, or other time-sensitive content that might have
/// changed while the user was away.
///
/// The guard doesn't do anything by itself - it just provides a base class
/// that you can extend to add your own logic. You'll typically want to
/// override the call method to implement whatever checks you need.
///
/// Works together with AppLifecycleRefresh which listens for app state
/// changes and triggers the guard when the app becomes active again.
/// There's a small delay (3 seconds by default) before triggering to
/// avoid running checks too frequently if the user quickly switches
/// between apps.
/// {@endtemplate}
class AppLifecycleGuard<
  TItem extends PresentumItem<PresentumPayload<S, V>, S, V>,
  S extends PresentumSurface,
  V extends PresentumVisualVariant
>
    extends PresentumGuard<TItem, S, V> {
  /// {@macro app_lifecycle_guard}
  AppLifecycleGuard({super.refresh});
}

/// Refresh listener for app lifecycle changes.
class AppLifecycleRefresh extends ChangeNotifier {
  AppLifecycleRefresh({this.notificationDelay = _defaultNotificationDelay}) {
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

  final Duration notificationDelay;

  static const _defaultNotificationDelay = Duration(seconds: 3);

  late final AppLifecycleListener _listener;
  Timer? _timer;

  void _scheduleNotification() {
    _cancelTimer();
    _timer = Timer(notificationDelay, notifyListeners);
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
