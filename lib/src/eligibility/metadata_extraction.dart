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
/// final isActive = payload.getBoolFlag(MetadataKeys.isActive);
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

    return mapConditions.map(mapper).firstWhereOrNull((e) => e != null);
  }

  /// Extracts a nested value from metadata or falls back to flat extraction.
  ///
  /// First tries to extract from nested structure using the key, then falls
  /// back to applying the mapper directly to the current map if nested
  /// extraction returns null.
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
  /// First tries to apply the mapper directly to the current map, then falls
  /// back to extracting from nested structure using the key if flat
  /// extraction returns null.
  ///
  /// Example:
  /// ```dart
  /// metadata.maybeGetFlatOrNested('any_of', (map) => map.timeRange);
  /// ```
  T? maybeGetFlatOrNested<T>(
    String key,
    T? Function(Map<String, dynamic>) mapper,
  ) => mapper(this) ?? maybeGetNested(key, mapper);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Time-based extractions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
  ({DateTime start, DateTime end})? get timeRange =>
      switch (this[MetadataKeys.timeRange]) {
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
  ///
  /// Returns `null` if:
  /// - No time range is present
  /// - Time range is invalid
  /// - Current time is before the range starts
  /// - Current time is after the range ends
  Duration? get timeUntilEnd {
    final range = timeRange;
    if (range == null) return null;

    final now = DateTime.now();
    return range.end.difference(now);
  }

  /// Checks if current time is within the time range.
  bool get isWithinTimeRange {
    final range = timeRange;
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
  get recurringTimePattern => switch (this[MetadataKeys.recurringTimePattern]) {
    <String, dynamic>{
      MetadataKeys.timeStart: final String startStr,
      MetadataKeys.timeEnd: final String endStr,
    } =>
      _parseRecurringPattern(
        startStr,
        endStr,
        this[MetadataKeys.recurringTimePattern] as Map<String, dynamic>,
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Boolean and flag extractions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Extracts a boolean flag from metadata by key.
  ///
  /// Returns `null` if the key doesn't exist or value is not a boolean.
  ///
  /// Example:
  /// ```dart
  /// final isActive = payload.getBoolFlag('is_active');
  /// ```
  bool? getBoolFlag(String key) => switch (this[key]) {
    final bool value => value,
    _ => null,
  };

  /// Convenience getter for the common "is_active" flag.
  bool? get isActive => getBoolFlag(MetadataKeys.isActive);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Structured extractions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
  ({String contextKey, Set<String> allowedValues})? get requiredStatus =>
      switch (this[MetadataKeys.requiredStatus]) {
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Composite condition extractions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Extracts list of condition maps for logical operators (any_of, all_of).
  ///
  /// Returns `null` if key doesn't exist or value is not a list of maps.
  ///
  /// Example:
  /// ```dart
  /// final conditions = payload.getConditionList('any_of');
  /// for (final condition in conditions ?? []) {
  ///   // Process each condition map
  /// }
  /// ```
  List<Map<String, dynamic>>? getConditionList(String key) =>
      switch (this[key]) {
        final List<dynamic> list
            when list.every((e) => e is Map<String, dynamic>) =>
          list.cast<Map<String, dynamic>>(),
        _ => null,
      };

  /// Extracts "any_of" conditions.
  List<Map<String, dynamic>>? get anyOfConditions =>
      getConditionList(MetadataKeys.anyOf);

  /// Extracts "all_of" conditions.
  List<Map<String, dynamic>>? get allOfConditions =>
      getConditionList(MetadataKeys.allOf);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Generic extractions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Safely extracts a value of type [T].
  T? getValue<T>(String key) => switch (this[key]) {
    final T value => value,
    _ => null,
  };

  /// Safely extracts a numeric value.
  num? getNum(String key) => getValue<num>(key);

  /// Safely extracts a string value.
  String? getString(String key) => getValue<String>(key);

  /// Safely extracts a list value.
  List<T>? getList<T>(String key) => getValue<List<T>>(key);

  /// Safely extracts a map value.
  Map<String, dynamic>? getMap(String key) =>
      getValue<Map<String, dynamic>>(key);
}
