import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/app/router/routes.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/common/widgets/app_constrained_scroll_view.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:presentum/presentum.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared/shared.dart';
import 'package:slide_countdown/slide_countdown.dart';

/// Maintenance mode screen that shows countdown and optional restart button
class MaintenanceView extends StatefulWidget {
  const MaintenanceView({super.key});

  @override
  State<MaintenanceView> createState() => _MaintenanceViewState();
}

class _MaintenanceViewState extends State<MaintenanceView> {
  late final PresentumStateObserver<MaintenanceItem, AppSurface, AppVariant>
  _observer;

  Timer? _countdownTimer;
  Duration? _remainingTime;
  bool _maintenanceEnded = false;
  bool _showRestartButton = false;

  @override
  void initState() {
    super.initState();
    _observer = context
        .presentum<MaintenanceItem, AppSurface, AppVariant>()
        .observer;
    _onStateChange();

    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final state = _observer.value;
    final item = state.slots[AppSurface.maintenanceView]?.active;
    if (item == null) return;

    _startCountdown(item);
  }

  void _startCountdown(MaintenanceItem item) {
    final payload = item.payload;

    final showRestartButton = item.payload.options.any(
      (e) => e.variant == AppVariant.maintenanceScreenRestartButton,
    );
    _showRestartButton = showRestartButton;

    // Calculate initial remaining time
    _remainingTime = payload.timeUntilEnd;
    final isActive = payload.isActive;

    final hasValidRemainingTime =
        _remainingTime != null && _remainingTime!.inSeconds > 0;
    _maintenanceEnded = isActive == false && hasValidRemainingTime;

    if (mounted) {
      setState(() {});
    }

    if (!hasValidRemainingTime) return;

    _countdownTimer?.cancel();

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final newRemaining = payload.timeUntilEnd;
        _remainingTime = newRemaining;

        final hasMaintenanceEnded =
            newRemaining != null && newRemaining <= Duration.zero;
        _maintenanceEnded = hasMaintenanceEnded;
        dev.log(
          'hasMaintenanceEnded: $hasMaintenanceEnded, newRemaining: $newRemaining',
        );
      });

      if (_remainingTime == null || _maintenanceEnded) {
        timer.cancel();
        return;
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _restartApp() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      await context.octopus.setState(
        (state) => state..removeByName(Routes.maintenance.name),
      );
      return;
    }

    try {
      final l10n = context.l10n;
      await Restart.restartApp(
        webOrigin: Config.websiteUrl,
        notificationTitle: l10n.restartingApp,
        notificationBody: l10n.restartNotification,
      );

      if (!kIsWeb) {
        exit(0);
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'MaintenanceView',
          context: ErrorSummary('Restarting app'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: AppConstrainedScrollView(
          padding: ScaffoldPadding.of(
            context,
            horizontalPadding: AppSpacing.xlg,
          ).copyWith(top: AppSpacing.xlg, bottom: AppSpacing.xlg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 80, color: colorScheme.primary),
                const SizedBox(height: AppSpacing.xxlg),
                Text(
                  l10n.maintenanceTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.maintenanceDescription,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxlg),

                // Show countdown if we have a time window
                if (_remainingTime case final remainingTime?
                    when !_maintenanceEnded &&
                        remainingTime >= Duration.zero) ...[
                  Text(
                    l10n.maintenanceEstimatedTimeRemaining,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    child: SlideCountdownSeparated(
                      duration: remainingTime,
                      separator: ':',
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      separatorType: SeparatorType.title,
                      separatorStyle: textTheme.titleMedium!.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                      style: textTheme.headlineMedium!.copyWith(
                        height: 1,
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxlg),
                ],

                // Show restart button if maintenance ended and it's enabled
                if (_maintenanceEnded && _showRestartButton) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.maintenanceComplete,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _restartApp,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l10n.maintenanceRestartApp),
                  ),
                ] else if (!_maintenanceEnded) ...[
                  Text(
                    l10n.maintenancePleaseCheckBack,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
