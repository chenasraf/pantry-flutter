import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/swipe_reveal_row.dart';

import '../helpers/test_app.dart';

void main() {
  setUp(() => SwipeRevealRow.debugPinActions = false);
  tearDown(() => SwipeRevealRow.debugPinActions = null);

  Widget row({VoidCallback? onEdit, TextDirection dir = TextDirection.ltr}) =>
      wrapForTest(
        Directionality(
          textDirection: dir,
          child: SwipeRevealRow(
            actions: [
              SwipeAction(
                icon: Icons.edit,
                label: 'Edit',
                tint: Colors.white,
                background: Colors.blue,
                onPressed: onEdit ?? () {},
              ),
              SwipeAction(
                icon: Icons.delete,
                label: 'Remove',
                tint: Colors.white,
                background: Colors.red,
                onPressed: () {},
              ),
            ],
            child: const SizedBox(
              width: double.infinity,
              height: 56,
              child: Text('Milk'),
            ),
          ),
        ),
      );

  /// How far the action row sits from fully open: 0 when open.
  double slideOf(WidgetTester tester) => tester
      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
      .transform!
      .getTranslation()
      .x;

  Future<void> open(WidgetTester tester, {double dx = -300}) async {
    await tester.drag(find.text('Milk'), Offset(dx, 0));
    await tester.pumpAndSettle();
    expect(slideOf(tester), 0);
  }

  testWidgets('swiping over the open buttons closes the row', (tester) async {
    await tester.pumpWidget(row());
    await open(tester);

    await tester.drag(find.text('Edit'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(slideOf(tester), isNot(0));
  });

  testWidgets('in RTL, swiping over the open buttons closes the row', (
    tester,
  ) async {
    await tester.pumpWidget(row(dir: TextDirection.rtl));
    await open(tester, dx: 300);

    await tester.drag(find.text('Edit'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(slideOf(tester), isNot(0));
  });

  testWidgets('a short swipe over the buttons snaps back open', (tester) async {
    await tester.pumpWidget(row());
    await open(tester);

    await tester.drag(find.text('Edit'), const Offset(30, 0));
    await tester.pumpAndSettle();

    expect(slideOf(tester), 0);
  });

  testWidgets('tapping an open button still runs it and closes the row', (
    tester,
  ) async {
    var edited = false;
    await tester.pumpWidget(row(onEdit: () => edited = true));
    await open(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
    expect(slideOf(tester), isNot(0));
  });
}
