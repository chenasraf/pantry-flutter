import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_metrics.dart';

/// Whether content that is not a row can be stopped on and read.
///
/// The snap table holds landable rows only, which is what makes a header
/// unlandable — but the physics settled on the nearest table entry from
/// anywhere, so anything sitting between two rows, or above the first, was
/// hauled off the screen the moment the wearer let go. Worn on the reference
/// watch as "the text above the checkboxes is hard to scroll into" on a note,
/// and as the account page snapping back to the household row.
void main() {
  setUp(() => WearShape.markFrom(['round']));

  Future<ScrollController> pump(
    WidgetTester tester,
    List<FocusElement> elements,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SnapFocusList(
            controller: scroll,
            itemExtent: WearMetrics.itemExtent,
            elements: elements,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scroll;
  }

  FocusElement row(String label) => FocusElement(
    extent: WearMetrics.itemExtent,
    builder: (context, _) => Text(label),
  );

  FocusElement prose(String label, double extent) => FocusElement(
    extent: extent,
    snappable: false,
    isHeader: true,
    builder: (context, _) => Text(label),
  );

  testWidgets('a long unlandable stretch can be rested in', (tester) async {
    final scroll = await pump(tester, [
      row('first'),
      prose('prose', WearMetrics.itemExtent * 5),
      row('last'),
    ]);

    // Into the middle of the prose, which is further from either row than the
    // snap reaches. A list of landable rows never settles more than half a row
    // from one, so this loosens nothing where the grid matters.
    final target = scroll.position.maxScrollExtent / 2;
    await tester.drag(
      find.byType(SnapFocusList),
      Offset(0, -target),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();

    expect((scroll.offset - target).abs(), lessThan(WearMetrics.itemExtent));
  });

  testWidgets('a header above the first row is a resting place', (
    tester,
  ) async {
    final scroll = await pump(tester, [
      prose('heading', WearMetrics.itemExtent),
      row('first'),
      row('second'),
    ]);

    await tester.drag(find.byType(SnapFocusList), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(SnapFocusList), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(
      scroll.offset,
      0,
      reason: 'the ends of the scrollable are always somewhere to stop',
    );
  });

  testWidgets('a homogeneous list still lands on rows only', (tester) async {
    final scroll = await pump(tester, [
      for (var i = 0; i < 6; i++) row('row $i'),
    ]);

    // Half a row is the furthest a settle can be from a target here, so the
    // snap always reaches and the grid is exactly as tight as it was.
    await tester.drag(
      find.byType(SnapFocusList),
      const Offset(0, -WearMetrics.itemExtent * 1.5),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();

    expect(scroll.offset % WearMetrics.itemExtent, closeTo(0, 0.5));
  });
}
