import 'dart:async';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:example/src/maintenance/presentum/payload.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:presentum/presentum.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared/shared.dart';

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
    _startCountdown();

    _onStateChange();

    _observer.addListener(_onStateChange);
  }

  void _onStateChange() {
    final state = _observer.value;
    final item = state.slots[AppSurface.maintenanceView]?.active;
    if (item?.payload.options.any(
          (e) => e.variant == AppVariant.maintenanceScreenRestartButton,
        ) ??
        false) {
      _showRestartButton = true;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _showRestartButton = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _startCountdown() {
    final item = context
        .presentumItem<MaintenanceItem, AppSurface, AppVariant>();
    final payload = item.payload;

    // Calculate initial remaining time
    _remainingTime = payload.timeUntilEnd;
    _maintenanceEnded = _remainingTime == Duration.zero;

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final newRemaining = payload.timeUntilEnd;
        _remainingTime = newRemaining;

        // Check if maintenance ended
        if (newRemaining == Duration.zero && !_maintenanceEnded) {
          _maintenanceEnded = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _restartApp() async {
    await Restart.restartApp(
      webOrigin: Config.websiteUrl,
      notificationTitle: 'Restarting App',
      notificationBody: 'Please tap here to open the app again.',
    );

    if (!kIsWeb) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: ScaffoldPadding.of(
              context,
              horizontalPadding: AppSpacing.xlg,
            ).copyWith(top: AppSpacing.xlg, bottom: AppSpacing.xlg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 80, color: colorScheme.primary),
                const SizedBox(height: AppSpacing.xxlg),
                Text(
                  'Maintenance Mode',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  "We're currently performing maintenance to improve your experience.",
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxlg),

                // Show countdown if we have a time window
                if (_remainingTime case final remainingTime?
                    when !_maintenanceEnded) ...[
                  Text(
                    'Estimated time remaining:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xlg,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(remainingTime),
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: AppFontWeight.bold,
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
                    'Maintenance complete!',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _restartApp,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart App'),
                  ),
                ] else if (!_maintenanceEnded) ...[
                  Text(
                    'Please check back soon.',
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
