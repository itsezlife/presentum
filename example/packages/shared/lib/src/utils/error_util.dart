import 'dart:async';
import 'dart:developer' as dev;

import 'package:shared/src/utils/platform/error_util_vm.dart'
    if (dart.library.io) 'package:shared/src/utils/platform/error_util_js.dart';

/// Error util.
abstract final class ErrorUtil {
  /// Log the error to the console and to Crashlytics.
  static Future<void> logError(
    Object exception,
    StackTrace stackTrace, {
    String? hint,
    bool fatal = false,
  }) async {
    try {
      if (exception is String) {
        return await logMessage(
          exception,
          stackTrace: stackTrace,
          hint: hint,
          warning: true,
        );
      }
      $captureException(exception, stackTrace, hint, fatal).ignore();
      dev.log('Error', error: exception, stackTrace: stackTrace, level: 1000);
    } on Object catch (error, stackTrace) {
      dev.log(
        'Error while logging error "$error" inside ErrorUtil.logError',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Logs a message to the console and to Crashlytics.
  static Future<void> logMessage(
    String message, {
    StackTrace? stackTrace,
    String? hint,
    bool warning = false,
  }) async {
    try {
      dev.log(
        message,
        stackTrace: stackTrace ?? StackTrace.current,
        level: 1000,
      );
      $captureMessage(message, stackTrace, hint, warning).ignore();
    } on Object catch (error, stackTrace) {
      dev.log(
        'Error while logging error "$error" inside ErrorUtil.logMessage',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  /// Rethrows the error with the stack trace.
  static Never throwWithStackTrace(Object error, StackTrace stackTrace) =>
      Error.throwWithStackTrace(error, stackTrace);
}
