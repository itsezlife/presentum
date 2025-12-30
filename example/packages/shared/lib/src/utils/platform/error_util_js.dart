// ignore_for_file: avoid_positional_boolean_parameters

/// Capture an exception.
Future<void> $captureException(
  Object exception,
  StackTrace stackTrace,
  String? hint,
  bool fatal,
) => Future<void>.value();

/// Capture a message.
Future<void> $captureMessage(
  String message,
  StackTrace? stackTrace,
  String? hint,
  bool warning,
) => Future<void>.value();
