import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/rrule.dart';

void main() {
  group('parseRrule', () {
    test('parses simple FREQ=WEEKLY', () {
      final map = parseRrule('FREQ=WEEKLY');
      expect(map['FREQ'], 'WEEKLY');
    });

    test('parses multiple components', () {
      final map = parseRrule('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE');
      expect(map['FREQ'], 'WEEKLY');
      expect(map['INTERVAL'], '2');
      expect(map['BYDAY'], 'MO,WE');
    });

    test('ignores malformed parts', () {
      final map = parseRrule('FREQ=DAILY;BROKEN;INTERVAL=3');
      expect(map['FREQ'], 'DAILY');
      expect(map['INTERVAL'], '3');
      expect(map.containsKey('BROKEN'), false);
    });

    test('empty string yields empty map', () {
      expect(parseRrule(''), isEmpty);
    });
  });

  group('buildRrule', () {
    test('basic daily', () {
      expect(buildRrule(freq: 'daily'), 'FREQ=DAILY');
    });

    test('weekly with interval', () {
      expect(buildRrule(freq: 'weekly', interval: 2), 'FREQ=WEEKLY;INTERVAL=2');
    });

    test('skips interval when 1', () {
      expect(buildRrule(freq: 'monthly', interval: 1), 'FREQ=MONTHLY');
    });

    test('adds BYDAY when provided', () {
      expect(
        buildRrule(freq: 'weekly', byDay: ['MO', 'FR']),
        'FREQ=WEEKLY;BYDAY=MO,FR',
      );
    });

    test('omits empty BYDAY', () {
      expect(buildRrule(freq: 'weekly', byDay: []), 'FREQ=WEEKLY');
    });

    test('adds COUNT', () {
      expect(buildRrule(freq: 'daily', count: 5), 'FREQ=DAILY;COUNT=5');
    });

    test('adds UNTIL', () {
      final until = DateTime(2025, 6, 7);
      expect(
        buildRrule(freq: 'daily', until: until),
        'FREQ=DAILY;UNTIL=20250607T235959Z',
      );
    });

    test('pads month and day', () {
      final until = DateTime(2025, 1, 2);
      expect(
        buildRrule(freq: 'weekly', until: until),
        'FREQ=WEEKLY;UNTIL=20250102T235959Z',
      );
    });

    test('combines all', () {
      final rrule = buildRrule(
        freq: 'weekly',
        interval: 3,
        byDay: ['MO'],
        count: 10,
      );
      expect(rrule, 'FREQ=WEEKLY;INTERVAL=3;BYDAY=MO;COUNT=10');
    });
  });

  group('formatRrule', () {
    test('daily freq contains "day"', () {
      final s = formatRrule('FREQ=DAILY');
      expect(s.toLowerCase(), contains('day'));
    });

    test('weekly freq contains "week"', () {
      final s = formatRrule('FREQ=WEEKLY');
      expect(s.toLowerCase(), contains('week'));
    });

    test('monthly freq contains "month"', () {
      final s = formatRrule('FREQ=MONTHLY');
      expect(s.toLowerCase(), contains('month'));
    });

    test('yearly freq contains "year"', () {
      final s = formatRrule('FREQ=YEARLY');
      expect(s.toLowerCase(), contains('year'));
    });

    test('interval > 1 appears in summary', () {
      final s = formatRrule('FREQ=DAILY;INTERVAL=3');
      expect(s, contains('3'));
    });

    test('weekly with BYDAY includes day names', () {
      final s = formatRrule('FREQ=WEEKLY;BYDAY=MO,FR');
      expect(s, contains('Monday'));
      expect(s, contains('Friday'));
    });

    test('no FREQ returns original', () {
      expect(formatRrule('INTERVAL=2'), 'INTERVAL=2');
    });
  });
}
