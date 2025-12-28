// ignore_for_file: lines_longer_than_80_chars

import 'package:presentum/src/eligibility/conditions.dart';
import 'package:presentum/src/eligibility/metadata_keys.dart';
import 'package:presentum/src/eligibility/resolver.dart';

/// Interface for subjects that have metadata.
///
/// This allows extractors to work with any subject that provides metadata.
abstract interface class HasMetadata {
  /// The metadata map.
  ///
  /// This map is used to store the metadata for the subject.
  Map<String, dynamic> get metadata;
}

/// {@template metadata_extractor}
/// Base class for metadata-based extractors.
///
/// Provides common validation utilities for extractors that parse metadata.
/// {@endtemplate}
abstract class MetadataExtractor<S extends HasMetadata>
    with _MetadataValidatorMixin
    implements EligibilityExtractor<S> {
  /// {@macro metadata_extractor}
  const MetadataExtractor();

  /// The key in metadata to read the value from.
  abstract final String metadataKey;

  /// Returns the suffix for the metadata key.
  String suffix(String suffix) => MetadataKeys(metadataKey).suffix(suffix);

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);
}

/// {@template time_range_extractor}
/// Extracts [TimeRangeEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "time_range": {
///     "start": "2025-12-01T00:00:00Z",
///     "end": "2025-12-31T23:59:59Z"
///   }
/// }
/// ```
final class TimeRangeExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro time_range_extractor}
  const TimeRangeExtractor({this.metadataKey = MetadataKeys.timeRange});

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final range = subject.metadata[metadataKey];
    if (range is! Map) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a map with "start" and "end" keys',
          'received: $range',
        ),
        StackTrace.current,
      );
    }

    final start = requireDateTime(
      range[MetadataKeys.start],
      suffix(MetadataKeys.start),
    );
    final end = requireDateTime(
      range[MetadataKeys.end],
      suffix(MetadataKeys.end),
    );

    if (start.isAfter(end) || start.isAtSameMomentAs(end)) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "${suffix(MetadataKeys.start)}" must be before "${suffix(MetadataKeys.end)}"',
          'received: start: $start >= end: $end',
        ),
        StackTrace.current,
      );
    }

    return [TimeRangeEligibility(start: start, end: end)];
  }
}

/// {@template set_membership_extractor}
/// Extracts [SetMembershipEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "required_status": {
///     "context_key": "user_status",
///     "allowed_values": ["active", "trial"]
///   }
/// }
/// ```
final class SetMembershipExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro set_membership_extractor}
  const SetMembershipExtractor({
    this.metadataKey = MetadataKeys.requiredStatus,
  });

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a map with "${MetadataKeys.contextKey}" and '
              '"${MetadataKeys.allowedValues}"',
          'received: $data',
        ),
        StackTrace.current,
      );
    }

    final contextKey = requireString(
      data[MetadataKeys.contextKey],
      suffix(MetadataKeys.contextKey),
    );
    final allowedValues = requireStringList(
      data[MetadataKeys.allowedValues],
      suffix(MetadataKeys.allowedValues),
    ).toSet();

    return [
      SetMembershipEligibility(
        contextKey: contextKey,
        allowedValues: allowedValues,
      ),
    ];
  }
}

/// {@template any_segment_extractor}
/// Extracts [AnySegmentEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "required_segments": ["premium", "beta_tester"]
/// }
/// ```
final class AnySegmentExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro any_segment_extractor}
  const AnySegmentExtractor({
    required this.contextKey,
    this.metadataKey = MetadataKeys.requiredSegments,
  });

  @override
  final String metadataKey;

  /// Key in context to check against (domain-specific, must be provided).
  final String contextKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final segments = requireStringList(
      subject.metadata[metadataKey],
      metadataKey,
    ).toSet();

    return [
      AnySegmentEligibility(contextKey: contextKey, requiredSegments: segments),
    ];
  }
}

/// {@template boolean_flag_extractor}
/// Extracts [BooleanFlagEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "is_active": true
/// }
/// ```
final class BooleanFlagExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro boolean_flag_extractor}
  const BooleanFlagExtractor({
    required this.metadataKey,
    required this.contextKey,
    this.requiredValue = true,
  });

  @override
  final String metadataKey;

  /// Key in context to check against.
  final String contextKey;

  /// Required value for eligibility (default: true).
  final bool requiredValue;

  @override
  Iterable<Eligibility> extract(S subject) {
    final value = requireBool(subject.metadata[metadataKey], metadataKey);

    return [
      BooleanFlagEligibility(contextKey: contextKey, requiredValue: value),
    ];
  }
}

/// {@template numeric_comparison_extractor}
/// Extracts [NumericComparisonEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "min_version": {
///     "context_key": "app_version",
///     "operator": ">=",
///     "threshold": 2.5
///   }
/// }
/// ```
final class NumericComparisonExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro numeric_comparison_extractor}
  const NumericComparisonExtractor({required this.metadataKey});

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a map with "${MetadataKeys.contextKey}", "${MetadataKeys.operator}", '
              'and "${MetadataKeys.threshold}"',
          'received: $data',
        ),
        StackTrace.current,
      );
    }

    final contextKey = requireString(
      data[MetadataKeys.contextKey],
      suffix(MetadataKeys.contextKey),
    );
    final operatorStr = requireString(
      data[MetadataKeys.operator],
      suffix(MetadataKeys.operator),
    );
    final threshold = requireNum(
      data[MetadataKeys.threshold],
      suffix(MetadataKeys.threshold),
    );

    final comparison = _parseOperator(operatorStr);

    return [
      NumericComparisonEligibility(
        contextKey: contextKey,
        comparison: comparison,
        threshold: threshold,
      ),
    ];
  }

  NumericComparison _parseOperator(String operator) => switch (operator) {
    '<' => NumericComparison.lessThan,
    '<=' => NumericComparison.lessThanOrEqual,
    '==' || '=' => NumericComparison.equal,
    '>=' => NumericComparison.greaterThanOrEqual,
    '>' => NumericComparison.greaterThan,
    '!=' => NumericComparison.notEqual,
    _ => throw MalformedMetadataException(
      'Invalid comparison operator: $operator',
      'supported: <, <=, ==, >=, >, !=',
    ),
  };
}

/// {@template string_match_extractor}
/// Extracts [StringMatchEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "platform_pattern": {
///     "context_key": "platform",
///     "pattern": "^(ios|android)$",
///     "case_sensitive": false
///   }
/// }
/// ```
final class StringMatchExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro string_match_extractor}
  const StringMatchExtractor({required this.metadataKey});

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a map with "${MetadataKeys.contextKey}" and "${MetadataKeys.pattern}"',
          'received: $data',
        ),
        StackTrace.current,
      );
    }

    final contextKey = requireString(
      data[MetadataKeys.contextKey],
      suffix(MetadataKeys.contextKey),
    );
    final pattern = requireString(
      data[MetadataKeys.pattern],
      suffix(MetadataKeys.pattern),
    );
    final caseSensitive = data[MetadataKeys.caseSensitive] as bool? ?? true;

    // Validate regex pattern
    try {
      RegExp(pattern);
    } catch (e) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Invalid regex pattern in "${suffix(MetadataKeys.pattern)}"',
          'error: $e',
        ),
        StackTrace.current,
      );
    }

    return [
      StringMatchEligibility(
        contextKey: contextKey,
        pattern: pattern,
        caseSensitive: caseSensitive,
      ),
    ];
  }
}

/// {@template constant_extractor}
/// Extracts [ConstantEligibility] from metadata.
///
/// This allows hard-coding eligibility values in metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "is_active": true
/// }
/// ```
final class ConstantExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro constant_extractor}
  const ConstantExtractor({required this.metadataKey});

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final value = requireBool(subject.metadata[metadataKey], metadataKey);

    return [ConstantEligibility(value: value)];
  }
}

/// Extracts [AllOfEligibility] from metadata (nested extractors).
///
/// This allows combining multiple conditions with AND logic.
///
/// Expected metadata:
/// ```json
/// {
///   "all_of": [
///     { "time_range": {...} },
///     { "required_segments": [...] }
///   ]
/// }
/// ```
final class AllOfExtractor<S extends HasMetadata> extends MetadataExtractor<S> {
  /// {@macro all_of_extractor}
  const AllOfExtractor({required this.nestedExtractors});

  /// Nested extractors must work with [HasMetadata], not a specific type.
  final List<EligibilityExtractor<HasMetadata>> nestedExtractors;

  /// The key in metadata to read the value from.
  @override
  String get metadataKey => MetadataKeys.allOf;

  @override
  Iterable<Eligibility> extract(S subject) {
    final conditions = <Eligibility>[];

    final items = subject.metadata[metadataKey];
    if (items is! List) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a list of condition maps',
          'received: $items',
        ),
        StackTrace.current,
      );
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        Error.throwWithStackTrace(
          MalformedMetadataException(
            'Each item in "$metadataKey" must be a map',
            'received: $item',
          ),
          StackTrace.current,
        );
      }

      // Create a temporary subject with this item as metadata
      final tempSubject = _MetadataWrapper(item);

      for (final extractor in nestedExtractors) {
        if (extractor.supports(tempSubject)) {
          conditions.addAll(extractor.extract(tempSubject));
        }
      }
    }

    if (conditions.isEmpty) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" produced no valid conditions',
          'received: $items',
        ),
        StackTrace.current,
      );
    }

    return [AllOfEligibility(conditions: conditions)];
  }
}

/// Extracts [AnyOfEligibility] from metadata (nested extractors).
///
/// This allows combining multiple conditions with OR logic.
final class AnyOfExtractor<S extends HasMetadata> extends MetadataExtractor<S> {
  /// {@macro any_of_extractor}
  const AnyOfExtractor({required this.nestedExtractors});

  /// Nested extractors must work with [HasMetadata], not a specific type.
  final List<EligibilityExtractor<HasMetadata>> nestedExtractors;

  @override
  String get metadataKey => MetadataKeys.anyOf;

  @override
  Iterable<Eligibility> extract(S subject) {
    final conditions = <Eligibility>[];

    final items = subject.metadata[metadataKey];
    if (items is! List) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a list of condition maps',
          'received: $items',
        ),
        StackTrace.current,
      );
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        Error.throwWithStackTrace(
          MalformedMetadataException(
            'Each item in "$metadataKey" must be a map',
            'received: $item',
          ),
          StackTrace.current,
        );
      }

      final tempSubject = _MetadataWrapper(item);

      for (final extractor in nestedExtractors) {
        if (extractor.supports(tempSubject)) {
          conditions.addAll(extractor.extract(tempSubject));
        }
      }
    }

    if (conditions.isEmpty) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" produced no valid conditions',
          'received: $items',
        ),
        StackTrace.current,
      );
    }

    return [AnyOfEligibility(conditions: conditions)];
  }
}

/// {@template recurring_time_pattern_extractor}
/// Extracts [RecurringTimePatternEligibility] from metadata.
/// {@endtemplate}
///
/// Expected metadata:
/// ```json
/// {
///   "recurring_time_pattern": {
///     "days_of_week": ["monday", "tuesday", "wednesday", "thursday", "friday"],
///     "time_start": "13:00",
///     "time_end": "17:00"
///   }
/// }
/// ```
///
/// Or for all days:
/// ```json
/// {
///   "recurring_time_pattern": {
///     "time_start": "17:00",
///     "time_end": "22:00"
///   }
/// }
/// ```
final class RecurringTimePatternExtractor<S extends HasMetadata>
    extends MetadataExtractor<S> {
  /// {@macro recurring_time_pattern_extractor}
  const RecurringTimePatternExtractor({
    this.metadataKey = MetadataKeys.recurringTimePattern,
  });

  @override
  final String metadataKey;

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$metadataKey" must be a map with "${MetadataKeys.timeStart}" and "${MetadataKeys.timeEnd}"',
          'received: $data',
        ),
        StackTrace.current,
      );
    }

    // Parse time range (required)
    final timeStartStr = requireString(
      data[MetadataKeys.timeStart],
      suffix(MetadataKeys.timeStart),
    );
    final timeEndStr = requireString(
      data[MetadataKeys.timeEnd],
      suffix(MetadataKeys.timeEnd),
    );

    final TimeOfDay timeStart;
    final TimeOfDay timeEnd;

    try {
      timeStart = TimeOfDay.parse(timeStartStr);
    } on Object catch (_) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Invalid time format in "${suffix(MetadataKeys.timeStart)}"',
          'expected HH:mm, got: $timeStartStr',
        ),
        StackTrace.current,
      );
    }

    try {
      timeEnd = TimeOfDay.parse(timeEndStr);
    } on Object catch (_) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Invalid time format in "${suffix(MetadataKeys.timeEnd)}"',
          'expected HH:mm, got: $timeEndStr',
        ),
        StackTrace.current,
      );
    }

    // Validate time range (start != end)
    if (timeStart.isAtSameTime(timeEnd)) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Invalid time range in "$metadataKey"',
          '${suffix(MetadataKeys.timeStart)} and ${suffix(MetadataKeys.timeEnd)} cannot be equal: $timeStartStr',
        ),
        StackTrace.current,
      );
    }

    // Parse days of week (optional)
    final Set<DayOfWeek> daysOfWeek;
    final rawDays = data[MetadataKeys.daysOfWeek];

    if (rawDays == null) {
      // No days specified = all days
      daysOfWeek = {};
    } else if (rawDays is List) {
      final dayStrings = rawDays.whereType<String>().toList();
      if (dayStrings.isEmpty && rawDays.isNotEmpty) {
        Error.throwWithStackTrace(
          MalformedMetadataException(
            'Field "${suffix(MetadataKeys.daysOfWeek)}" must contain strings',
            'received: $rawDays',
          ),
          StackTrace.current,
        );
      }

      try {
        daysOfWeek = dayStrings.map(DayOfWeek.parse).toSet();
      } catch (e) {
        Error.throwWithStackTrace(
          MalformedMetadataException(
            'Invalid day name in "${suffix(MetadataKeys.daysOfWeek)}"',
            'error: $e',
          ),
          StackTrace.current,
        );
      }
    } else {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "${suffix(MetadataKeys.daysOfWeek)}" must be a list of strings',
          'received: $rawDays',
        ),
        StackTrace.current,
      );
    }

    return [
      RecurringTimePatternEligibility(
        timeStart: timeStart,
        timeEnd: timeEnd,
        daysOfWeek: daysOfWeek,
      ),
    ];
  }
}

/// Internal wrapper for nested metadata extraction.
class _MetadataWrapper implements HasMetadata {
  const _MetadataWrapper(this.metadata);

  @override
  final Map<String, dynamic> metadata;
}

mixin _MetadataValidatorMixin {
  /// Validates that a value is a non-empty string.
  String requireString(Object? value, String fieldName) {
    if (value is! String || value.isEmpty) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$fieldName" must be a non-empty string',
          'received: $value',
        ),
        StackTrace.current,
      );
    }
    return value;
  }

  /// Validates that a value is a boolean.
  bool requireBool(Object? value, String fieldName) {
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    Error.throwWithStackTrace(
      MalformedMetadataException(
        'Field "$fieldName" must be a boolean or "true"/"false" string',
        'received: $value',
      ),
      StackTrace.current,
    );
  }

  /// Validates that a value is a number.
  num requireNum(Object? value, String fieldName) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    Error.throwWithStackTrace(
      MalformedMetadataException(
        'Field "$fieldName" must be a number',
        'received: $value',
      ),
      StackTrace.current,
    );
  }

  /// Validates that a value is a non-empty list of strings.
  List<String> requireStringList(Object? value, String fieldName) {
    if (value is! List || value.isEmpty) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$fieldName" must be a non-empty list',
          'received: $value',
        ),
        StackTrace.current,
      );
    }

    final strings = value.whereType<String>().toList();
    if (strings.isEmpty) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$fieldName" must contain at least one string',
          'received: $value',
        ),
        StackTrace.current,
      );
    }

    return strings;
  }

  /// Validates that a value is a parseable DateTime.
  DateTime requireDateTime(Object? value, String fieldName) {
    if (value is! String) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$fieldName" must be an ISO 8601 date string',
          'received: $value',
        ),
        StackTrace.current,
      );
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Field "$fieldName" is not a valid ISO 8601 date',
          'received: $value',
        ),
        StackTrace.current,
      );
    }

    return parsed;
  }
}
