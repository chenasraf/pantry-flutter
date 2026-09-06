import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_metrics.dart';

/// What a square screen does instead of electing a row.
///
/// A round screen narrows towards the top and bottom, and that is the whole
/// argument for a row in charge: rows recede from it, the scroll settles on it,
/// and a tap anywhere else only aims. A square screen narrows nowhere — every
/// row is as wide and as legible as every other — so the same machinery buys
/// the wearer a scroll before every action and nothing else.
///
/// Every other wear test runs round, so this file is the only place the flat
/// path is exercised at all.
void main() {
  const viewport = 450.0;
  const extent = WearMetrics.itemExtent;

  /// How many whole rows fit with the list scrolled to the top.
  const whole = viewport ~/ extent;

  setUp(() => WearShape.markFrom(const ['square']));
  tearDown(() => WearShape.markFrom(const ['round']));

  Future<({ScrollController scroll, GlobalKey<SnapFocusListState> key})> pump(
    WidgetTester tester, {
    int rows = 12,
    bool underRail = false,
  }) async {
    tester.view.physicalSize = const Size(viewport, viewport);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final key = GlobalKey<SnapFocusListState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SnapFocusList(
            key: key,
            controller: scroll,
            itemExtent: extent,
            underRail: underRail,
            elements: [
              for (var i = 0; i < rows; i++)
                FocusElement(
                  extent: extent,
                  builder: (context, d) => Text('row $i'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (scroll: scroll, key: key);
  }

  testWidgets('the list starts at the top, not half a viewport down', (
    tester,
  ) async {
    await pump(tester);

    // The round lead exists so the first row can reach the centre line. With
    // no line to reach it is just half a screen of nothing.
    expect(tester.getTopLeft(find.text('row 0')).dy, closeTo(0, 1));
  });

  testWidgets('a list under the rail holds back exactly what the rail covers', (
    tester,
  ) async {
    await pump(tester, underRail: true);

    expect(
      tester.getTopLeft(find.text('row 0')).dy,
      closeTo(WearMetrics.railHeight(viewport), 1),
    );
  });

  testWidgets('no row recedes from any other', (tester) async {
    await pump(tester);

    // The falloff narrows and scales each row inside a FractionallySizedBox.
    // A flat list wraps none, so there is not one in the tree.
    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('the scroll rests where it is let go of', (tester) async {
    final it = await pump(tester);

    // Deliberately not `drag`, which flings: this is a slow drag released with
    // no velocity, so anything that moves afterwards is the snap.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SnapFocusList)),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // A third of a row down. On a round screen the snap would have taken it
    // back to a row centre.
    expect(it.scroll.offset, closeTo(30, 2));
  });

  testWidgets('a whole row acts where it lies, and a clipped one does not', (
    tester,
  ) async {
    final it = await pump(tester);
    final list = it.key.currentState!;

    // Not just the row a round screen would have elected — every row the
    // wearer can see all of.
    for (var i = 0; i < whole; i++) {
      expect(list.canActOn(i), isTrue, reason: 'row $i is whole');
    }
    // The first row running off the bottom edge. It was not aimed at squarely
    // either, so it is the one case that still costs a scroll.
    expect(list.isFullyVisible(whole), isFalse);
    expect(list.canActOn(whole), isFalse);
  });

  testWidgets('revealing a clipped row brings it in and no further', (
    tester,
  ) async {
    final it = await pump(tester);
    final list = it.key.currentState!;

    list.reveal(whole);
    await tester.pumpAndSettle();

    expect(list.canActOn(whole), isTrue);
    // Scrolled just enough to seat the row against the bottom edge — hauling
    // it to a centre it does not have is the very thing a flat list avoids.
    expect(it.scroll.offset, closeTo((whole + 1) * extent - viewport, 1));
  });
}
