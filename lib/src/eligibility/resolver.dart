import 'package:presentum/src/eligibility/eligibility.dart';
import 'package:presentum/src/eligibility/resolver_impl.dart';
import 'package:presentum/src/eligibility/rules.dart';

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
  ///
  /// The [rules] parameter is optional. If not provided, [createStandardRules]
  /// will be called to create a standard set of rules.
  ///
  /// Throws [EvaluationException] if evaluation cannot complete, or
  /// [MalformedMetadataException] if extraction fails.
  factory EligibilityResolver({
    required List<EligibilityExtractor<S>> extractors,
    List<EligibilityRule>? rules,
  }) {
    // Caller-provided rules take precedence over the built-in defaults.
    final $rules = [...?rules, ...createStandardRules()];
    return EligibilityResolver$Impl<S>(rules: $rules, extractors: extractors);
  }

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
