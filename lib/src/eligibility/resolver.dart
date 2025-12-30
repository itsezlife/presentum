import 'package:flutter/foundation.dart';

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

/// Evaluates a specific type of [Eligibility] against a runtime context.
///
/// Rules are stateless, reusable predicates. They should only depend on:
/// 1. The eligibility condition itself
/// 2. The runtime context
///
/// Type parameter [T] is the specific eligibility type this rule handles.
abstract interface class EligibilityRule<T extends Eligibility> {
  const EligibilityRule();

  /// Returns true if this rule can evaluate the given [eligibility].
  bool supports(Eligibility eligibility);

  /// Evaluates the [eligibility] condition against the [context].
  ///
  /// Returns `true` if the condition is satisfied (subject remains eligible).
  /// Returns `false` if the condition fails (subject is ineligible).
  ///
  /// May throw [EvaluationException] if evaluation cannot complete.
  Future<bool> evaluate(T eligibility, Map<String, dynamic> context);
}

/// Extracts structured [Eligibility] conditions from a subject.
///
/// Extractors are responsible for parsing/deserializing data (e.g., metadata,
/// configuration) into typed eligibility conditions.
///
/// Type parameter [S] is the subject type (e.g., a campaign, feature flag,
/// user).
abstract interface class EligibilityExtractor<S> {
  const EligibilityExtractor();

  /// Returns true if this extractor can process the given [subject].
  bool supports(S subject);

  /// Extracts zero or more eligibility conditions from the [subject].
  ///
  /// May throw [MalformedMetadataException] if data is invalid.
  Iterable<Eligibility> extract(S subject);
}

/// Resolves whether a subject is eligible based on extracted conditions.
abstract interface class EligibilityResolver<S> {
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

/// Default implementation of [EligibilityResolver].
final class DefaultEligibilityResolver<S> implements EligibilityResolver<S> {
  /// {@macro default_eligibility_resolver}
  const DefaultEligibilityResolver({
    required List<EligibilityRule> rules,
    required List<EligibilityExtractor<S>> extractors,
  }) : _rules = rules,
       _extractors = extractors;

  final List<EligibilityRule> _rules;
  final List<EligibilityExtractor<S>> _extractors;

  @override
  Future<Eligibility?> getIneligibleCondition(
    S subject,
    Map<String, dynamic> context,
  ) async {
    // Extract all eligibility conditions from the subject
    final conditions = <Eligibility>[];
    for (final extractor in _extractors) {
      if (extractor.supports(subject)) {
        conditions.addAll(extractor.extract(subject));
      }
    }

    // No conditions extracted => considered eligible by default
    if (conditions.isEmpty) return null;

    // Evaluate each condition
    for (final condition in conditions) {
      // Find a rule that supports this condition
      final rule = _rules.firstWhere(
        (r) => r.supports(condition),
        orElse: () => throw EvaluationException(
          'No rule found for eligibility type: ${condition.runtimeType}',
        ),
      );

      // Evaluate the condition
      // We use a type-unsafe cast here because rules use covariant generics.
      // The rule.supports() check ensures type safety at runtime.
      final isEligible = await _evaluateUnsafe(rule, condition, context);
      if (!isEligible) return condition;
    }

    return null;
  }

  @override
  Future<bool> isEligible(S subject, Map<String, dynamic> context) =>
      getIneligibleCondition(subject, context).then((c) => c == null);

  /// Type-unsafe evaluation helper.
  /// This is safe because we've already verified support via rule.supports().
  Future<bool> _evaluateUnsafe(
    EligibilityRule rule,
    Eligibility condition,
    Map<String, dynamic> context,
    // ignore: prefer_expression_function_bodies
  ) {
    // Dart doesn't allow us to express the relationship between the rule's
    // generic type and the condition type statically, so we use dynamic.
    return rule.evaluate(condition, context);
  }
}
