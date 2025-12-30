/// Generic eligibility framework for evaluating conditions against subjects.
///
/// This library provides a flexible, composable system for determining whether
/// subjects (campaigns, features, users, etc.) are eligible based on various
/// conditions.
///
/// ## Core Concepts
///
/// - **[Eligibility]**: A declarative condition (e.g., time range, user
///   segment)
/// - **[EligibilityRule]**: Evaluates a specific type of eligibility condition
/// - **[EligibilityExtractor]**: Extracts eligibility conditions from a subject
/// - **[EligibilityResolver]**: Orchestrates extraction and evaluation
///
/// ## Example Usage
///
/// ```dart
/// // Define a subject with metadata
/// class Campaign implements HasMetadata {
///   final String id;
///   final Map<String, dynamic> metadata;
///   Campaign(this.id, this.metadata);
/// }
///
/// // Create a resolver with standard rules and extractors
/// final resolver = DefaultEligibilityResolver<Campaign>(
///   rules: createStandardRules(),
///   extractors: [
///     TimeRangeExtractor(),
///     RecurringTimePatternExtractor(),
///     AnySegmentExtractor(),
///   ],
/// );
///
/// // Check eligibility with absolute time range
/// final campaign1 = Campaign('holiday-promo', {
///   'time_range': {
///     'start': '2025-12-01T00:00:00Z',
///     'end': '2025-12-31T23:59:59Z',
///   },
///   'required_segments': ['premium', 'early_adopter'],
/// });
///
/// // Check eligibility with recurring time pattern (business hours)
/// final campaign2 = Campaign('weekday-flash-sale', {
///   'recurring_time_pattern': {
///     'days_of_week': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
///     'time_start': '13:00',
///     'time_end': '17:00',
///   },
/// });
///
/// final context = {
///   'user_segments': {'premium', 'verified'},
/// };
///
/// final isEligible1 = await resolver.isEligible(campaign1, context);
/// final isEligible2 = await resolver.isEligible(campaign2, context);
/// ```
// ignore_for_file: lines_longer_than_80_chars

library;

export 'conditions.dart';
export 'extractors.dart';
export 'metadata_extraction.dart';
export 'metadata_keys.dart';
export 'resolver.dart';
export 'rules.dart';
