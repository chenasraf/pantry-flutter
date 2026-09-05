import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// The rail is the only thing that names a page, so a page that does not reach
/// it has no title at all — which is how every page came to read as the
/// checklist's name.
void main() {
  setUp(() => WearShape.markFrom(['round']));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      lists: [testList()],
      categories: [testCategory(id: 1, name: 'Dairy')],
      items: [testItem(id: 1, name: 'Milk', categoryId: 1)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each browse page is named by the rail', (tester) async {
    await pump(tester);

    final titles = [
      testList().name,
      m.nav.photoBoard,
      m.nav.notesWall,
      m.wear.account,
    ];
    for (final title in titles) {
      expect(
        find.text(title),
        findsWidgets,
        reason: 'the rail should name the page as "$title"',
      );
      await tester.fling(
        find.byType(PageView).first,
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('tapping the rail offers the list switcher', (tester) async {
    await pump(tester);

    expect(find.text(m.wear.changeList), findsNothing);
    await tester.tap(find.text(testList().name));
    await tester.pumpAndSettle();

    // One tap expands, a second one opens: a mistap on a rail this small would
    // otherwise cost the wearer their place.
    expect(find.text(m.wear.changeList), findsOneWidget);
  });
}
