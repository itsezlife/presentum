import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/eligibility/eligibility.dart';

void main() {
  group('RecurringTimePatternEligibility Integration Tests', () {
    test('complete workflow: business hours promotion', () async {
      // Setup: Campaign that runs Monday-Friday 9am-5pm
      final campaign = _TestSubject({
        'recurring_time_pattern': {
          'time_start': '09:00',
          'time_end': '17:00',
          'days_of_week': [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
          ],
        },
      });

      // Test during business hours on Monday
      final mondayRule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 22, 14, 0), // Monday 2pm
      );
      final resolverMonday = DefaultEligibilityResolver<_TestSubject>(
        rules: [mondayRule],
        extractors: [const RecurringTimePatternExtractor()],
      );
      expect(await resolverMonday.isEligible(campaign, {}), isTrue);

      // Test outside business hours on Saturday
      final saturdayRule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 14, 0), // Saturday 2pm
      );
      final resolverSaturday = DefaultEligibilityResolver<_TestSubject>(
        rules: [saturdayRule],
        extractors: [const RecurringTimePatternExtractor()],
      );
      expect(await resolverSaturday.isEligible(campaign, {}), isFalse);
    });

    test('complete workflow: night owl promotion (crosses midnight)', () async {
      // Setup: Campaign that runs every day 10pm-2am
      final campaign = _TestSubject({
        'recurring_time_pattern': {'time_start': '22:00', 'time_end': '02:00'},
      });

      // Test at 11pm - should be eligible
      final rule11pm = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 23, 30),
      );
      final resolver11pm = DefaultEligibilityResolver<_TestSubject>(
        rules: [rule11pm],
        extractors: [const RecurringTimePatternExtractor()],
      );
      expect(await resolver11pm.isEligible(campaign, {}), isTrue);

      // Test at 1am - should be eligible
      final rule1am = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 28, 1, 0),
      );
      final resolver1am = DefaultEligibilityResolver<_TestSubject>(
        rules: [rule1am],
        extractors: [const RecurringTimePatternExtractor()],
      );
      expect(await resolver1am.isEligible(campaign, {}), isTrue);

      // Test at 3pm - should not be eligible
      final rule3pm = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 15, 0),
      );
      final resolver3pm = DefaultEligibilityResolver<_TestSubject>(
        rules: [rule3pm],
        extractors: [const RecurringTimePatternExtractor()],
      );
      expect(await resolver3pm.isEligible(campaign, {}), isFalse);
    });
  });
}

class _TestSubject implements HasMetadata {
  _TestSubject(this.metadata);

  @override
  final Map<String, dynamic> metadata;
}
