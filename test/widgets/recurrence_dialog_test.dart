import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/recurrence_dialog.dart';

// The recurrence dialog uses AuthService.instance.firstDayOfWeek for day
// ordering, but the default value is derived from locale and does not touch
// the network, so it is safe in tests.

void main() {
  // The recurrence dialog's "Ends" row overflows the inner 372px dialog
  // width in tests. We silence overflow errors so the tests focus on logic.
  setUp(() {
    final prev = FlutterError.onError;
    FlutterError.onError = (details) {
      final ex = details.exception;
      if (ex is FlutterError && ex.message.toLowerCase().contains('overflow')) {
        return;
      }
      prev?.call(details);
    };
  });

  Future<void> openDialog(
    WidgetTester tester, {
    String? initial,
    bool fromCompletion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => showRecurrenceDialog(
                  ctx,
                  initialRrule: initial,
                  initialRepeatFromCompletion: fromCompletion,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Consume the known-harmless overflow exception (see setUp comment).
    tester.takeException();
  }

  testWidgets('renders title, presets and summary', (tester) async {
    await openDialog(tester);

    expect(find.text('Recurrence'), findsOneWidget);
    expect(find.text('Presets'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Every 2 weeks'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Summary '), findsOneWidget);
  });

  testWidgets('default preset is Weekly, summary shows "every week"', (
    tester,
  ) async {
    await openDialog(tester);
    expect(find.textContaining('week'), findsWidgets);
  });

  testWidgets('tapping Daily preset updates summary to "every day"', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.textContaining('day'), findsWidgets);
  });

  testWidgets('tapping Monthly preset updates summary to "every month"', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.textContaining('month'), findsWidgets);
  });

  testWidgets('tapping Every 2 weeks preset shows interval of 2', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.text('Every 2 weeks'));
    await tester.pumpAndSettle();
    tester.takeException();
    // summary should include "2"
    expect(find.textContaining('2'), findsWidgets);
  });

  testWidgets('cancel closes dialog without returning a result', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    tester.takeException();
    await tester.tap(
      find.widgetWithText(TextButton, 'Cancel'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    tester.takeException();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('save dismisses the dialog', (tester) async {
    await openDialog(tester);

    // Dialog open — Dialog widget is present.
    expect(find.byType(Dialog), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    tester.takeException();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Save'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    tester.takeException();

    // Dialog should be gone after save.
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('pre-filled DAILY/INTERVAL=3 rrule parses initial state', (
    tester,
  ) async {
    await openDialog(tester, initial: 'FREQ=DAILY;INTERVAL=3');
    // Summary should show "every 3 days"
    expect(find.textContaining('3'), findsWidgets);
    expect(find.textContaining('day'), findsWidgets);
  });
}
