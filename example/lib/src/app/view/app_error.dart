import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template app_error}
/// AppError widget
/// {@endtemplate}
class AppError extends StatelessWidget {
  /// {@macro app_error}
  const AppError({this.error, super.key});

  /// Error
  final Object? error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'App Error',
    theme:
        View.of(context).platformDispatcher.platformBrightness ==
            Brightness.dark
        ? const AppTheme().theme
        : const AppDarkTheme().theme,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              // ErrorUtil.formatMessage(error)
              error?.toString() ?? 'Something went wrong',
              textScaler: TextScaler.noScaling,
            ),
          ),
        ),
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: child!,
    ),
  );
}
