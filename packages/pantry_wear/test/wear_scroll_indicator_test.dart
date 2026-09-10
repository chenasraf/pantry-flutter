import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/wear_scroll_indicator.dart';

/// Whether the watch says where in a list the wearer is.
///
/// A scrolling view with nothing to show for it leaves the wearer with no idea
/// how much more there is or how far down they have come — and on a screen this
/// small that is most of what they need to know. Wear's rule cuts both ways: a
/// view that scrolls has to show one, and a view that does not must not.
void main() {
  setUp(() => WearShape.markFrom(const ['round']));

  Future<void> pump(WidgetTester tester, {required int rows}) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearScrollIndicator(
            child: ListView(
              children: [
                for (var i = 0; i < rows; i++)
                  SizedBox(height: 54, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The indicator's own fader. Nothing else inside the wrapper builds one, so
  /// its presence is the indicator's presence and its value is how visible it
  /// currently is.
  final fader = find.descendant(
    of: find.byType(WearScrollIndicator),
    matching: find.byType(FadeTransition),
  );

  double shownAt(WidgetTester tester) =>
      tester.widget<FadeTransition>(fader).opacity.value;

  testWidgets('a list says where you are in it once you move it', (
    tester,
  ) async {
    await pump(tester, rows: 40);

    // Nothing before the wearer has touched it: the rule is about what happens
    // when they interact with a scrollable view.
    expect(fader, findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(fader, findsOneWidget);
    expect(shownAt(tester), 1);
  });

  testWidgets('and stops saying it a moment after the list settles', (
    tester,
  ) async {
    await pump(tester, rows: 40);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shownAt(tester), 1);

    await tester.pump(WearScrollIndicator.linger);
    await tester.pump(const Duration(milliseconds: 200));

    expect(shownAt(tester), 0);
  });

  testWidgets('a list that fits says nothing at all', (tester) async {
    await pump(tester, rows: 2);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Wear's rule runs both ways: an indicator on a view that does not scroll
    // is as wrong as none on a view that does.
    expect(fader, findsNothing);
  });
}
