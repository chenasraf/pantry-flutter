import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shopping/progression_page.dart';
import 'package:pantry_wear/src/shopping/trip_summary_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_row.dart';

import 'wear_fixtures.dart';

void main() {
  setUp(() {
    WearShape.markFrom(['round']);
    SyncManager.instance.setOnline(true);
  });

  tearDown(() => SyncManager.instance.setOnline(true));

  final corner = testStore(id: 7, name: 'Corner shop');
  final hardware = testStore(id: 8, name: 'Hardware store', sortOrder: 1);
  final market = testStore(id: 9, name: 'Market', sortOrder: 2);

  ChecklistsController seeded({
    int? activeStoreId = 8,
    List<int> storeIds = const [7, 8, 9],
    List<ListItem> done = const [],
  }) => ChecklistsController.seeded(
    houseId: 1,
    stores: [corner, hardware, market],
    done: done,
    session: testSession(activeStoreId: activeStoreId, storeIds: storeIds),
  );

  Future<void> pumpProgression(
    WidgetTester tester,
    ChecklistsController controller,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProgressionPage(
            controller: controller,
            active: true,
            rotary: true,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  WearRow rowFor(WidgetTester tester, String label) => tester.widget<WearRow>(
    find.ancestor(of: find.text(label), matching: find.byType(WearRow)),
  );

  group('the legs', () {
    testWidgets('every leg is a row, in the order the trip walks them', (
      tester,
    ) async {
      await pumpProgression(tester, seeded());

      for (final store in [corner, hardware, market]) {
        expect(find.text(store.name), findsOneWidget);
      }
    });

    testWidgets('the leg being shopped says so and the ones behind recede', (
      tester,
    ) async {
      await pumpProgression(tester, seeded());

      expect(rowFor(tester, hardware.name).value, m.wear.hereNow);
      expect(
        rowFor(tester, corner.name).spent,
        isTrue,
        reason: 'a shop already walked keeps its place and loses its ink',
      );
      expect(rowFor(tester, market.name).spent, isFalse);
      expect(rowFor(tester, market.name).value, isNull);
    });

    testWidgets('a storeless trip has no legs and still offers the way out', (
      tester,
    ) async {
      await pumpProgression(
        tester,
        seeded(activeStoreId: null, storeIds: const []),
      );

      expect(find.text(m.shopping.finishTrip), findsOneWidget);
    });
  });

  group('the one move it offers', () {
    testWidgets('names the shop it would move to while a leg remains', (
      tester,
    ) async {
      await pumpProgression(tester, seeded());

      expect(find.text(m.wear.nextIs(market.name)), findsOneWidget);
      expect(find.text(m.shopping.finishTrip), findsNothing);
    });

    testWidgets('becomes finishing at the last leg', (tester) async {
      await pumpProgression(tester, seeded(activeStoreId: 9));

      expect(find.text(m.shopping.finishTrip), findsOneWidget);
      expect(find.text(m.wear.nextIs(market.name)), findsNothing);
    });

    testWidgets('says why it cannot act with no connection', (tester) async {
      SyncManager.instance.setOnline(false);
      await pumpProgression(tester, seeded());

      // Both lifecycle verbs are online-only: `getItems` is narrowed by the
      // active store server-side, so a queued advance would show the previous
      // shop's list while claiming to be at the next.
      expect(find.text(m.wear.needsConnection), findsOneWidget);
    });

    testWidgets('only the centred leg is the one the trip acts on', (
      tester,
    ) async {
      // Offline is the deterministic refusal, and reaching it at all is what
      // proves a row is wired to the trip rather than merely drawn.
      SyncManager.instance.setOnline(false);
      await pumpProgression(tester, seeded());

      // The list opens on the reminders row. Putting the last leg on the
      // centre line leaves the ones behind it above — which is where they have
      // to be tapped from, since the call to action stands over the lower rows
      // and takes their taps by design.
      tester.state<SnapFocusListState>(find.byType(SnapFocusList)).centreOn(3);
      await tester.pumpAndSettle();

      // Q19's commit-on-centre, unchanged: a mis-aim costs a scroll rather
      // than a write against a shop the wearer is not standing in.
      await tester.tap(find.text(corner.name));
      await tester.pumpAndSettle();
      expect(find.text(m.wear.advanceFailed), findsNothing);

      // The same row, now on the line the first tap carried it to.
      await tester.tap(find.text(corner.name));
      await tester.pump();
      expect(find.text(m.wear.advanceFailed), findsOneWidget);
    });
  });

  group('the summary that ends it', () {
    Future<void> pumpSummary(
      WidgetTester tester,
      ChecklistsController controller,
    ) async {
      tester.view.physicalSize = const Size(450, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: TripSummaryPage(controller: controller)),
      );
      await tester.pump();
    }

    ChecklistsController withReview() => ChecklistsController.seeded(
      houseId: 1,
      stores: [corner, hardware],
      session: testSession(activeStoreId: 8, storeIds: const [7, 8]),
      review: testReview([
        (storeId: 7, items: [testItem(id: 1, name: 'Milk')]),
        (storeId: 8, items: [testItem(id: 2, name: 'Bulbs')]),
      ]),
    );

    testWidgets('describes the trip rather than asking about it', (
      tester,
    ) async {
      await pumpSummary(tester, withReview());

      expect(
        find.text('${m.wear.boughtTally(2)} · ${m.wear.storeTally(2)}'),
        findsOneWidget,
      );
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text(corner.name), findsOneWidget);
      expect(find.text(m.shopping.finishTrip), findsOneWidget);
    });

    testWidgets('a till with no figure says it is not set', (tester) async {
      await pumpSummary(tester, withReview());

      expect(find.text(m.wear.notBilled), findsWidgets);
    });

    testWidgets('a figure the trip already carries is the one shown', (
      tester,
    ) async {
      final controller = ChecklistsController.seeded(
        houseId: 1,
        stores: [corner],
        session: testSession(
          activeStoreId: 7,
          storeIds: const [7],
          billedByStore: const {7: 12.5},
        ),
        review: testReview([
          (storeId: 7, items: [testItem(id: 1, name: 'Milk')]),
        ]),
      );

      await pumpSummary(tester, controller);

      expect(find.text(r'$12.5'), findsOneWidget);
    });

    testWidgets('a log that never arrived is absent, not zero', (tester) async {
      final controller = ChecklistsController.seeded(
        houseId: 1,
        stores: [corner],
        session: testSession(activeStoreId: 7, storeIds: const [7]),
      );

      await pumpSummary(tester, controller);

      expect(
        find.text('${m.wear.boughtTally(0)} · ${m.wear.storeTally(0)}'),
        findsNothing,
        reason: '"0 bought" would name a trip that bought nothing',
      );
      expect(find.text(m.shopping.finishTrip), findsOneWidget);
    });
  });
}
