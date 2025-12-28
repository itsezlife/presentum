import 'package:flutter/foundation.dart';
import 'package:presentum/src/eligibility/resolver.dart';

/// {@template time_range_eligibility}
/// Time must fall within a specified range (inclusive of start, exclusive of
/// end).
/// {@endtemplate}
@immutable
final class TimeRangeEligibility extends Eligibility {
  /// {@macro time_range_eligibility}
  const TimeRangeEligibility({required this.start, required this.end});

  /// Start time of the range.
  final DateTime start;

  /// End time of the range.
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRangeEligibility && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimeRangeEligibility(start: $start, end: $end)';
}

/// {@template set_membership_eligibility}
/// A value must be present in a specified set.
/// {@endtemplate}
@immutable
final class SetMembershipEligibility extends Eligibility {
  /// {@macro set_membership_eligibility}
  const SetMembershipEligibility({
    required this.contextKey,
    required this.allowedValues,
  });

  /// Key in the context map to read the value from.
  final String contextKey;

  /// Set of allowed values. The context value must match one of these.
  final Set<String> allowedValues;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetMembershipEligibility &&
          contextKey == other.contextKey &&
          allowedValues.length == other.allowedValues.length &&
          allowedValues.every(other.allowedValues.contains);

  @override
  int get hashCode => Object.hash(contextKey, Object.hashAll(allowedValues));

  @override
  String toString() =>
      'SetMembershipEligibility(key: $contextKey, allowed: $allowedValues)';
}

/// {@template any_segment_eligibility}
/// A value from context must be a member of at least one segment in the
/// required set.
/// {@endtemplate}
@immutable
final class AnySegmentEligibility extends Eligibility {
  /// {@macro any_segment_eligibility}
  const AnySegmentEligibility({
    required this.contextKey,
    required this.requiredSegments,
  });

  /// Key in context map containing a `Set<String>` or `List<String>` of user
  /// segments.
  final String contextKey;

  /// User must belong to at least one of these segments.
  final Set<String> requiredSegments;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnySegmentEligibility &&
          contextKey == other.contextKey &&
          requiredSegments.length == other.requiredSegments.length &&
          requiredSegments.every(other.requiredSegments.contains);

  @override
  int get hashCode => Object.hash(contextKey, Object.hashAll(requiredSegments));

  @override
  String toString() =>
      'AnySegmentEligibility(key: $contextKey, segments: $requiredSegments)';
}

/// {@template boolean_flag_eligibility}
/// A boolean flag in context must match the required value.
/// {@endtemplate}
@immutable
final class BooleanFlagEligibility extends Eligibility {
  /// {@macro boolean_flag_eligibility}
  const BooleanFlagEligibility({
    required this.contextKey,
    required this.requiredValue,
  });

  /// Key in the context map to read the boolean from.
  final String contextKey;

  /// Required boolean value for eligibility.
  final bool requiredValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BooleanFlagEligibility &&
          contextKey == other.contextKey &&
          requiredValue == other.requiredValue;

  @override
  int get hashCode => Object.hash(contextKey, requiredValue);

  @override
  String toString() =>
      'BooleanFlagEligibility(key: $contextKey, required: $requiredValue)';
}

/// Comparison operators for numeric eligibility.
enum NumericComparison {
  /// Compare value with threshold using the less than operator.
  lessThan,

  /// Compare value with threshold using the less than or equal operator.
  lessThanOrEqual,

  /// Compare value with threshold using the equal operator.
  equal,

  /// Compare value with threshold using the greater than or equal operator.
  greaterThanOrEqual,

  /// Compare value with threshold using the greater than operator.
  greaterThan,

  /// Compare value with threshold using the not equal operator.
  notEqual;

  /// Compare value with threshold using the operator.
  bool compare(num value, num threshold) => switch (this) {
    lessThan => value < threshold,
    lessThanOrEqual => value <= threshold,
    equal => value == threshold,
    greaterThanOrEqual => value >= threshold,
    greaterThan => value > threshold,
    notEqual => value != threshold,
  };

  @override
  String toString() => switch (this) {
    lessThan => '<',
    lessThanOrEqual => '<=',
    equal => '==',
    greaterThanOrEqual => '>=',
    greaterThan => '>',
    notEqual => '!=',
  };
}

/// {@template numeric_comparison_eligibility}
/// A numeric value from context must satisfy a comparison with a threshold.
/// {@endtemplate}
@immutable
final class NumericComparisonEligibility extends Eligibility {
  /// {@macro numeric_comparison_eligibility}
  const NumericComparisonEligibility({
    required this.contextKey,
    required this.comparison,
    required this.threshold,
  });

  /// Key in the context map to read the numeric value from.
  final String contextKey;

  /// Comparison operator to apply.
  final NumericComparison comparison;

  /// Threshold value to compare against.
  final num threshold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumericComparisonEligibility &&
          contextKey == other.contextKey &&
          comparison == other.comparison &&
          threshold == other.threshold;

  @override
  int get hashCode => Object.hash(contextKey, comparison, threshold);

  @override
  String toString() =>
      'NumericComparisonEligibility(key: $contextKey, $comparison $threshold)';
}

/// A string value from context must match a pattern.
@immutable
final class StringMatchEligibility extends Eligibility {
  /// {@macro string_match_eligibility}
  const StringMatchEligibility({
    required this.contextKey,
    required this.pattern,
    this.caseSensitive = true,
  });

  /// Key in the context map to read the string value from.
  final String contextKey;

  /// Regular expression pattern to match.
  final String pattern;

  /// Whether the match should be case-sensitive.
  final bool caseSensitive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringMatchEligibility &&
          contextKey == other.contextKey &&
          pattern == other.pattern &&
          caseSensitive == other.caseSensitive;

  @override
  int get hashCode => Object.hash(contextKey, pattern, caseSensitive);

  @override
  String toString() =>
      'StringMatchEligibility(key: $contextKey, '
      'pattern: $pattern, caseSensitive: $caseSensitive)';
}

/// {@template all_of_eligibility}
/// ALL nested conditions must be satisfied (AND combinator).
/// {@endtemplate}
@immutable
final class AllOfEligibility extends Eligibility {
  /// {@macro all_of_eligibility}
  const AllOfEligibility({required this.conditions});

  /// Nested conditions to be satisfied.
  final List<Eligibility> conditions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AllOfEligibility) return false;
    if (conditions.length != other.conditions.length) return false;
    for (var i = 0; i < conditions.length; i++) {
      if (conditions[i] != other.conditions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(conditions);

  @override
  String toString() => 'AllOfEligibility(${conditions.length} conditions)';
}

/// {@template any_of_eligibility}
/// At least ONE nested condition must be satisfied (OR combinator).
/// {@endtemplate}
@immutable
final class AnyOfEligibility extends Eligibility {
  /// {@macro any_of_eligibility}
  const AnyOfEligibility({required this.conditions});

  /// Nested conditions to be satisfied.
  final List<Eligibility> conditions;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnyOfEligibility) return false;
    if (conditions.length != other.conditions.length) return false;
    for (var i = 0; i < conditions.length; i++) {
      if (conditions[i] != other.conditions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(conditions);

  @override
  String toString() => 'AnyOfEligibility(${conditions.length} conditions)';
}

/// Inverts the result of a nested condition (NOT combinator).
@immutable
final class NotEligibility extends Eligibility {
  /// {@macro not_eligibility}
  const NotEligibility({required this.condition});

  /// Nested condition to be inverted.
  final Eligibility condition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotEligibility && condition == other.condition;

  @override
  int get hashCode => condition.hashCode;

  @override
  String toString() => 'NotEligibility($condition)';
}

/// A direct boolean value (useful for hard-coded eligibility).
///
/// Warning: This is trivial and mainly useful for testing or explicit
/// overrides.
@immutable
final class ConstantEligibility extends Eligibility {
  /// {@macro constant_eligibility}
  const ConstantEligibility({required this.value});

  /// Constant boolean value.
  final bool value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstantEligibility && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ConstantEligibility($value)';
}

/// Days of the week for recurring patterns.
enum DayOfWeek {
  /// Monday
  monday(DateTime.monday),

  /// Tuesday
  tuesday(DateTime.tuesday),

  /// Wednesday
  wednesday(DateTime.wednesday),

  /// Thursday
  thursday(DateTime.thursday),

  /// Friday
  friday(DateTime.friday),

  /// Saturday
  saturday(DateTime.saturday),

  /// Sunday
  sunday(DateTime.sunday);

  const DayOfWeek(this.value);

  /// Corresponding DateTime weekday constant (1-7).
  final int value;

  /// Parse from lowercase string.
  static DayOfWeek parse(String day) => switch (day.toLowerCase()) {
    'monday' || 'mon' => monday,
    'tuesday' || 'tue' => tuesday,
    'wednesday' || 'wed' => wednesday,
    'thursday' || 'thu' => thursday,
    'friday' || 'fri' => friday,
    'saturday' || 'sat' => saturday,
    'sunday' || 'sun' => sunday,
    _ => throw ArgumentError('Invalid day: $day'),
  };

  /// Parse from lowercase string.
  static DayOfWeek? tryParse(String day) {
    try {
      return parse(day);
    } on Object catch (_) {
      return null;
    }
  }
}

/// Time of day representation (hours and minutes).
@immutable
final class TimeOfDay {
  /// Creates a time of day.
  const TimeOfDay({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24, 'Hour must be 0-23'),
      assert(minute >= 0 && minute < 60, 'Minute must be 0-59');

  /// Parse from "HH:mm" format.
  factory TimeOfDay.parse(String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Time must be in HH:mm format: $time');
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      throw FormatException('Invalid time format: $time');
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Parse from "HH:mm" format.
  static TimeOfDay? tryParse(String time) {
    try {
      return TimeOfDay.parse(time);
    } on Object catch (_) {
      return null;
    }
  }

  /// Hour (0-23).
  final int hour;

  /// Minute (0-59).
  final int minute;

  /// Convert to minutes since midnight for comparison.
  int get minutesSinceMidnight => hour * 60 + minute;

  /// Check if this time is before another time (within same day).
  bool isBefore(TimeOfDay other) =>
      minutesSinceMidnight < other.minutesSinceMidnight;

  /// Check if this time equals another time.
  bool isAtSameTime(TimeOfDay other) =>
      hour == other.hour && minute == other.minute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

/// {@template recurring_time_pattern_eligibility}
/// Time must match a recurring weekly pattern (cron-like).
///
/// Evaluates against **local time** (not UTC) for intuitive user experience.
///
/// Examples:
/// - Monday-Friday 9am-5pm (business hours)
/// - Saturday-Sunday 10am-11pm (weekend hours)
/// - Any day 5pm-2am (evening/night, crosses midnight)
/// {@endtemplate}
@immutable
final class RecurringTimePatternEligibility extends Eligibility {
  /// {@macro recurring_time_pattern_eligibility}
  const RecurringTimePatternEligibility({
    required this.timeStart,
    required this.timeEnd,
    this.daysOfWeek = const {},
  });

  /// Start time of the daily window (inclusive).
  final TimeOfDay timeStart;

  /// End time of the daily window (exclusive).
  final TimeOfDay timeEnd;

  /// Days of week this pattern applies to.
  ///
  /// Empty set means all days.
  final Set<DayOfWeek> daysOfWeek;

  /// Whether this pattern crosses midnight (e.g., 22:00-02:00).
  bool get crossesMidnight => timeEnd.isBefore(timeStart);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTimePatternEligibility &&
          timeStart == other.timeStart &&
          timeEnd == other.timeEnd &&
          daysOfWeek.length == other.daysOfWeek.length &&
          daysOfWeek.every(other.daysOfWeek.contains);

  @override
  int get hashCode =>
      Object.hash(timeStart, timeEnd, Object.hashAll(daysOfWeek));

  @override
  String toString() {
    final daysStr = daysOfWeek.isEmpty
        ? 'any day'
        : daysOfWeek.map((d) => d.name).join(', ');
    return 'RecurringTimePatternEligibility($daysStr $timeStart-$timeEnd)';
  }
}
