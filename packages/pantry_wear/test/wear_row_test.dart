import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/wear_metrics.dart';
import 'package:pantry_wear/src/widgets/wear_row.dart';

/// A row that cannot act, and how it says so.
///
/// Going quiet is the failure mode worth guarding: a card that still looks like
/// a target and swallows every tap reads as a broken app rather than a held
/// write, and on a wrist there is no cursor to reveal otherwise.
void main() {
  setUp(() => WearShape.markFrom(const ['round']));

  Future<WearRow> pump(
    WidgetTester tester, {
    String? reason,
    String? value,
    required VoidCallback onTap,
  }) async {
    final row = WearRow(
      icon: Icons.done_all,
      label: 'Finish trip',
      value: value,
      reason: reason,
      onTap: onTap,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: WearMetrics.unscaled.cardHeight,
              child: row,
            ),
          ),
        ),
      ),
    );
    return row;
  }

  testWidgets('a reason is said in place, and swallows no tap silently', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, reason: 'Needs a connection', onTap: () => taps++);

    expect(find.text('Needs a connection'), findsOneWidget);

    await tester.tap(find.text('Finish trip'));
    await tester.pump();
    expect(taps, 0, reason: 'the reason is what disables it');
  });

  testWidgets('the reason takes the value line, which has nothing to say yet', (
    tester,
  ) async {
    await pump(
      tester,
      reason: 'Needs a connection',
      value: r'$12.50',
      onTap: () {},
    );

    // One line under the label, and while a row is refusing, why it refuses is
    // the more useful of the two.
    expect(find.text('Needs a connection'), findsOneWidget);
    expect(find.text(r'$12.50'), findsNothing);
  });

  testWidgets('without one the row acts and answers as before', (tester) async {
    var taps = 0;
    await pump(tester, value: r'$12.50', onTap: () => taps++);

    expect(find.text(r'$12.50'), findsOneWidget);

    await tester.tap(find.text('Finish trip'));
    await tester.pump();
    expect(taps, 1);
  });
}
