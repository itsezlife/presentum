import 'package:flutter/foundation.dart';

/// {@template eligibility}
/// Base class for all eligibility conditions.
///
/// Eligibility conditions are declarative representations of rules that can be
/// evaluated against a context to determine if a subject is eligible.
///
/// Examples:
/// - Time is within a specific range
/// - User belongs to one of the specified segments
/// - A numeric value exceeds a threshold
/// - A string matches a pattern
/// {@endtemplate}
@immutable
abstract class Eligibility {
  /// {@macro eligibility}
  const Eligibility();

  /// Subclasses must override to provide value equality.
  @override
  bool operator ==(Object other);

  /// Subclasses must override to provide consistent hashing.
  @override
  int get hashCode;
}
