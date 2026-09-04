import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/prototype/checklist_prototype.dart';
import 'package:pantry_wear/src/prototype/focus_list.dart';

/// PROTOTYPE — guards the one bug that stayed invisible to every other check.
/// The list computed the focused group correctly the whole time; the rail
/// never saw it, because a scroll notification arrives during layout and the
/// rebuild it asked for was dropped inside the frame already building.
/// Analysis was clean and no exception reached logcat, so only pumping the
/// real tree caught it.
void main() {
  testWidgets('the list publishes the focused row group', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final geometry = ValueNotifier(const FocusGeometry());
    addTearDown(geometry.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 480,
          width: 480,
          child: SnapFocusList(
            controller: controller,
            elements: [
              FocusElement(
                extent: 24,
                snappable: false,
                isHeader: true,
                groupLabel: 'Dairy',
                builder: (context, d) => const SizedBox(),
              ),
              for (var i = 0; i < 4; i++)
                FocusElement(
                  extent: 54,
                  groupLabel: 'Dairy',
                  groupColor: Colors.green,
                  builder: (context, d) => const SizedBox(),
                ),
            ],
            itemExtent: 54,
            geometry: geometry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(geometry.value.stickyGroup, 'Dairy');
  });

  testWidgets('the rail renders the focused group', (tester) async {
    tester.view.physicalSize = const Size(480, 480);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ChecklistPrototype()));
    await tester.pumpAndSettle();

    // Twice over: the group's own header in the list, and the rail naming it.
    expect(find.text('Dairy'), findsNWidgets(2));
  });
}
