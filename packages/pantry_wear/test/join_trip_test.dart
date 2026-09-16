import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/member.dart';
import 'package:pantry_core/models/shopping_presence_entry.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shopping/join_trip_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_avatar.dart';
import 'package:pantry_wear/src/widgets/wear_row.dart';

import 'wear_fixtures.dart';

/// The page that offers a housemate's trip before the wearer sets up one of
/// their own. What these guard is that it offers only trips worth joining,
/// names whoever is on them, and never stands between the wearer and a trip of
/// their own.
void main() {
  setUp(() {
    WearShape.markFrom(['round']);
    SyncManager.instance.setOnline(true);
  });

  tearDown(() => SyncManager.instance.setOnline(true));

  final corner = testStore(id: 7, name: 'Corner shop');

  Member member(String userId, String displayName) => Member(
    id: userId.hashCode,
    houseId: 1,
    userId: userId,
    displayName: displayName,
    role: 'member',
    joinedAt: 0,
  );

  ShoppingPresenceEntry trip({
    required String userId,
    int? sessionId = 12,
    int? activeStoreId,
    List<String> memberIds = const [],
    int lastSeenAt = 0,
  }) => ShoppingPresenceEntry(
    userId: userId,
    sessionId: sessionId,
    activeStoreId: activeStoreId,
    lastSeenAt: lastSeenAt,
    memberIds: memberIds.isNotEmpty ? memberIds : [userId],
  );

  ChecklistsController seeded({
    required List<ShoppingPresenceEntry> joinableTrips,
  }) => ChecklistsController.seeded(
    houseId: 1,
    stores: [corner],
    members: [
      member('casraf', 'Chen'),
      member('dana', 'Dana'),
      member('yuval', 'Yuval'),
    ],
    joinableTrips: joinableTrips,
    currentUserId: 'casraf',
  );

  Future<JoinChoice?> pumpGate(
    WidgetTester tester,
    ChecklistsController controller,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(controller.dispose);
    JoinChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  choice = await Navigator.of(context).push<JoinChoice>(
                    MaterialPageRoute(
                      builder: (_) => JoinTripPage(controller: controller),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return choice;
  }

  group('which trips are offered', () {
    test('a trip the wearer is already on is not one of them', () {
      final entries = [
        trip(userId: 'dana', sessionId: 12, memberIds: ['dana', 'casraf']),
        trip(userId: 'yuval', sessionId: 13),
      ];

      // Presence describes trips rather than people, so the one the wearer
      // joined comes back here too — offering it would be offering them a trip
      // they are standing in.
      final joinable = ChecklistsController.joinableFrom(entries, 'casraf');
      expect(joinable.map((e) => e.userId), ['yuval']);
    });

    test('a trip with no id to address is nothing to offer', () {
      // What a server without `shopping-join-session` sends: presence by
      // person, naming no trip.
      final joinable = ChecklistsController.joinableFrom([
        trip(userId: 'dana', sessionId: null),
      ], 'casraf');

      expect(joinable, isEmpty);
    });

    test('the freshest trip is the one under the thumb', () {
      final joinable = ChecklistsController.joinableFrom([
        trip(userId: 'dana', sessionId: 12, lastSeenAt: 100),
        trip(userId: 'yuval', sessionId: 13, lastSeenAt: 900),
      ], 'casraf');

      expect(joinable.map((e) => e.userId), ['yuval', 'dana']);
    });
  });

  group('the offer', () {
    testWidgets('a trip is a row, by name, at the shop it is being walked', (
      tester,
    ) async {
      await pumpGate(
        tester,
        seeded(joinableTrips: [trip(userId: 'dana', activeStoreId: 7)]),
      );

      expect(find.text('Dana'), findsOneWidget);
      expect(find.text(corner.name), findsOneWidget);
      // A face, not an icon: it is read faster than any glyph standing in for
      // one.
      expect(find.byType(WearAvatarStack), findsOneWidget);
    });

    testWidgets('housemates sharing a trip share its row', (tester) async {
      await pumpGate(
        tester,
        seeded(
          joinableTrips: [
            trip(userId: 'dana', memberIds: ['dana', 'yuval']),
          ],
        ),
      );

      // One row per trip, under whoever started it — two rows would read as
      // two trips to choose between.
      expect(find.byType(WearRow), findsOneWidget);
      expect(find.text(m.wear.plusOthers('Dana', 1)), findsOneWidget);
      // A trip nobody has reached a till on still says it is under way.
      expect(find.text(m.shopping.bannerShoppingNow), findsOneWidget);
    });

    testWidgets('a trip nobody has a name for keeps its login name', (
      tester,
    ) async {
      final controller = ChecklistsController.seeded(
        houseId: 1,
        joinableTrips: [trip(userId: 'dana')],
        currentUserId: 'casraf',
      );

      await pumpGate(tester, controller);

      // The member list is a read like any other and can be the one that did
      // not land. An unnamed housemate is still a trip worth joining.
      expect(find.text('dana'), findsOneWidget);
    });
  });

  group('the acts', () {
    testWidgets('starting a trip of your own is never more than one tap away', (
      tester,
    ) async {
      final controller = seeded(
        joinableTrips: [
          trip(userId: 'dana'),
          trip(userId: 'yuval', sessionId: 13),
        ],
      );
      await pumpGate(tester, controller);

      // The call to action holds the slot every other page keeps its act in,
      // whatever is offered above it.
      await tester.tap(find.text(m.wear.startMyOwn));
      await tester.pumpAndSettle();

      expect(find.byType(JoinTripPage), findsNothing);
    });

    testWidgets('a row says why it cannot act, rather than going quiet', (
      tester,
    ) async {
      SyncManager.instance.setOnline(false);
      await pumpGate(tester, seeded(joinableTrips: [trip(userId: 'dana')]));

      // Joining is online-only for the reason starting is: a queued join would
      // put the watch inside a trip the server has never put it in.
      expect(find.text(m.wear.needsConnection), findsOneWidget);
    });

    testWidgets('a refused join leaves the other trips standing', (
      tester,
    ) async {
      final controller = seeded(
        joinableTrips: [
          trip(userId: 'dana'),
          trip(userId: 'yuval', sessionId: 13),
        ],
      );
      await pumpGate(tester, controller);

      // No server behind this test, so the join is refused — which is the
      // case worth guarding: the page stays, with the reason where a blocked
      // start's reason goes.
      tester.state<SnapFocusListState>(find.byType(SnapFocusList)).centreOn(0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dana'));
      await tester.pumpAndSettle();

      expect(find.byType(JoinTripPage), findsOneWidget);
      expect(find.text(m.wear.joinFailed), findsOneWidget);
      expect(find.text('Yuval'), findsOneWidget);
    });
  });
}
