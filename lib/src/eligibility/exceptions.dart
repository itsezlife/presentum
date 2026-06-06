/// {@template eligibility_exception}
/// Base class for all eligibility exceptions.
/// {@endtemplate}
abstract class EligibilityException implements Exception {
  /// {@macro eligibility_exception}
  const EligibilityException(this.error, [this.message]);

  /// The error object.
  final Object error;

  /// The error message.
  final String? message;

  @override
  String toString() =>
      'EligibilityException: $error${message != null ? ' - $message' : ''}';
}

/// {@template malformed_metadata_exception}
/// Thrown when metadata cannot be parsed into an eligibility condition.
/// {@endtemplate}
final class MalformedMetadataException extends EligibilityException {
  /// {@macro malformed_metadata_exception}
  const MalformedMetadataException(super.error, [super.message]);
}

/// {@template evaluation_exception}
/// Thrown when an eligibility rule evaluation fails unexpectedly.
/// {@endtemplate}
final class EvaluationException extends EligibilityException {
  /// {@macro evaluation_exception}
  const EvaluationException(super.error, [super.message]);
}
