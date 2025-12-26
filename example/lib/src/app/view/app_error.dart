import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/widgets/scaffold_padding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// {@template app_error}
/// AppError widget
/// {@endtemplate}
class AppError extends StatelessWidget {
  /// {@macro app_error}
  const AppError({this.error, this.stackTrace, super.key});

  /// Error
  final Object? error;

  /// Stack trace
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return MaterialApp(
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
              padding: ScaffoldPadding.of(
                context,
              ).copyWith(top: AppSpacing.lg, bottom: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // ErrorUtil.formatMessage(error)
                    error?.toString() ?? 'Something went wrong',
                    textScaler: TextScaler.noScaling,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (stackTrace case final stackTrace?) ...[
                    Stack(
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              stackTrace.toString(),
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: AppSpacing.md,
                          top: AppSpacing.md,
                          child: IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: stackTrace.toString()),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to the clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Copy to the clipboard',
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            context.textScaleFactor(maxTextScaleFactor: 1.5),
          ),
        ),
        child: child!,
      ),
    );
  }
}
