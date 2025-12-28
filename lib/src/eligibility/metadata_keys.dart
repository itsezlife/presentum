/// Standard metadata field names used across the eligibility system.
///
/// This provides a single source of truth for metadata structure,
/// enabling IDE autocomplete and preventing typos.
extension type MetadataKeys(String key) {
  /// Logical operator for combining conditions with OR logic.
  static const anyOf = 'any_of';

  /// Logcal operator for combining conditions with AND logic.
  static const allOf = 'all_of';

  /// Time-based condition
  static const timeRange = 'time_range';

  /// Recurring time pattern condition
  static const recurringTimePattern = 'recurring_time_pattern';

  /// Boolean flags
  static const isActive = 'is_active';

  /// Membership and matching conditions
  static const requiredSegments = 'required_segments';

  /// Membership and matching conditions
  static const requiredStatus = 'required_status';

  /// Platform pattern condition
  static const platformPattern = 'platform_pattern';

  /// Minimum version condition
  static const minVersion = 'min_version';

  /// Start time sub-field
  static const start = 'start';

  /// End time sub-field
  static const end = 'end';

  /// Recurring time start sub-field
  static const timeStart = 'time_start';

  /// Recurring time end sub-field
  static const timeEnd = 'time_end';

  /// Days of week sub-field
  static const daysOfWeek = 'days_of_week';

  /// Context key sub-field
  static const contextKey = 'context_key';

  /// Allowed values sub-field
  static const allowedValues = 'allowed_values';

  /// Pattern sub-field
  static const pattern = 'pattern';

  /// Case sensitive sub-field
  static const caseSensitive = 'case_sensitive';

  /// Operator sub-field
  static const operator = 'operator';

  /// Threshold sub-field
  static const threshold = 'threshold';

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
