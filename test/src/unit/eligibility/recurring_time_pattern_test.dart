import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/eligibility/conditions.dart';
import 'package:presentum/src/eligibility/extractors.dart';
import 'package:presentum/src/eligibility/resolver.dart';
import 'package:presentum/src/eligibility/rules.dart';

void main() {
  group('TimeOfDay', () {
    test('parses HH:mm format correctly', () {
      final time = TimeOfDay.parse('14:30');
      expect(time.hour, 14);
      expect(time.minute, 30);
    });

    test('throws on invalid format', () {
      expect(() => TimeOfDay.parse('25:00'), throwsA(isA<AssertionError>()));
      expect(() => TimeOfDay.parse('14:60'), throwsA(isA<AssertionError>()));
      expect(() => TimeOfDay.parse('14'), throwsFormatException);
      expect(() => TimeOfDay.parse('abc'), throwsFormatException);
    });

    test('calculates minutes since midnight', () {
      expect(TimeOfDay.parse('00:00').minutesSinceMidnight, 0);
      expect(TimeOfDay.parse('01:30').minutesSinceMidnight, 90);
      expect(TimeOfDay.parse('23:59').minutesSinceMidnight, 1439);
    });

    test('compares times correctly', () {
      final morning = TimeOfDay.parse('09:00');
      final afternoon = TimeOfDay.parse('14:00');

      expect(morning.isBefore(afternoon), isTrue);
      expect(afternoon.isBefore(morning), isFalse);
    });

    test('equality works', () {
      final time1 = TimeOfDay.parse('14:30');
      final time2 = TimeOfDay.parse('14:30');
      final time3 = TimeOfDay.parse('14:31');

      expect(time1, equals(time2));
      expect(time1.isAtSameTime(time2), isTrue);
      expect(time1, isNot(equals(time3)));
      expect(time1.isAtSameTime(time3), isFalse);
    });

    test('toString formats correctly', () {
      expect(TimeOfDay.parse('09:05').toString(), '09:05');
      expect(TimeOfDay.parse('14:30').toString(), '14:30');
      expect(TimeOfDay.parse('00:00').toString(), '00:00');
      expect(TimeOfDay.parse('23:59').toString(), '23:59');
    });
  });

  group('DayOfWeek', () {
    test('parses day names correctly', () {
      expect(DayOfWeek.parse('monday'), DayOfWeek.monday);
      expect(DayOfWeek.parse('MONDAY'), DayOfWeek.monday);
      expect(DayOfWeek.parse('Monday'), DayOfWeek.monday);
      expect(DayOfWeek.parse('mon'), DayOfWeek.monday);
    });

    test('throws on invalid day name', () {
      expect(() => DayOfWeek.parse('funday'), throwsArgumentError);
    });

    test('has correct DateTime values', () {
      expect(DayOfWeek.monday.value, DateTime.monday);
      expect(DayOfWeek.sunday.value, DateTime.sunday);
    });
  });

  group('RecurringTimePatternEligibility', () {
    test('detects midnight crossover', () {
      final normal = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
      );

      final crossover = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('22:00'),
        timeEnd: TimeOfDay.parse('02:00'),
      );

      expect(normal.crossesMidnight, isFalse);
      expect(crossover.crossesMidnight, isTrue);
    });

    test('equality works', () {
      final pattern1 = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
        daysOfWeek: const {DayOfWeek.monday, DayOfWeek.friday},
      );

      final pattern2 = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
        daysOfWeek: const {
          DayOfWeek.friday,
          DayOfWeek.monday,
        }, // Order doesn't matter
      );

      final pattern3 = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('18:00'), // Different end time
        daysOfWeek: const {DayOfWeek.monday, DayOfWeek.friday},
      );

      expect(pattern1, equals(pattern2));
      expect(pattern1, isNot(equals(pattern3)));
    });

    test('toString is readable', () {
      final pattern = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
        daysOfWeek: const {DayOfWeek.monday, DayOfWeek.friday},
      );

      expect(pattern.toString(), contains('09:00'));
      expect(pattern.toString(), contains('17:00'));
    });
  });

  group('RecurringTimePatternRule', () {
    test('matches during specified time range', () async {
      final rule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 14, 30), // Saturday 2:30pm
      );

      final eligibility = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('13:00'),
        timeEnd: TimeOfDay.parse('17:00'),
      );

      final result = await rule.evaluate(eligibility, {});
      expect(result, isTrue);
    });

    test('rejects outside time range', () async {
      final rule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 10, 0), // Saturday 10:00am
      );

      final eligibility = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('13:00'),
        timeEnd: TimeOfDay.parse('17:00'),
      );

      final result = await rule.evaluate(eligibility, {});
      expect(result, isFalse);
    });

    test('matches on specified days of week', () async {
      final mondayRule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 22, 14, 0), // Monday 2pm
      );

      final saturdayRule = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 14, 0), // Saturday 2pm
      );

      final weekdayPattern = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
        daysOfWeek: const {
          DayOfWeek.monday,
          DayOfWeek.tuesday,
          DayOfWeek.wednesday,
          DayOfWeek.thursday,
          DayOfWeek.friday,
        },
      );

      expect(await mondayRule.evaluate(weekdayPattern, {}), isTrue);
      expect(await saturdayRule.evaluate(weekdayPattern, {}), isFalse);
    });

    test('handles midnight crossover correctly', () async {
      final eligibility = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('22:00'), // 10pm
        timeEnd: TimeOfDay.parse('02:00'), // 2am
      );

      // Test at 11pm - should match
      final rule11pm = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 23, 0),
      );
      expect(await rule11pm.evaluate(eligibility, {}), isTrue);

      // Test at 1am - should match
      final rule1am = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 1, 0),
      );
      expect(await rule1am.evaluate(eligibility, {}), isTrue);

      // Test at 5pm - should not match
      final rule5pm = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 17, 0),
      );
      expect(await rule5pm.evaluate(eligibility, {}), isFalse);

      // Test at 3am - should not match (after 2am)
      final rule3am = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 3, 0),
      );
      expect(await rule3am.evaluate(eligibility, {}), isFalse);
    });

    test('handles edge cases at boundary times', () async {
      final eligibility = RecurringTimePatternEligibility(
        timeStart: TimeOfDay.parse('09:00'),
        timeEnd: TimeOfDay.parse('17:00'),
      );

      // Test at start time (inclusive) - should match
      final ruleStart = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 9, 0),
      );
      expect(await ruleStart.evaluate(eligibility, {}), isTrue);

      // Test at end time (exclusive) - should not match
      final ruleEnd = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 17, 0),
      );
      expect(await ruleEnd.evaluate(eligibility, {}), isFalse);

      // Test one minute before end - should match
      final ruleBeforeEnd = RecurringTimePatternRule(
        timeProvider: () => DateTime(2025, 12, 27, 16, 59),
      );
      expect(await ruleBeforeEnd.evaluate(eligibility, {}), isTrue);
    });
  });

  group('RecurringTimePatternExtractor', () {
    test('extracts basic pattern from metadata', () {
      final subject = _TestSubject({
        'recurring_time_pattern': {'time_start': '13:00', 'time_end': '17:00'},
      });

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      expect(extractor.supports(subject), isTrue);

      final conditions = extractor.extract(subject).toList();
      expect(conditions, hasLength(1));

      final condition = conditions.first as RecurringTimePatternEligibility;
      expect(condition.timeStart, TimeOfDay.parse('13:00'));
      expect(condition.timeEnd, TimeOfDay.parse('17:00'));
      expect(condition.daysOfWeek, isEmpty);
    });

    test('extracts pattern with days of week', () {
      final subject = _TestSubject({
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

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      final conditions = extractor.extract(subject).toList();
      final condition = conditions.first as RecurringTimePatternEligibility;

      expect(condition.daysOfWeek, hasLength(5));
      expect(condition.daysOfWeek, contains(DayOfWeek.monday));
      expect(condition.daysOfWeek, contains(DayOfWeek.friday));
      expect(condition.daysOfWeek, isNot(contains(DayOfWeek.saturday)));
    });

    test('throws on invalid time format', () {
      final subject = _TestSubject({
        'recurring_time_pattern': {
          'time_start': 'invalid',
          'time_end': '17:00',
        },
      });

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      expect(
        () => extractor.extract(subject),
        throwsA(isA<MalformedMetadataException>()),
      );
    });

    test('throws when time_start equals time_end', () {
      final subject = _TestSubject({
        'recurring_time_pattern': {'time_start': '14:00', 'time_end': '14:00'},
      });

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      expect(
        () => extractor.extract(subject),
        throwsA(isA<MalformedMetadataException>()),
      );
    });

    test('throws on invalid day name', () {
      final subject = _TestSubject({
        'recurring_time_pattern': {
          'time_start': '09:00',
          'time_end': '17:00',
          'days_of_week': ['monday', 'funday'],
        },
      });

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      expect(
        () => extractor.extract(subject),
        throwsA(isA<MalformedMetadataException>()),
      );
    });

    test('throws on malformed metadata structure', () {
      final subject = _TestSubject({'recurring_time_pattern': 'invalid'});

      const extractor = RecurringTimePatternExtractor<_TestSubject>();
      expect(
        () => extractor.extract(subject),
        throwsA(isA<MalformedMetadataException>()),
      );
    });
  });
}

class _TestSubject implements HasMetadata {
  _TestSubject(this.metadata);

  @override
  final Map<String, dynamic> metadata;
}
