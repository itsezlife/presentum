import 'package:presentum/src/eligibility/conditions.dart';
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
    implements EligibilityExtractor<S> {
  /// {@macro metadata_extractor}
  const MetadataExtractor();

  /// Validates that a value is a non-empty string.
  String requireString(Object? value, String fieldName) {
    if (value is! String || value.isEmpty) {
      throw MalformedMetadataException(
        'Field "$fieldName" must be a non-empty string',
        'received: $value',
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
    throw MalformedMetadataException(
      'Field "$fieldName" must be a boolean or "true"/"false" string',
      'received: $value',
    );
  }

  /// Validates that a value is a number.
  num requireNum(Object? value, String fieldName) {
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw MalformedMetadataException(
      'Field "$fieldName" must be a number',
      'received: $value',
    );
  }

  /// Validates that a value is a non-empty list of strings.
  List<String> requireStringList(Object? value, String fieldName) {
    if (value is! List || value.isEmpty) {
      throw MalformedMetadataException(
        'Field "$fieldName" must be a non-empty list',
        'received: $value',
      );
    }

    final strings = value.whereType<String>().toList();
    if (strings.isEmpty) {
      throw MalformedMetadataException(
        'Field "$fieldName" must contain at least one string',
        'received: $value',
      );
    }

    return strings;
  }

  /// Validates that a value is a parseable DateTime.
  DateTime requireDateTime(Object? value, String fieldName) {
    if (value is! String) {
      throw MalformedMetadataException(
        'Field "$fieldName" must be an ISO 8601 date string',
        'received: $value',
      );
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw MalformedMetadataException(
        'Field "$fieldName" is not a valid ISO 8601 date',
        'received: $value',
      );
    }

    return parsed;
  }
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
  const TimeRangeExtractor({this.metadataKey = 'time_range'});

  /// Key in metadata to read the time range from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final range = subject.metadata[metadataKey];
    if (range is! Map) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a map with "start" and "end" keys',
        'received: $range',
      );
    }

    final start = requireDateTime(range['start'], '$metadataKey.start');
    final end = requireDateTime(range['end'], '$metadataKey.end');

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
  const SetMembershipExtractor({this.metadataKey = 'required_status'});

  /// Key in metadata to read the list of allowed values from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a map with "context_key" and '
            '"allowed_values"',
        'received: $data',
      );
    }

    final contextKey = requireString(
      data['context_key'],
      '$metadataKey.context_key',
    );
    final allowedValues = requireStringList(
      data['allowed_values'],
      '$metadataKey.allowed_values',
    ).toSet();

    return [
      SetMembershipEligibility(
        contextKey: contextKey,
        allowedValues: allowedValues,
      ),
    ];
  }
}

/// Extracts [AnySegmentEligibility] from metadata.
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
    this.metadataKey = 'required_segments',
    this.contextKey = 'user_segments',
  });

  /// Key in metadata to read the list of segments from.
  final String metadataKey;

  /// Key in context to check against.
  final String contextKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

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

  /// Key in metadata to read the boolean from.
  final String metadataKey;

  /// Key in context to check against.
  final String contextKey;

  /// Required value for eligibility (default: true).
  final bool requiredValue;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

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
  const NumericComparisonExtractor({this.metadataKey = 'min_version'});

  /// Key in metadata to read the numeric value from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a map with "context_key", "operator", '
            'and "threshold"',
        'received: $data',
      );
    }

    final contextKey = requireString(
      data['context_key'],
      '$metadataKey.context_key',
    );
    final operatorStr = requireString(
      data['operator'],
      '$metadataKey.operator',
    );
    final threshold = requireNum(data['threshold'], '$metadataKey.threshold');

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

/// Extracts [StringMatchEligibility] from metadata.
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
  const StringMatchExtractor({this.metadataKey = 'platform_pattern'});

  /// Key in metadata to read the string value from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final data = subject.metadata[metadataKey];
    if (data is! Map) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a map with "context_key" and "pattern"',
        'received: $data',
      );
    }

    final contextKey = requireString(
      data['context_key'],
      '$metadataKey.context_key',
    );
    final pattern = requireString(data['pattern'], '$metadataKey.pattern');
    final caseSensitive = data['case_sensitive'] as bool? ?? true;

    // Validate regex pattern
    try {
      RegExp(pattern);
    } catch (e) {
      throw MalformedMetadataException(
        'Invalid regex pattern in "$metadataKey.pattern"',
        'error: $e',
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
  const AllOfExtractor({
    required this.nestedExtractors,
    this.metadataKey = 'all_of',
  });

  /// Nested extractors must work with [HasMetadata], not a specific type.
  final List<EligibilityExtractor<HasMetadata>> nestedExtractors;

  /// Key in metadata to read the list of conditions from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final conditions = <Eligibility>[];

    final items = subject.metadata[metadataKey];
    if (items is! List) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a list of condition maps',
        'received: $items',
      );
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw MalformedMetadataException(
          'Each item in "$metadataKey" must be a map',
          'received: $item',
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
      throw MalformedMetadataException(
        'Field "$metadataKey" produced no valid conditions',
        'received: $items',
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
  const AnyOfExtractor({
    required this.nestedExtractors,
    this.metadataKey = 'any_of',
  });

  /// Nested extractors must work with [HasMetadata], not a specific type.
  final List<EligibilityExtractor<HasMetadata>> nestedExtractors;

  /// Key in metadata to read the list of conditions from.
  final String metadataKey;

  @override
  bool supports(S subject) => subject.metadata.containsKey(metadataKey);

  @override
  Iterable<Eligibility> extract(S subject) {
    final conditions = <Eligibility>[];

    final items = subject.metadata[metadataKey];
    if (items is! List) {
      throw MalformedMetadataException(
        'Field "$metadataKey" must be a list of condition maps',
        'received: $items',
      );
    }

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw MalformedMetadataException(
          'Each item in "$metadataKey" must be a map',
          'received: $item',
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
      throw MalformedMetadataException(
        'Field "$metadataKey" produced no valid conditions',
        'received: $items',
      );
    }

    return [AnyOfEligibility(conditions: conditions)];
  }
}

/// Internal wrapper for nested metadata extraction.
class _MetadataWrapper implements HasMetadata {
  const _MetadataWrapper(this.metadata);

  @override
  final Map<String, dynamic> metadata;
}
