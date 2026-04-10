import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/repeat_button.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('shows "not set" when rrule is null', (tester) async {
    await tester.pumpWidget(
      wrapForTest(RepeatButton(rrule: null, onTap: () {})),
    );
    expect(find.text('not set'), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat), findsOneWidget);
  });

  testWidgets('shows "not set" when rrule is empty string', (tester) async {
    await tester.pumpWidget(wrapForTest(RepeatButton(rrule: '', onTap: () {})));
    expect(find.text('not set'), findsOneWidget);
  });

  testWidgets('shows formatted summary when rrule is set', (tester) async {
    await tester.pumpWidget(
      wrapForTest(RepeatButton(rrule: 'FREQ=WEEKLY', onTap: () {})),
    );
    // "every week" from formatRrule
    expect(find.textContaining('week'), findsWidgets);
  });

  testWidgets('tapping calls onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrapForTest(RepeatButton(rrule: 'FREQ=DAILY', onTap: () => tapped++)),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, 1);
  });
}
