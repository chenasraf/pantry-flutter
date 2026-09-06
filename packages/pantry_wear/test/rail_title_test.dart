import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_rail.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// The rail is the only thing that names a page, so a page that does not reach
/// it has no title at all — which is how every page came to read as the
/// checklist's name.
void main() {
  setUp(() {
    WearShape.markFrom(['round']);
    AuthService.instance.isUnauthorized.value = false;
  });

  tearDown(() => AuthService.instance.isUnauthorized.value = false);

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

  testWidgets('a rejected credential takes the rail line', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('degraded-line')), findsNothing);

    // The rail carries no listener of the controller's, so this is the whole
    // trigger: nothing else about the shell changes when a 401 lands.
    AuthService.instance.isUnauthorized.value = true;
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('degraded-line')), findsOneWidget);
    expect(find.text(m.common.sessionExpiredTitle), findsOneWidget);
  });

  testWidgets('the state is washed, not merely written', (tester) async {
    // Worn without one, a 9pt line reads as another label rather than a state.
    // The gradient is the fix for the hard chord a flat fill cuts across a
    // round screen, so it is the wash's shape as much as its presence.
    Finder wash() => find.descendant(
      of: find.byType(WearRail),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).gradient != null,
      ),
    );

    await pump(tester);
    expect(wash(), findsNothing);

    AuthService.instance.isUnauthorized.value = true;
    await tester.pumpAndSettle();

    expect(wash(), findsOneWidget);
  });

  testWidgets('a title tap cannot hide the state', (tester) async {
    await pump(tester);
    AuthService.instance.isUnauthorized.value = true;
    await tester.pumpAndSettle();

    await tester.tap(find.text(testList().name));
    await tester.pumpAndSettle();

    // The slot the *Change list* button lives in is spoken for while the state
    // stands, so the expansion that would cover it never happens.
    expect(find.text(m.wear.changeList), findsNothing);
    expect(find.byKey(const ValueKey('degraded-line')), findsOneWidget);
  });

  testWidgets('the line is a signpost to the account page', (tester) async {
    await pump(tester);
    AuthService.instance.isUnauthorized.value = true;
    await tester.pumpAndSettle();
    expect(find.text(m.wear.account), findsNothing);

    await tester.tap(find.byKey(const ValueKey('degraded-line')));
    await tester.pumpAndSettle();

    // The rail names the page under it, so this is the pager having moved —
    // and it moved to the page holding *Set up again*, not into a pairing flow.
    expect(find.text(m.wear.account), findsOneWidget);
    expect(find.text(m.wear.setUpAgain), findsOneWidget);
  });
}
