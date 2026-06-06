/// Standard metadata field names used across the eligibility system.
///
/// This provides a single source of truth for metadata structure,
/// enabling IDE autocomplete and preventing typos.
extension type const MetadataKeys(String key) implements String {
  /// Logical operator for combining conditions with OR logic.
  static const anyOf = MetadataKeys('any_of');

  /// Logcal operator for combining conditions with AND logic.
  static const allOf = MetadataKeys('all_of');

  /// Time-based condition
  static const timeRange = MetadataKeys('time_range');

  /// Recurring time pattern condition
  static const recurringTimePattern = MetadataKeys('recurring_time_pattern');

  /// Boolean flags
  static const isActive = MetadataKeys('is_active');

  /// Membership and matching conditions
  static const requiredSegments = MetadataKeys('required_segments');

  /// Membership and matching conditions
  static const requiredStatus = MetadataKeys('required_status');

  /// Platform pattern condition
  static const platformPattern = MetadataKeys('platform_pattern');

  /// Minimum version condition
  static const minVersion = MetadataKeys('min_version');

  /// Start time sub-field
  static const start = MetadataKeys('start');

  /// End time sub-field
  static const end = MetadataKeys('end');

  /// Recurring time start sub-field
  static const timeStart = MetadataKeys('time_start');

  /// Recurring time end sub-field
  static const timeEnd = MetadataKeys('time_end');

  /// Days of week sub-field
  static const daysOfWeek = MetadataKeys('days_of_week');

  /// Context key sub-field
  static const contextKey = MetadataKeys('context_key');

  /// Allowed values sub-field
  static const allowedValues = MetadataKeys('allowed_values');

  /// Pattern sub-field
  static const pattern = MetadataKeys('pattern');

  /// Case sensitive sub-field
  static const caseSensitive = MetadataKeys('case_sensitive');

  /// Operator sub-field
  static const operator = MetadataKeys('operator');

  /// Threshold sub-field
  static const threshold = MetadataKeys('threshold');

  /// All metadata keys
  static const all = {
    anyOf,
    allOf,
    timeRange,
    recurringTimePattern,
    isActive,
    requiredSegments,
    requiredStatus,
    platformPattern,
    minVersion,
    start,
    end,
    timeStart,
    timeEnd,
    daysOfWeek,
    contextKey,
    allowedValues,
    pattern,
    caseSensitive,
    operator,
    threshold,
  };

  /// Returns the key with the given suffix.
  String suffix(String suffix) => '$key.$suffix';
}
