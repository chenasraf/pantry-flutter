import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry/widgets/recurrence_parts.dart';

void main() {
  group('RecurrenceState round trip', () {
    void expectRoundTrip(String rrule) {
      final rebuilt = RecurrenceState.fromRrule(rrule).toRrule();
      expect(
        sameRrule(rebuilt, rrule),
        isTrue,
        reason: '$rrule came back as $rebuilt',
      );
    }

    test('keeps a weekly rule', () {
      expectRoundTrip('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,FR');
    });

    test('keeps a monthly ordinal weekday', () {
      expectRoundTrip('FREQ=MONTHLY;INTERVAL=1;BYDAY=+2MO');
      expectRoundTrip('FREQ=MONTHLY;INTERVAL=1;BYDAY=-1FR');
    });

    test('keeps days of the month', () {
      expectRoundTrip('FREQ=MONTHLY;BYMONTHDAY=3,17');
    });

    test('keeps a yearly date', () {
      expectRoundTrip('FREQ=YEARLY;INTERVAL=1;BYMONTH=3;BYMONTHDAY=15');
    });

    test('keeps the leap day', () {
      expectRoundTrip('FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29');
    });

    test('keeps an end condition', () {
      expectRoundTrip('FREQ=DAILY;COUNT=5');
      expectRoundTrip('FREQ=DAILY;UNTIL=20250607T235959Z');
    });

    test('keeps parts no editor owns', () {
      expectRoundTrip('FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2;WKST=SU');
    });

    test('an empty rule starts weekly', () {
      expect(RecurrenceState.fromRrule(null).toRrule(), 'FREQ=WEEKLY');
    });
  });

  group('RecurrenceState parsing', () {
    test('reads the pinned position of a monthly weekday', () {
      final state = RecurrenceState.fromRrule('FREQ=MONTHLY;BYDAY=-1FR');
      expect(state.monthlyMode, RecurrenceMonthlyMode.weekday);
      expect(state.ordinal, -1);
      expect(state.ordinalWeekday, 'FR');
      expect(state.byDay, isEmpty);
    });

    test('reads a yearly date onto the anchor year', () {
      final state = RecurrenceState.fromRrule(
        'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15',
      );
      expect(state.yearlyDate, DateTime(kYearlessAnchorYear, 3, 15));
      expect(state.monthDays, isEmpty);
    });

    test('reads days of the month only for a monthly rule', () {
      final state = RecurrenceState.fromRrule('FREQ=MONTHLY;BYMONTHDAY=3,17');
      expect(state.monthlyMode, RecurrenceMonthlyMode.days);
      expect(state.monthDays, {3, 17});
    });
  });

  group('RecurrenceState clearing', () {
    test('changing frequency drops the previous shape', () {
      final state = RecurrenceState.fromRrule('FREQ=MONTHLY;BYMONTHDAY=3,17');
      state.setFreq('YEARLY');
      expect(state.monthDays, isEmpty);
      expect(state.toRrule(), 'FREQ=YEARLY');
    });

    test('changing monthly mode drops the other selection', () {
      final state = RecurrenceState.fromRrule('FREQ=MONTHLY;BYMONTHDAY=3,17');
      state.setMonthlyMode(RecurrenceMonthlyMode.weekday);
      expect(state.monthDays, isEmpty);
      expect(state.toRrule(), 'FREQ=MONTHLY;BYDAY=1MO');

      state.ordinal = 3;
      state.ordinalWeekday = 'WE';
      state.setMonthlyMode(RecurrenceMonthlyMode.days);
      expect(state.ordinal, 1);
      expect(state.ordinalWeekday, 'MO');
      expect(state.toRrule(), 'FREQ=MONTHLY');
    });

    test('re-selecting the same frequency keeps the selection', () {
      final state = RecurrenceState.fromRrule('FREQ=WEEKLY;BYDAY=MO,FR');
      state.setFreq('WEEKLY');
      expect(state.byDay, {'MO', 'FR'});
    });
  });
}
