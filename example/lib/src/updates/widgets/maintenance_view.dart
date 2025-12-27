import 'dart:async';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/updates/presentum/payload.dart';
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
  Timer? _countdownTimer;
  Duration? _remainingTime;
  bool _maintenanceEnded = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
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
    final item = context
        .presentumItem<MaintenanceItem, AppSurface, AppVariant>();
    final payload = item.payload;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 80,
                  color: context.theme.colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Maintenance Mode',
                  style: context.theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "We're currently performing maintenance to improve your experience.",
                  style: context.theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Show countdown if we have a time window
                if (_remainingTime != null && !_maintenanceEnded) ...[
                  Text(
                    'Estimated time remaining:',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(_remainingTime!),
                      style: context.theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: context.theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Show restart button if maintenance ended and it's enabled
                if (_maintenanceEnded && payload.enableRestartButton) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Maintenance complete!',
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      color: context.theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _restartApp,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restart App'),
                  ),
                ] else if (!_maintenanceEnded) ...[
                  Text(
                    'Please check back soon.',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
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
