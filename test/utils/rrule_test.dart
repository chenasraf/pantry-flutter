import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/rrule.dart';

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

    test('adds an ordinal BYDAY as given', () {
      expect(
        buildRrule(freq: 'monthly', byDay: ['2MO']),
        'FREQ=MONTHLY;BYDAY=2MO',
      );
    });

    test('adds BYMONTHDAY', () {
      expect(
        buildRrule(freq: 'monthly', byMonthDay: [3, 17]),
        'FREQ=MONTHLY;BYMONTHDAY=3,17',
      );
    });

    test('omits empty BYMONTHDAY', () {
      expect(buildRrule(freq: 'monthly', byMonthDay: []), 'FREQ=MONTHLY');
    });

    test('adds a yearly month and day', () {
      expect(
        buildRrule(freq: 'yearly', byMonth: 3, byMonthDay: [15]),
        'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15',
      );
    });
  });

  group('parseByDay', () {
    test('reads a plain weekday', () {
      expect(parseByDay('MO'), (ordinal: null, weekday: 'MO'));
    });

    test('reads a positive ordinal with and without the plus', () {
      expect(parseByDay('+2MO'), (ordinal: 2, weekday: 'MO'));
      expect(parseByDay('2MO'), (ordinal: 2, weekday: 'MO'));
    });

    test('reads a last-of-month weekday', () {
      expect(parseByDay('-1FR'), (ordinal: -1, weekday: 'FR'));
    });

    test('rejects anything that is not a weekday code', () {
      expect(parseByDay('XX'), isNull);
      expect(parseByDay('2'), isNull);
    });

    test('serializes without the plus', () {
      expect(formatByDay((ordinal: 2, weekday: 'MO')), '2MO');
      expect(formatByDay((ordinal: -1, weekday: 'FR')), '-1FR');
      expect(formatByDay((ordinal: null, weekday: 'MO')), 'MO');
    });
  });

  group('sameRrule', () {
    test('an omitted INTERVAL matches an explicit 1', () {
      expect(sameRrule('FREQ=WEEKLY', 'FREQ=WEEKLY;INTERVAL=1'), isTrue);
    });

    test('the optional plus on an ordinal does not change the rule', () {
      expect(
        sameRrule('FREQ=MONTHLY;BYDAY=+2MO', 'FREQ=MONTHLY;BYDAY=2MO'),
        isTrue,
      );
    });

    test('set order does not change the rule', () {
      expect(
        sameRrule(
          'FREQ=MONTHLY;BYMONTHDAY=17,3',
          'FREQ=MONTHLY;BYMONTHDAY=3,17',
        ),
        isTrue,
      );
      expect(
        sameRrule('FREQ=WEEKLY;BYDAY=FR,MO', 'FREQ=WEEKLY;BYDAY=MO,FR'),
        isTrue,
      );
    });

    test('different days are different rules', () {
      expect(
        sameRrule('FREQ=MONTHLY;BYDAY=2MO', 'FREQ=MONTHLY;BYDAY=-1MO'),
        isFalse,
      );
      expect(
        sameRrule('FREQ=MONTHLY;BYMONTHDAY=3', 'FREQ=MONTHLY;BYMONTHDAY=3,17'),
        isFalse,
      );
    });

    test('a null rule matches only another null', () {
      expect(sameRrule(null, null), isTrue);
      expect(sameRrule(null, 'FREQ=WEEKLY'), isFalse);
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

    test('monthly ordinal weekday names the position and the day', () {
      final s = formatRrule('FREQ=MONTHLY;INTERVAL=1;BYDAY=+2MO');
      expect(s, 'Every month on the second Monday');
    });

    test('monthly last weekday reads as "last"', () {
      final s = formatRrule('FREQ=MONTHLY;INTERVAL=1;BYDAY=-1FR');
      expect(s, 'Every month on the last Friday');
    });

    test('monthly days of the month are listed', () {
      expect(
        formatRrule('FREQ=MONTHLY;BYMONTHDAY=3,17'),
        'Every month on days 3, 17',
      );
      expect(formatRrule('FREQ=MONTHLY;BYMONTHDAY=3'), 'Every month on day 3');
    });

    test('yearly date renders in the locale order', () {
      final s = formatRrule('FREQ=YEARLY;INTERVAL=1;BYMONTH=3;BYMONTHDAY=15');
      expect(s, contains('March'));
      expect(s, contains('15'));
      expect(s, startsWith('Every year on '));
    });

    test('yearly leap day survives', () {
      expect(
        formatRrule('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29'),
        contains('29'),
      );
    });

    test('a yearly rule without a date stays bare', () {
      expect(formatRrule('FREQ=YEARLY;INTERVAL=1'), 'Every year');
    });
  });
}
