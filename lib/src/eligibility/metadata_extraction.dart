import 'package:collection/collection.dart';
import 'package:presentum/src/eligibility/conditions.dart';
import 'package:presentum/src/eligibility/metadata_keys.dart';

/// {@template metadata_extraction}
/// Type-safe utilities for extracting structured data from metadata.
///
/// Provides pattern-matching based accessors that return typed results
/// or null if the field is missing or malformed.
///
/// Example:
/// ```dart
/// final payload = MyPayload(metadata: {...});
///
/// // Extract time range with type safety
/// if (payload.timeRange case (start: final s, end: final e)) {
///   print('Active from $s to $e');
/// }
///
/// // Extract boolean flag
/// final isActive = payload.metadata.getBoolFlag(MetadataKeys.isActive);
/// ```
/// {@endtemplate}
extension MetadataExtraction on Map<String, dynamic> {
  /// Extracts a nested value from metadata.
  ///
  /// Returns `null` if the key doesn't exist or value is not a list of maps.
  ///
  /// Example:
  /// ```dart
  /// metadata.maybeGetNested('any_of', (map) => map.timeRange);
  /// ```
  T? maybeGetNested<T>(String key, T? Function(Map<String, dynamic>) mapper) {
    final conditions = getList<dynamic>(key);
    if (conditions == null) return null;

    final mapConditions = <Map<String, dynamic>>[];
    for (final condition in conditions) {
      if (condition case final Map<String, dynamic> map) {
        mapConditions.add(map);
      }
    }

    if (mapConditions.isEmpty) return null;

    return mapConditions.map(mapper).firstWhereOrNull((e) => e != null);
  }

  /// Extracts a nested value from metadata or falls back to flat extraction.
  ///
  /// Example:
  /// ```dart
  /// metadata.maybeGetNestedOrFlat('any_of', (map) => map.timeRange);
  /// ```
  T? maybeGetNestedOrFlat<T>(
    String key,
    T? Function(Map<String, dynamic>) mapper,
  ) => maybeGetNested(key, mapper) ?? mapper(this);

  /// Extracts a flat value first, then tries nested extraction as fallback.
  ///
  /// Example:
  /// ```dart
  /// metadata.maybeGetFlatOrNested('any_of', (map) => map.timeRange);
  /// ```
  T? maybeGetFlatOrNested<T>(
    String key,
    T? Function(Map<String, dynamic>) mapper,
  ) => mapper(this) ?? maybeGetNested(key, mapper);

  /// Extracts a time range from metadata.
  ///
  /// Returns a record with `start` and `end` DateTime values if the metadata
  /// contains a valid time range structure, otherwise returns `null`.
  ///
  /// Expected structure:
  /// ```json
  /// {
  ///   "time_range": {
  ///     "start": "2025-12-28T00:00:00Z",
  ///     "end": "2025-12-28T16:28:00Z"
  ///   }
  /// }
  /// ```
  ({DateTime start, DateTime end})? timeRange({
    String key = MetadataKeys.timeRange,
  }) => switch (this[key]) {
    <String, dynamic>{
      MetadataKeys.start: final String startStr,
      MetadataKeys.end: final String endStr,
    } =>
      _parseTimeRange(startStr, endStr),
    _ => null,
  };

  /// Internal helper to parse and validate time ranges.
  ({DateTime start, DateTime end})? _parseTimeRange(
    String startStr,
    String endStr,
  ) {
    final start = DateTime.tryParse(startStr);
    final end = DateTime.tryParse(endStr);

    if (start == null || end == null || start.isAfter(end)) {
      return null;
    }

    return (start: start, end: end);
  }

  /// Calculates time remaining until the end of a time range.
  Duration? timeUntilEnd({String key = MetadataKeys.timeRange}) {
    final range = timeRange(key: key);
    if (range == null) return null;

    final now = DateTime.now();
    return range.end.difference(now);
  }

  /// Checks if current time is within the time range.
  bool isWithinTimeRange({String key = MetadataKeys.timeRange}) {
    final range = timeRange(key: key);
    if (range == null) return false;

    final now = DateTime.now();
    return now.isAfter(range.start) && now.isBefore(range.end);
  }

  /// Extracts recurring time pattern from metadata.
  ///
  /// Returns a record with time boundaries and optional days of week.
  ///
  /// Expected structure:
  /// ```json
  /// {
  ///   "recurring_time_pattern": {
  ///     "time_start": "09:00",
  ///     "time_end": "17:00",
  ///     "days_of_week": ["monday", "friday"]  // optional
  ///   }
  /// }
  /// ```
  ({TimeOfDay timeStart, TimeOfDay timeEnd, Set<DayOfWeek>? daysOfWeek})?
  recurringTimePattern({String key = MetadataKeys.recurringTimePattern}) =>
      switch (this[key]) {
        <String, dynamic>{
          MetadataKeys.timeStart: final String startStr,
          MetadataKeys.timeEnd: final String endStr,
        } =>
          _parseRecurringPattern(
            startStr,
            endStr,
            this[key] as Map<String, dynamic>,
          ),
        _ => null,
      };

  /// Internal helper to parse recurring time patterns.
  ({TimeOfDay timeStart, TimeOfDay timeEnd, Set<DayOfWeek>? daysOfWeek})?
  _parseRecurringPattern(
    String startStr,
    String endStr,
    Map<String, dynamic> patternData,
  ) {
    final TimeOfDay start;
    final TimeOfDay end;

    try {
      start = TimeOfDay.parse(startStr);
      end = TimeOfDay.parse(endStr);
    } on Object catch (_) {
      return null;
    }

    if (start.isAtSameTime(end)) {
      return null;
    }

    final days = patternData.getList<String>(MetadataKeys.daysOfWeek);

    final daysOfWeek = days?.map(DayOfWeek.parse).toSet();

    return (timeStart: start, timeEnd: end, daysOfWeek: daysOfWeek);
  }

  /// Extracts set membership configuration.
  ///
  /// Expected structure:
  /// ```json
  /// {
  ///   "required_status": {
  ///     "context_key": "user_status",
  ///     "allowed_values": ["active", "trial"]
  ///   }
  /// }
  /// ```
  ({String contextKey, Set<String> allowedValues})? requiredStatus({
    String key = MetadataKeys.requiredStatus,
  }) => switch (this[key]) {
    <String, dynamic>{
      MetadataKeys.contextKey: final String contextKey,
      MetadataKeys.allowedValues: final List<dynamic> allowedValues,
    }
        when allowedValues.every((e) => e is String) =>
      (
        contextKey: contextKey,
        allowedValues: allowedValues.cast<String>().toSet(),
      ),
    _ => null,
  };

  /// Safely extracts a value of type [T].
  T? getValue<T>(String key) => switch (this[key]) {
    final T value => value,
    _ => null,
  };

  /// Safely extracts a numeric value.
  num? getNum(String key) => getValue<num>(key);

  /// Extracts a boolean flag from metadata by key.
  ///
  /// Returns `null` if the key doesn't exist or value is not a boolean.
  ///
  /// Example:
  /// ```dart
  /// final isActive = payload.getBoolFlag('is_active');
  /// ```
  bool? getBoolFlag(String key) => getValue<bool>(key);

  /// Convenience getter for the common "is_active" flag.
  bool? get isActive => getBoolFlag(MetadataKeys.isActive);

  /// Safely extracts a string value.
  String? getString(String key) => getValue<String>(key);

  /// Safely extracts a list value.
  List<T>? getList<T>(String key) => getValue<List<T>>(key);

  /// Safely extracts a map value.
  Map<String, dynamic>? getMap(String key) =>
      getValue<Map<String, dynamic>>(key);
}
