import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';

import 'wear_fixtures.dart';

/// Guards the bug that stayed invisible to every other check. The list
/// computed the focused group correctly the whole time; the rail never saw it,
/// because a scroll notification arrives during layout and the rebuild it
/// asked for was dropped inside the frame already building. Analysis was clean
/// and no exception reached logcat, so only pumping the real tree caught it.
void main() {
  setUp(() => WearShape.markFrom(['round']));

  ChecklistsController seeded({List<ListItem> done = const []}) =>
      ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        categories: [testCategory(id: 1, name: 'Dairy')],
        items: [
          for (var i = 0; i < 4; i++)
            testItem(id: i + 1, name: 'Item ${i + 1}', categoryId: 1),
        ],
        done: done,
      );

  Future<ChecklistsController> pumpShell(
    WidgetTester tester, {
    List<ListItem> done = const [],
  }) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = seeded(done: done);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
    return controller;
  }

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
    await pumpShell(tester);

    // Twice over: the group's own header in the list, and the rail naming it.
    expect(find.text('Dairy'), findsNWidgets(2));
  });

  testWidgets('the completed section is reachable once opened', (tester) async {
    await pumpShell(
      tester,
      done: [testItem(id: 9, name: 'Milk', categoryId: 1, done: true)],
    );

    final label = m.checklists.completedCount(1);
    final controller = tester
        .widget<SnapFocusList>(find.byType(SnapFocusList))
        .controller;

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    final opened = tester.widget<SnapFocusList>(find.byType(SnapFocusList));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(opened.geometry!.value.stickyGroup, label);
    expect(opened.geometry!.value.centredIndex, opened.elements.length - 1);
  });

  testWidgets('an off-centre tap scrolls rather than checking', (tester) async {
    await pumpShell(tester);

    final geometry = tester
        .widget<SnapFocusList>(find.byType(SnapFocusList))
        .geometry!;
    final centred = geometry.value.centredIndex;

    // The last row drawn is well below the centre line, so this is a mis-aim.
    await tester.tap(find.text('Item 4'));
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.check_circle),
      findsNothing,
      reason: 'a mis-aim costs a scroll, never a write',
    );
    expect(geometry.value.centredIndex, isNot(centred));
  });
}
