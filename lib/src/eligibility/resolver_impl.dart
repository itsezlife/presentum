import 'package:flutter/foundation.dart';
import 'package:presentum/src/eligibility/eligibility.dart';
import 'package:presentum/src/eligibility/exceptions.dart';
import 'package:presentum/src/eligibility/resolver.dart';

@internal
final class EligibilityResolver$Impl<S> implements EligibilityResolver<S> {
  const EligibilityResolver$Impl({
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
    context['_subject'] = subject;

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
        orElse: () => Error.throwWithStackTrace(
          EvaluationException(
            'No rule found for eligibility type: ${condition.runtimeType}',
          ),
          StackTrace.current,
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
