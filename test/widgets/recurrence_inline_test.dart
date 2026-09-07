import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/form_components.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpPanel(WidgetTester tester, RecurrenceState state) async {
    await tester.pumpWidget(
      wrapForTest(
        StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: RecurrenceInline(
              state: state,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('weekly shows the weekday chips only', (tester) async {
    await pumpPanel(tester, RecurrenceState());
    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Days of the month'), findsNothing);
    expect(find.text('Date'), findsNothing);
  });

  testWidgets('monthly offers both repeat-on modes', (tester) async {
    await pumpPanel(tester, RecurrenceState.fromRrule('FREQ=MONTHLY'));
    expect(find.text('Days of the month'), findsOneWidget);
    expect(find.text('A weekday of the month'), findsOneWidget);
  });

  testWidgets('picking a day of the month writes BYMONTHDAY', (tester) async {
    final state = RecurrenceState.fromRrule('FREQ=MONTHLY');
    await pumpPanel(tester, state);

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();

    expect(state.monthDays, {17});
    expect(state.toRrule(), 'FREQ=MONTHLY;BYMONTHDAY=17');
  });

  testWidgets('an ordinal weekday rule opens on its own mode', (tester) async {
    final state = RecurrenceState.fromRrule('FREQ=MONTHLY;BYDAY=-1FR');
    await pumpPanel(tester, state);

    expect(find.text('Last'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Days of the month'), findsOneWidget);
    expect(state.toRrule(), 'FREQ=MONTHLY;BYDAY=-1FR');
  });

  testWidgets('yearly offers a date, and keeps the one it was given', (
    tester,
  ) async {
    final state = RecurrenceState.fromRrule(
      'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15',
    );
    await pumpPanel(tester, state);

    expect(find.text('Date'), findsOneWidget);
    expect(find.textContaining('March'), findsOneWidget);
    expect(state.toRrule(), 'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15');
  });

  testWidgets('clearing the yearly date falls back to the same date', (
    tester,
  ) async {
    final state = RecurrenceState.fromRrule(
      'FREQ=YEARLY;BYMONTH=3;BYMONTHDAY=15',
    );
    await pumpPanel(tester, state);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(state.yearlyDate, isNull);
    expect(state.toRrule(), 'FREQ=YEARLY');
  });
}
