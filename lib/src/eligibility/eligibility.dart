import 'package:flutter/foundation.dart';
import 'package:presentum/src/eligibility/resolver_impl.dart';

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

/// {@template eligibility_rule}
/// Evaluates a specific type of [Eligibility] against a runtime context.
///
/// Rules are stateless, reusable predicates. They should only depend on:
/// 1. The eligibility condition itself
/// 2. The runtime context
///
/// Type parameter [T] is the specific eligibility type this rule handles.
/// {@endtemplate}
abstract class EligibilityRule<T extends Eligibility> {
  /// {@macro eligibility_rule}
  const EligibilityRule();

  /// Returns true if this rule can evaluate the given [eligibility].
  bool supports(Eligibility eligibility) => eligibility is T;

  /// Evaluates the [eligibility] condition against the [context].
  ///
  /// Returns `true` if the condition is satisfied (subject remains eligible).
  /// Returns `false` if the condition fails (subject is ineligible).
  ///
  /// May throw [EvaluationException] if evaluation cannot complete.
  Future<bool> evaluate(T eligibility, Map<String, dynamic> context);
}

/// {@template eligibility_extractor}
/// Extracts structured [Eligibility] conditions from a subject.
///
/// Extractors are responsible for parsing/deserializing data (e.g., metadata,
/// configuration) into typed eligibility conditions.
///
/// Type parameter [S] is the subject type (e.g., a campaign, feature flag,
/// user).
/// {@endtemplate}
abstract interface class EligibilityExtractor<S> {
  /// {@macro eligibility_extractor}
  const EligibilityExtractor();

  /// Returns true if this extractor can process the given [subject].
  bool supports(S subject);

  /// Extracts zero or more eligibility conditions from the [subject].
  ///
  /// May throw [MalformedMetadataException] if data is invalid.
  Iterable<Eligibility> extract(S subject);
}

/// {@template eligibility_resolver}
/// Resolves whether a subject is eligible based on extracted conditions.
/// {@endtemplate}
abstract interface class EligibilityResolver<S> {
  /// {@macro eligibility_resolver}
  const factory EligibilityResolver({
    required List<EligibilityRule> rules,
    required List<EligibilityExtractor<S>> extractors,
  }) = EligibilityResolver$Impl<S>;

  /// Returns the first [Eligibility] condition that fails, or `null` if all
  /// pass.
  Future<Eligibility?> getIneligibleCondition(
    S subject,
    Map<String, dynamic> context,
  );

  /// Returns `true` if all eligibility conditions pass for the [subject].
  Future<bool> isEligible(S subject, Map<String, dynamic> context) =>
      getIneligibleCondition(subject, context).then((c) => c == null);
}
