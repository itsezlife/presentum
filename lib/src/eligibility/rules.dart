import 'dart:developer' as dev;

import 'package:presentum/src/eligibility/conditions.dart';
import 'package:presentum/src/eligibility/resolver.dart';

/// Evaluates [TimeRangeEligibility] conditions.
///
/// Checks if the current UTC time falls within [start, end).
final class TimeRangeRule implements EligibilityRule<TimeRangeEligibility> {
  /// {@macro time_range_rule}
  const TimeRangeRule({this.timeProvider});

  /// Optional custom time provider (useful for testing).
  /// Defaults to DateTime.now().toUtc().
  final DateTime Function()? timeProvider;

  @override
  bool supports(Eligibility eligibility) => eligibility is TimeRangeEligibility;

  @override
  Future<bool> evaluate(
    TimeRangeEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final now = (timeProvider ?? () => DateTime.now().toUtc())();
    final start = eligibility.start.toUtc();
    final end = eligibility.end.toUtc();

    // Inclusive start, exclusive end
    final isEligible = !now.isBefore(start) && now.isBefore(end);

    dev.log(
      'TimeRange: now=$now, range=[$start, $end), eligible=$isEligible',
      name: 'TimeRangeRule',
    );

    return isEligible;
  }
}

/// Evaluates [SetMembershipEligibility] conditions.
///
/// Checks if a value from context is present in the allowed set.
final class SetMembershipRule
    implements EligibilityRule<SetMembershipEligibility> {
  /// {@macro set_membership_rule}
  const SetMembershipRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is SetMembershipEligibility;

  @override
  Future<bool> evaluate(
    SetMembershipEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final value = context[eligibility.contextKey];

    if (value == null) {
      dev.log(
        'SetMembership: key="${eligibility.contextKey}" not found in context',
        name: 'SetMembershipRule',
      );
      return false;
    }

    final isEligible = eligibility.allowedValues.contains(value.toString());

    dev.log(
      'SetMembership: key="${eligibility.contextKey}", '
      'value="$value", allowed=${eligibility.allowedValues}, '
      'eligible=$isEligible',
      name: 'SetMembershipRule',
    );

    return isEligible;
  }
}

/// Evaluates [AnySegmentEligibility] conditions.
///
/// Checks if user segments (from context) overlap with required segments.
final class AnySegmentRule implements EligibilityRule<AnySegmentEligibility> {
  /// {@macro any_segment_rule}
  const AnySegmentRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is AnySegmentEligibility;

  @override
  Future<bool> evaluate(
    AnySegmentEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final rawSegments = context[eligibility.contextKey];

    Set<String> userSegments;
    if (rawSegments is Set<String>) {
      userSegments = rawSegments;
    } else if (rawSegments is List) {
      userSegments = rawSegments.whereType<String>().toSet();
    } else {
      dev.log(
        'AnySegment: key="${eligibility.contextKey}" is not a Set or List',
        name: 'AnySegmentRule',
      );
      return false;
    }

    final isEligible = eligibility.requiredSegments.any(userSegments.contains);

    dev.log(
      'AnySegment: userSegments=$userSegments, '
      'required=${eligibility.requiredSegments}, eligible=$isEligible',
      name: 'AnySegmentRule',
    );

    return isEligible;
  }
}

/// Evaluates [BooleanFlagEligibility] conditions.
///
/// Checks if a boolean flag in context matches the required value.
final class BooleanFlagRule implements EligibilityRule<BooleanFlagEligibility> {
  /// {@macro boolean_flag_rule}
  const BooleanFlagRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is BooleanFlagEligibility;

  @override
  Future<bool> evaluate(
    BooleanFlagEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final value = context[eligibility.contextKey];

    if (value is! bool) {
      dev.log(
        'BooleanFlag: key="${eligibility.contextKey}" is not a bool '
        '(got: ${value.runtimeType})',
        name: 'BooleanFlagRule',
      );
      return false;
    }

    final isEligible = value == eligibility.requiredValue;

    dev.log(
      'BooleanFlag: key="${eligibility.contextKey}", '
      'value=$value, required=${eligibility.requiredValue}, '
      'eligible=$isEligible',
      name: 'BooleanFlagRule',
    );

    return isEligible;
  }
}

/// Evaluates [NumericComparisonEligibility] conditions.
///
/// Compares a numeric value from context against a threshold.
final class NumericComparisonRule
    implements EligibilityRule<NumericComparisonEligibility> {
  /// {@macro numeric_comparison_rule}
  const NumericComparisonRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is NumericComparisonEligibility;

  @override
  Future<bool> evaluate(
    NumericComparisonEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final value = context[eligibility.contextKey];

    if (value is! num) {
      dev.log(
        'NumericComparison: key="${eligibility.contextKey}" is not a num '
        '(got: ${value.runtimeType})',
        name: 'NumericComparisonRule',
      );
      return false;
    }

    final isEligible = eligibility.comparison.compare(
      value,
      eligibility.threshold,
    );

    dev.log(
      'NumericComparison: key="${eligibility.contextKey}", '
      'value=$value ${eligibility.comparison} ${eligibility.threshold}, '
      'eligible=$isEligible',
      name: 'NumericComparisonRule',
    );

    return isEligible;
  }
}

/// Evaluates [StringMatchEligibility] conditions.
///
/// Checks if a string value from context matches a regex pattern.
final class StringMatchRule implements EligibilityRule<StringMatchEligibility> {
  /// {@macro string_match_rule}
  const StringMatchRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is StringMatchEligibility;

  @override
  Future<bool> evaluate(
    StringMatchEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final value = context[eligibility.contextKey];

    if (value == null) {
      dev.log(
        'StringMatch: key="${eligibility.contextKey}" not found in context',
        name: 'StringMatchRule',
      );
      return false;
    }

    final stringValue = value.toString();
    final regex = RegExp(
      eligibility.pattern,
      caseSensitive: eligibility.caseSensitive,
    );

    final isEligible = regex.hasMatch(stringValue);

    dev.log(
      'StringMatch: key="${eligibility.contextKey}", '
      'value="$stringValue", pattern="${eligibility.pattern}", '
      'eligible=$isEligible',
      name: 'StringMatchRule',
    );

    return isEligible;
  }
}

/// Evaluates [AllOfEligibility] conditions (AND combinator).
///
/// Requires an [EligibilityResolver] to recursively evaluate nested conditions.
final class AllOfRule implements EligibilityRule<AllOfEligibility> {
  /// {@macro all_of_rule}
  const AllOfRule(this.rules);

  /// Rules to use for evaluating nested conditions.
  final List<EligibilityRule> rules;

  @override
  bool supports(Eligibility eligibility) => eligibility is AllOfEligibility;

  @override
  Future<bool> evaluate(
    AllOfEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    for (final condition in eligibility.conditions) {
      final rule = rules.firstWhere(
        (r) => r.supports(condition),
        orElse: () => throw EvaluationException(
          'No rule found for nested condition: ${condition.runtimeType}',
        ),
      );

      final isEligible = await _evaluateUnsafe(rule, condition, context);
      if (!isEligible) {
        dev.log('AllOf: Failed on condition $condition', name: 'AllOfRule');
        return false;
      }
    }

    dev.log(
      'AllOf: All ${eligibility.conditions.length} conditions passed',
      name: 'AllOfRule',
    );
    return true;
  }

  Future<bool> _evaluateUnsafe(
    EligibilityRule rule,
    Eligibility condition,
    Map<String, dynamic> context,
  ) => rule.evaluate(condition, context);
}

/// Evaluates [AnyOfEligibility] conditions (OR combinator).
final class AnyOfRule implements EligibilityRule<AnyOfEligibility> {
  /// {@macro any_of_rule}
  const AnyOfRule(this.rules);

  /// Rules to use for evaluating nested conditions.
  final List<EligibilityRule> rules;

  @override
  bool supports(Eligibility eligibility) => eligibility is AnyOfEligibility;

  @override
  Future<bool> evaluate(
    AnyOfEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    for (final condition in eligibility.conditions) {
      final rule = rules.firstWhere(
        (r) => r.supports(condition),
        orElse: () => throw EvaluationException(
          'No rule found for nested condition: ${condition.runtimeType}',
        ),
      );

      final isEligible = await _evaluateUnsafe(rule, condition, context);
      if (isEligible) {
        dev.log('AnyOf: Passed on condition $condition', name: 'AnyOfRule');
        return true;
      }
    }

    dev.log(
      'AnyOf: None of ${eligibility.conditions.length} conditions passed',
      name: 'AnyOfRule',
    );
    return false;
  }

  Future<bool> _evaluateUnsafe(
    EligibilityRule rule,
    Eligibility condition,
    Map<String, dynamic> context,
  ) => rule.evaluate(condition, context);
}

/// Evaluates [NotEligibility] conditions (NOT combinator).
final class NotRule implements EligibilityRule<NotEligibility> {
  /// {@macro not_rule}
  const NotRule(this.rules);

  /// Rules to use for evaluating the nested condition.
  final List<EligibilityRule> rules;

  @override
  bool supports(Eligibility eligibility) => eligibility is NotEligibility;

  @override
  Future<bool> evaluate(
    NotEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final rule = rules.firstWhere(
      (r) => r.supports(eligibility.condition),
      orElse: () => throw EvaluationException(
        'No rule found for nested condition: '
        '${eligibility.condition.runtimeType}',
      ),
    );

    final isEligible = await _evaluateUnsafe(
      rule,
      eligibility.condition,
      context,
    );
    final inverted = !isEligible;

    dev.log('Not: condition=$isEligible, inverted=$inverted', name: 'NotRule');

    return inverted;
  }

  Future<bool> _evaluateUnsafe(
    EligibilityRule rule,
    Eligibility condition,
    Map<String, dynamic> context,
  ) => rule.evaluate(condition, context);
}

/// Evaluates [ConstantEligibility] conditions.
///
/// Simply returns the constant boolean value.
final class ConstantRule implements EligibilityRule<ConstantEligibility> {
  /// {@macro constant_rule}
  const ConstantRule();

  @override
  bool supports(Eligibility eligibility) => eligibility is ConstantEligibility;

  @override
  Future<bool> evaluate(
    ConstantEligibility eligibility,
    Map<String, dynamic> context,
  ) async => eligibility.value;
}

/// Convenience function to create a standard rule set with all built-in rules.
///
/// Includes composite rules (AllOf, AnyOf, Not) which recursively use the same
/// rule set.
List<EligibilityRule> createStandardRules() {
  // Create base rules first
  final baseRules = <EligibilityRule>[
    const TimeRangeRule(),
    const SetMembershipRule(),
    const AnySegmentRule(),
    const BooleanFlagRule(),
    const NumericComparisonRule(),
    const StringMatchRule(),
    const ConstantRule(),
  ];

  // Create composite rules that reference the full list (including themselves)
  final allRules = <EligibilityRule>[...baseRules];

  // Add composite rules that can reference the full list
  allRules.addAll([
    AllOfRule(allRules),
    AnyOfRule(allRules),
    NotRule(allRules),
  ]);

  return allRules;
}
