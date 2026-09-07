import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/item_card.dart';
import 'package:pantry_wear/src/shopping/trip_collection_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/undo_window.dart';

import 'wear_fixtures.dart';

/// The done and skipped pages, once they became what they always were: the
/// checklist's own rows in a state, on the same centred-focus list as every
/// other page that writes.
///
/// Commit-on-centre is the rule under test — an off-centre tap costs a scroll,
/// never a write — and the glyph is the one thing the two pages do not share,
/// because a skipped item is not a checked one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WearShape.markFrom(['round']);
    SyncManager.instance.setOnline(false);
  });

  tearDown(() => unawaited(SyncManager.instance.reset()));

  final bought = [
    testItem(id: 1, name: 'Bread'),
    testItem(id: 2, name: 'Milk'),
    testItem(id: 3, name: 'Apples'),
  ];

  ChecklistsController seeded({
    List<ListItem> done = const [],
    List<ListItem> removed = const [],
  }) {
    final controller = ChecklistsController.seeded(
      houseId: 1,
      stores: [testStore(id: 1, name: 'Corner shop')],
      categories: [testCategory(id: 1, name: 'Dairy')],
      done: done,
      removed: removed,
      session: testSession(activeStoreId: 1),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ChecklistsController controller, {
    required List<ListItem> items,
    IconData markedIcon = Icons.check_circle,
    void Function(ListItem item)? onTap,
  }) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: TripCollectionPage(
            controller: controller,
            items: items,
            empty: m.wear.nothingToCheckOff,
            markedIcon: markedIcon,
            onTap: onTap ?? controller.uncheckItem,
            rotary: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ItemCard cardFor(WidgetTester tester, String name) => tester.widget<ItemCard>(
    find.ancestor(of: find.text(name), matching: find.byType(ItemCard)),
  );

  testWidgets("the rows are the checklist page's own cards", (tester) async {
    final controller = seeded(done: bought);
    await pumpPage(tester, controller, items: bought);

    expect(find.byType(ItemCard), findsWidgets);
    // Everything on this page is in the state the page is about.
    expect(cardFor(tester, 'Bread').marked, isTrue);
  });

  testWidgets('the skipped page says skipped, not checked', (tester) async {
    final controller = seeded(removed: bought);
    await pumpPage(
      tester,
      controller,
      items: bought,
      markedIcon: Icons.remove_shopping_cart,
      onTap: controller.unskipItem,
    );

    expect(cardFor(tester, 'Bread').markedIcon, Icons.remove_shopping_cart);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('an off-centre tap scrolls and writes nothing', (tester) async {
    final controller = seeded(done: bought);
    await pumpPage(tester, controller, items: bought);

    final before = tester.getTopLeft(find.text('Apples')).dy;
    await tester.tap(find.text('Apples'));
    await tester.pumpAndSettle();
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    // It came to the centre line, and no window was ever opened.
    expect(tester.getTopLeft(find.text('Apples')).dy, lessThan(before));
    expect(controller.done.length, 3);
    expect(controller.items, isEmpty);
  });

  testWidgets('the centred row goes back, behind the undo window', (
    tester,
  ) async {
    final controller = seeded(done: bought);
    await pumpPage(tester, controller, items: bought);

    // The first row is the one on the centre line when the list opens.
    await tester.tap(find.text('Bread'));
    await tester.pump(const Duration(milliseconds: 100));

    // Reading as on its way back before anything is written.
    expect(cardFor(tester, 'Bread').marked, isFalse);
    expect(controller.done.length, 3);

    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(controller.done.map((i) => i.name), isNot(contains('Bread')));
    expect(controller.items.map((i) => i.name), contains('Bread'));
  });

  testWidgets('a second tap inside the window keeps it here', (tester) async {
    final controller = seeded(done: bought);
    await pumpPage(tester, controller, items: bought);

    await tester.tap(find.text('Bread'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Bread'));
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(cardFor(tester, 'Bread').marked, isTrue);
    expect(controller.done.length, 3);
  });

  testWidgets('an empty page says so rather than drawing nothing', (
    tester,
  ) async {
    final controller = seeded();
    await pumpPage(tester, controller, items: const []);

    expect(find.text(m.wear.nothingToCheckOff), findsOneWidget);
    expect(find.byType(ItemCard), findsNothing);
  });
}
