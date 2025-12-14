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
///     AnySegmentExtractor(),
///   ],
/// );
///
/// // Check eligibility
/// final campaign = Campaign('promo-2025', {
///   'time_range': {
///     'start': '2025-12-01T00:00:00Z',
///     'end': '2025-12-31T23:59:59Z',
///   },
///   'required_segments': ['premium', 'early_adopter'],
/// });
///
/// final context = {
///   'user_segments': {'premium', 'verified'},
/// };
///
/// final isEligible = await resolver.isEligible(campaign, context);
/// ```
library;

export 'conditions.dart';
export 'extractors.dart';
export 'resolver.dart';
export 'rules.dart';
