import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/eligibility/conditions.dart';
import 'package:presentum/src/eligibility/metadata_extraction.dart';
import 'package:presentum/src/eligibility/metadata_keys.dart';

void main() {
  group('MetadataExtraction', () {
    group('timeRange', () {
      test('extracts valid time range', () {
        final metadata = <String, dynamic>{
          'time_range': {
            'start': '2025-12-28T00:00:00Z',
            'end': '2025-12-28T16:28:00Z',
          },
        };

        final result = metadata.timeRange();

        expect(result, isNotNull);
        expect(result!.start, DateTime.parse('2025-12-28T00:00:00Z'));
        expect(result.end, DateTime.parse('2025-12-28T16:28:00Z'));
      });

      test('returns null when time_range is missing', () {
        final metadata = <String, dynamic>{};
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when time_range is not a map', () {
        final metadata = <String, dynamic>{'time_range': 'invalid'};
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when start is missing', () {
        final metadata = <String, dynamic>{
          'time_range': {'end': '2025-12-28T16:28:00Z'},
        };
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when end is missing', () {
        final metadata = <String, dynamic>{
          'time_range': {'start': '2025-12-28T00:00:00Z'},
        };
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when start is invalid date string', () {
        final metadata = <String, dynamic>{
          'time_range': {'start': 'not-a-date', 'end': '2025-12-28T16:28:00Z'},
        };
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when end is invalid date string', () {
        final metadata = <String, dynamic>{
          'time_range': {'start': '2025-12-28T00:00:00Z', 'end': 'not-a-date'},
        };
        expect(metadata.timeRange(), isNull);
      });

      test('returns null when start is after end', () {
        final metadata = <String, dynamic>{
          'time_range': {
            'start': '2025-12-28T16:28:00Z',
            'end': '2025-12-28T00:00:00Z',
          },
        };
        expect(metadata.timeRange(), isNull);
      });

      test('handles different date formats', () {
        final metadata = <String, dynamic>{
          'time_range': {'start': '2025-12-28', 'end': '2025-12-29'},
        };

        final result = metadata.timeRange();
        expect(result, isNotNull);
        expect(result!.start.year, 2025);
        expect(result.start.month, 12);
        expect(result.start.day, 28);
      });
    });

    group('timeUntilEnd', () {
      test('returns duration when current time is within range', () {
        final now = DateTime.now();
        final start = now.subtract(const Duration(hours: 1));
        final end = now.add(const Duration(hours: 1));

        final metadata = <String, dynamic>{
          'time_range': {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        };

        final result = metadata.timeUntilEnd();
        expect(result, isNotNull);
        expect(
          result!.inMinutes,
          greaterThan(55),
        ); // ~1 hour minus test execution time
        expect(result.inMinutes, lessThanOrEqualTo(60));
      });

      test('returns null when no time range', () {
        final metadata = <String, dynamic>{};
        expect(metadata.timeUntilEnd(), isNull);
      });
    });

    group('isWithinTimeRange', () {
      test('returns true when current time is within range', () {
        final now = DateTime.now();
        final start = now.subtract(const Duration(hours: 1));
        final end = now.add(const Duration(hours: 1));

        final metadata = <String, dynamic>{
          'time_range': {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        };

        expect(metadata.isWithinTimeRange(), isTrue);
      });

      test('returns false when no time range', () {
        final metadata = <String, dynamic>{};
        expect(metadata.isWithinTimeRange(), isFalse);
      });

      test('returns false when current time is before range', () {
        final now = DateTime.now();
        final start = now.add(const Duration(hours: 1));
        final end = now.add(const Duration(hours: 2));

        final metadata = <String, dynamic>{
          'time_range': {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        };

        expect(metadata.isWithinTimeRange(), isFalse);
      });

      test('returns false when current time is after range', () {
        final now = DateTime.now();
        final start = now.subtract(const Duration(hours: 2));
        final end = now.subtract(const Duration(hours: 1));

        final metadata = <String, dynamic>{
          'time_range': {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        };

        expect(metadata.isWithinTimeRange(), isFalse);
      });
    });

    group('recurringTimePattern', () {
      test('extracts valid recurring pattern with days', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {
            'time_start': '09:00',
            'time_end': '17:00',
            'days_of_week': ['monday', 'friday'],
          },
        };

        final result = metadata.recurringTimePattern();

        expect(result, isNotNull);
        expect(result!.timeStart, const TimeOfDay(hour: 9, minute: 0));
        expect(result.timeEnd, const TimeOfDay(hour: 17, minute: 0));
        expect(result.daysOfWeek, isNotNull);
        expect(result.daysOfWeek!.length, 2);
        expect(result.daysOfWeek!.contains(DayOfWeek.monday), isTrue);
        expect(result.daysOfWeek!.contains(DayOfWeek.friday), isTrue);
      });

      test('extracts valid recurring pattern without days', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {
            'time_start': '09:00',
            'time_end': '17:00',
          },
        };

        final result = metadata.recurringTimePattern();

        expect(result, isNotNull);
        expect(result!.timeStart, const TimeOfDay(hour: 9, minute: 0));
        expect(result.timeEnd, const TimeOfDay(hour: 17, minute: 0));
        expect(result.daysOfWeek, isNull);
      });

      test('returns null when recurring_time_pattern is missing', () {
        final metadata = <String, dynamic>{};
        expect(metadata.recurringTimePattern(), isNull);
      });

      test('returns null when time_start is missing', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {'time_end': '17:00'},
        };
        expect(metadata.recurringTimePattern(), isNull);
      });

      test('returns null when time_end is missing', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {'time_start': '09:00'},
        };
        expect(metadata.recurringTimePattern(), isNull);
      });

      test('returns null when time_start is invalid', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {
            'time_start': 'invalid',
            'time_end': '17:00',
          },
        };
        expect(metadata.recurringTimePattern(), isNull);
      });

      test('returns null when time_end is invalid', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {
            'time_start': '09:00',
            'time_end': 'invalid',
          },
        };
        expect(metadata.recurringTimePattern(), isNull);
      });

      test('returns null when start equals end', () {
        final metadata = <String, dynamic>{
          'recurring_time_pattern': {
            'time_start': '09:00',
            'time_end': '09:00',
          },
        };
        expect(metadata.recurringTimePattern(), isNull);
      });
    });

    group('getBoolFlag', () {
      test('extracts true boolean', () {
        final metadata = <String, dynamic>{'is_active': true};
        expect(metadata.getBoolFlag('is_active'), isTrue);
      });

      test('extracts false boolean', () {
        final metadata = <String, dynamic>{'is_active': false};
        expect(metadata.getBoolFlag('is_active'), isFalse);
      });

      test('returns null when key is missing', () {
        final metadata = <String, dynamic>{};
        expect(metadata.getBoolFlag('is_active'), isNull);
      });

      test('returns null when value is not a boolean', () {
        final metadata = <String, dynamic>{'is_active': 'true'};
        expect(metadata.getBoolFlag('is_active'), isNull);
      });

      test('returns null when value is number', () {
        final metadata = <String, dynamic>{'is_active': 1};
        expect(metadata.getBoolFlag('is_active'), isNull);
      });
    });

    group('isActive', () {
      test('extracts is_active flag', () {
        final metadata = <String, dynamic>{MetadataKeys.isActive: true};
        expect(metadata.isActive, isTrue);
      });

      test('returns null when is_active is missing', () {
        final metadata = <String, dynamic>{};
        expect(metadata.isActive, isNull);
      });
    });

    group('requiredStatus', () {
      test('extracts valid required status', () {
        final metadata = <String, dynamic>{
          'required_status': {
            'context_key': 'user_status',
            'allowed_values': ['active', 'trial'],
          },
        };

        final result = metadata.requiredStatus();

        expect(result, isNotNull);
        expect(result!.contextKey, 'user_status');
        expect(result.allowedValues, {'active', 'trial'});
      });

      test('returns null when required_status is missing', () {
        final metadata = <String, dynamic>{};
        expect(metadata.requiredStatus(), isNull);
      });

      test('returns null when context_key is missing', () {
        final metadata = <String, dynamic>{
          'required_status': {
            'allowed_values': ['active', 'trial'],
          },
        };
        expect(metadata.requiredStatus(), isNull);
      });

      test('returns null when allowed_values is missing', () {
        final metadata = <String, dynamic>{
          'required_status': {'context_key': 'user_status'},
        };
        expect(metadata.requiredStatus(), isNull);
      });

      test('returns null when allowed_values is not all strings', () {
        final metadata = <String, dynamic>{
          'required_status': {
            'context_key': 'user_status',
            'allowed_values': ['active', 123],
          },
        };
        expect(metadata.requiredStatus(), isNull);
      });

      test('handles single allowed value', () {
        final metadata = <String, dynamic>{
          'required_status': {
            'context_key': 'user_status',
            'allowed_values': ['active'],
          },
        };

        final result = metadata.requiredStatus();
        expect(result, isNotNull);
        expect(result!.allowedValues, {'active'});
      });
    });

    group('getValue', () {
      test('extracts String value', () {
        final metadata = <String, dynamic>{'key': 'value'};
        expect(metadata.getValue<String>('key'), 'value');
      });

      test('extracts num value', () {
        final metadata = <String, dynamic>{'key': 42};
        expect(metadata.getValue<num>('key'), 42);
      });

      test('extracts bool value', () {
        final metadata = <String, dynamic>{'key': true};
        expect(metadata.getValue<bool>('key'), true);
      });

      test('extracts List<dynamic> value', () {
        final metadata = <String, dynamic>{
          'key': [1, 2, 3],
        };
        expect(metadata.getValue<List<dynamic>>('key'), [1, 2, 3]);
      });

      test('extracts Map<String, dynamic> value', () {
        final metadata = <String, dynamic>{
          'key': {'nested': 'value'},
        };
        expect(metadata.getValue<Map<String, dynamic>>('key'), {
          'nested': 'value',
        });
      });

      test('returns null for missing key', () {
        final metadata = <String, dynamic>{};
        expect(metadata.getValue<String>('missing'), isNull);
      });
    });

    group('getNum', () {
      test('extracts integer', () {
        final metadata = <String, dynamic>{'count': 42};
        expect(metadata.getNum('count'), 42);
      });

      test('extracts double', () {
        final metadata = <String, dynamic>{'price': 19.99};
        expect(metadata.getNum('price'), 19.99);
      });

      test('returns null for missing key', () {
        final metadata = <String, dynamic>{};
        expect(metadata.getNum('missing'), isNull);
      });
    });

    group('getList', () {
      test('extracts list of strings', () {
        final metadata = <String, dynamic>{
          'items': ['a', 'b', 'c'],
        };
        expect(metadata.getList<String>('items'), ['a', 'b', 'c']);
      });

      test('extracts list of numbers', () {
        final metadata = <String, dynamic>{
          'numbers': [1, 2, 3],
        };
        expect(metadata.getList<int>('numbers'), [1, 2, 3]);
      });

      test('extracts mixed list', () {
        final metadata = <String, dynamic>{
          'mixed': [1, 'two', true],
        };
        expect(metadata.getList<dynamic>('mixed'), [1, 'two', true]);
      });

      test('returns null for missing key', () {
        final metadata = <String, dynamic>{};
        expect(metadata.getList<String>('missing'), isNull);
      });
    });

    group('getMap', () {
      test('extracts map', () {
        final metadata = <String, dynamic>{
          'config': {'setting': 'value'},
        };
        expect(metadata.getMap('config'), {'setting': 'value'});
      });

      test('extracts nested map', () {
        final metadata = <String, dynamic>{
          'config': {
            'nested': {'deep': 'value'},
          },
        };
        final result = metadata.getMap('config');
        expect(result, isNotNull);
        expect(result!['nested'], isA<Map<String, dynamic>>());
      });

      test('returns null for missing key', () {
        final metadata = <String, dynamic>{};
        expect(metadata.getMap('missing'), isNull);
      });
    });

    group('maybeGetNested', () {
      test('extracts from nested any_of structure', () {
        final metadata = <String, dynamic>{
          'any_of': [
            {
              'time_range': {
                'start': '2025-12-28T00:00:00Z',
                'end': '2025-12-28T16:28:00Z',
              },
            },
          ],
        };

        final result = metadata.maybeGetNested(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
        expect(result!.start, DateTime.parse('2025-12-28T00:00:00Z'));
      });

      test('returns first non-null result from multiple conditions', () {
        final metadata = <String, dynamic>{
          'any_of': [
            {'is_active': false},
            {
              'time_range': {
                'start': '2025-12-28T00:00:00Z',
                'end': '2025-12-28T16:28:00Z',
              },
            },
          ],
        };

        final result = metadata.maybeGetNested(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
      });

      test('returns null when nested key is missing', () {
        final metadata = <String, dynamic>{};
        final result = metadata.maybeGetNested(
          'any_of',
          (map) => map.timeRange(),
        );
        expect(result, isNull);
      });

      test('returns null when all nested values are null', () {
        final metadata = <String, dynamic>{
          'any_of': [
            {'is_active': true},
            {'other': 'value'},
          ],
        };

        final result = metadata.maybeGetNested(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNull);
      });
    });

    group('maybeGetNestedOrFlat', () {
      test('extracts from nested structure first', () {
        final metadata = <String, dynamic>{
          'time_range': {
            'start': '2025-12-28T00:00:00Z',
            'end': '2025-12-28T12:00:00Z',
          },
          'any_of': [
            {
              'time_range': {
                'start': '2025-12-29T00:00:00Z',
                'end': '2025-12-29T16:28:00Z',
              },
            },
          ],
        };

        final result = metadata.maybeGetNestedOrFlat(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
        // Should get nested value (Dec 29)
        expect(result!.start.day, 29);
      });

      test('falls back to flat structure', () {
        final metadata = <String, dynamic>{
          'time_range': {
            'start': '2025-12-28T00:00:00Z',
            'end': '2025-12-28T16:28:00Z',
          },
        };

        final result = metadata.maybeGetNestedOrFlat(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
        expect(result!.start.day, 28);
      });

      test('returns null when both nested and flat are missing', () {
        final metadata = <String, dynamic>{};
        final result = metadata.maybeGetNestedOrFlat(
          'any_of',
          (map) => map.timeRange(),
        );
        expect(result, isNull);
      });
    });

    group('maybeGetFlatOrNested', () {
      test('extracts from flat structure first', () {
        final metadata = <String, dynamic>{
          'time_range': {
            'start': '2025-12-28T00:00:00Z',
            'end': '2025-12-28T16:28:00Z',
          },
          'any_of': [
            {
              'time_range': {
                'start': '2025-12-29T00:00:00Z',
                'end': '2025-12-29T12:00:00Z',
              },
            },
          ],
        };

        final result = metadata.maybeGetFlatOrNested(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
        // Should get flat value (Dec 28)
        expect(result!.start.day, 28);
      });

      test('falls back to nested structure', () {
        final metadata = <String, dynamic>{
          'any_of': [
            {
              'time_range': {
                'start': '2025-12-28T00:00:00Z',
                'end': '2025-12-28T16:28:00Z',
              },
            },
          ],
        };

        final result = metadata.maybeGetFlatOrNested(
          'any_of',
          (map) => map.timeRange(),
        );

        expect(result, isNotNull);
        expect(result!.start.day, 28);
      });

      test('returns null when both flat and nested are missing', () {
        final metadata = <String, dynamic>{};
        final result = metadata.maybeGetFlatOrNested(
          'any_of',
          (map) => map.timeRange(),
        );
        expect(result, isNull);
      });
    });
  });
}
