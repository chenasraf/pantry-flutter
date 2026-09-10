import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/account/account_page.dart';
import 'package:pantry_wear/src/account/house_switcher_page.dart';
import 'package:pantry_wear/src/account/sign_out_page.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';

/// The checks the account page earned.
///
/// It analysed clean before it was ever pumped, which is the whole reason it
/// has tests: a watch layout fails by drawing the wrong thing quietly, not by
/// throwing. The page is also the only heterogeneous list on the watch — a
/// header that cannot be landed on, a readout that opens nothing, and four
/// rows that each open something different — so the snap table is the thing
/// most worth pinning down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory dir;
  final storage = <String, String>{};

  House house(int id, String name) => House(
    id: id,
    name: name,
    ownerUid: 'ada',
    role: 'admin',
    createdAt: 0,
    updatedAt: 0,
  );

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_account_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async => dir.path);
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      final key = call.arguments['key'] as String? ?? '';
      return switch (call.method) {
        'read' => storage[key],
        'write' => storage[key] = call.arguments['value'] as String,
        'readAll' => Map<String, String>.from(storage),
        _ => null,
      };
    });
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    await PrefsService.instance.setLastHouseId(1);
    await SyncManager.instance.reset();
    AuthService.instance.isUnauthorized.value = false;
  });

  tearDown(() async {
    AuthService.instance.isUnauthorized.value = false;
    await SyncManager.instance.reset();
    await HouseService.instance.cache.clear();
    await dir.delete(recursive: true);
  });

  /// A watch-sized window, so a pushed route gets watch geometry too rather
  /// than the 800×600 a test window defaults to.
  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Cache writes go through [WidgetTester.runAsync]: a store reads its
  /// directory over a platform channel and writes over real file I/O, and
  /// neither is driven to completion by the fake-async zone a `testWidgets`
  /// body runs in.
  Future<void> seedHouses(WidgetTester tester, List<House> houses) =>
      tester.runAsync(() async {
        await HouseService.instance.cache.load();
        HouseService.instance.cache.setList(
          'houses',
          houses,
          (h) => h.toJson(),
        );
        await HouseService.instance.cache.flush();
      });

  Future<void> pump(WidgetTester tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AccountPage(rotary: true))),
    );
    await tester.pump();
  }

  /// How many lists are listening to the crown. The detent stream is broadcast
  /// and a covered list stays mounted, so this is the number that must never
  /// exceed one. Offstage is not skipped: a route pushed over the page takes
  /// it offstage but leaves it mounted and subscribed, which is the entire
  /// thing being counted.
  int rotaryListeners(WidgetTester tester) => tester
      .widgetList<SnapFocusList>(
        find.byType(SnapFocusList, skipOffstage: false),
      )
      .where((list) => list.rotaryActive)
      .length;

  testWidgets('says who the watch is and where, on both shapes', (
    tester,
  ) async {
    for (final shape in ['round', 'square']) {
      WearShape.markFrom([shape]);
      await pump(tester);

      expect(find.text(m.wear.signedInAs('ada')), findsOneWidget);
      expect(
        find.text('cloud.example'),
        findsOneWidget,
        reason:
            'the wearer typed neither the account nor the server, so this is '
            'the one place the watch says whose house it is showing',
      );
    }
  });

  testWidgets('identity is a label, not a landing', (tester) async {
    await pump(tester);

    final list = tester.widget<SnapFocusList>(find.byType(SnapFocusList));
    expect(list.elements.first.snappable, isFalse);
    expect(list.elements.first.isHeader, isTrue);
    expect(
      list.elements.where((e) => e.snappable).length,
      3,
      reason:
          'house, settings and the way out — and nothing else while the '
          'credential still works. Sync is a readout, not a row.',
    );
  });

  testWidgets('the top of the page is somewhere the wearer can stay', (
    tester,
  ) async {
    await pump(tester);
    final scroll = tester
        .widget<SnapFocusList>(find.byType(SnapFocusList))
        .controller;

    // Identity and the sync line sit above the first landable row, so without
    // the ends of the scrollable being resting places the snap hauls the
    // wearer straight past them onto the house row and they can never be
    // read.
    await tester.drag(find.byType(SnapFocusList), const Offset(0, 60));
    await tester.pumpAndSettle();

    expect(scroll.offset, 0);
    expect(find.text(m.wear.signedInAs('ada')), findsOneWidget);
    expect(find.text(m.wear.allSaved), findsOneWidget);
  });

  testWidgets('the house row names the house', (tester) async {
    await seedHouses(tester, [house(1, 'Ada House'), house(2, 'The Annexe')]);
    await pump(tester);

    expect(find.text(m.wear.house), findsOneWidget);
    expect(find.text('Ada House'), findsOneWidget);
  });

  testWidgets('an off-centre tap scrolls, and the centred row opens', (
    tester,
  ) async {
    await seedHouses(tester, [house(1, 'Ada House')]);
    await pump(tester);

    // The way out is the furthest row from the centre line on arrival, which
    // is exactly the asymmetry the page wants: the destructive control is the
    // one thing no single mistap can reach.
    await tester.tap(find.text(m.common.logout));
    await tester.pumpAndSettle();

    expect(
      find.byType(SignOutPage),
      findsNothing,
      reason: 'a mis-aim costs a scroll, never a page',
    );

    await tester.tap(find.text(m.common.logout));
    await tester.pumpAndSettle();

    expect(find.byType(SignOutPage), findsOneWidget);
  });

  testWidgets('a pushed page takes the crown with it', (tester) async {
    await seedHouses(tester, [house(1, 'Ada House')]);
    await pump(tester);

    expect(rotaryListeners(tester), 1);

    await tester.tap(find.text(m.wear.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.wear.settings));
    await tester.pumpAndSettle();

    expect(find.byType(WearSettingsPage), findsOneWidget);
    expect(
      find.byType(SnapFocusList, skipOffstage: false),
      findsNWidgets(2),
      reason: 'the covered page stays mounted under the one pushed over it',
    );
    expect(
      rotaryListeners(tester),
      1,
      reason:
          'so leaving both subscribed would mean one turn of the bezel scrolls '
          'the page on top and the page under it at once',
    );
  });

  testWidgets('the house row opens the switcher', (tester) async {
    await seedHouses(tester, [house(1, 'Ada House'), house(2, 'The Annexe')]);
    await pump(tester);

    await tester.tap(find.text(m.wear.house));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.wear.house));
    await tester.pumpAndSettle();

    expect(find.byType(HouseSwitcherPage), findsOneWidget);
    expect(find.text('The Annexe'), findsOneWidget);
  });

  group('the sync row', () {
    testWidgets('says the work is safe when nothing is waiting', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text(m.wear.allSaved), findsOneWidget);
    });

    testWidgets('says nothing about a mirror that was never part of it', (
      tester,
    ) async {
      await pump(tester);

      // A watch with no link has no snapshot to be late. Reporting that none
      // had ever landed would name a fault where the design has none: a
      // standalone or F-Droid watch reads everything for itself and is exactly
      // as correct.
      expect(find.textContaining(m.wear.agoJustNow), findsNothing);
    });

    testWidgets('follows the queue while the page is being looked at', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text(m.wear.allSaved), findsOneWidget);

      SyncManager.instance.pendingCount.value = 2;
      await tester.pump();

      // The page is the one place the watch answers "is my work safe", and a
      // check-off made on the page behind it is exactly when the answer
      // changes.
      expect(find.text(m.wear.queued(2)), findsOneWidget);
      expect(find.text(m.wear.allSaved), findsNothing);
    });

    testWidgets('is a label under the identity, not a row among the rows', (
      tester,
    ) async {
      await pump(tester);

      final list = tester.widget<SnapFocusList>(find.byType(SnapFocusList));
      expect(
        list.elements[1].snappable,
        isFalse,
        reason:
            'it answers a question instead of offering an action, and a tile '
            'among tiles reads as one more thing to tap',
      );
      expect(list.elements[1].isHeader, isTrue);
    });

    testWidgets('carries its state in colour, not only in words', (
      tester,
    ) async {
      await pump(tester);

      // The mirror half beside it is the page's ordinary quiet grey; the state
      // half is not, so the answer arrives before the words do.
      final safe = tester.widget<Text>(find.text(m.wear.allSaved));
      expect(safe.style!.color, isNotNull);
      expect(safe.style!.color, isNot(Colors.white38));
      expect(safe.style!.color, isNot(Colors.white54));
      expect(safe.style!.fontWeight, FontWeight.w600);
    });
  });

  group('a rejected credential', () {
    Future<void> pumpDegraded(WidgetTester tester) async {
      await pump(tester);
      AuthService.instance.isUnauthorized.value = true;
      await tester.pumpAndSettle();
    }

    testWidgets('explains itself and offers the way back', (tester) async {
      await pumpDegraded(tester);

      expect(find.text(m.wear.sessionExpiredShort), findsOneWidget);
      expect(find.text(m.wear.setUpAgain), findsOneWidget);
    });

    testWidgets('keeps everything the wearer could still do', (tester) async {
      await seedHouses(tester, [house(1, 'Ada House')]);
      await pumpDegraded(tester);

      // A 401 degrades rather than signing out: the caches stay readable and
      // the queue holds, so the page it is shown on must not lose its rows.
      expect(find.text(m.wear.house), findsOneWidget);
      expect(find.text(m.wear.settings), findsOneWidget);
      expect(find.text(m.common.logout), findsOneWidget);
    });

    testWidgets('carries the wearer to the button the rail pointed at', (
      tester,
    ) async {
      await pumpDegraded(tester);

      // The rail line spent the group label to buy a signpost, so the signpost
      // has to arrive at what it points at rather than one scroll above it.
      // Identity, the sync line, then the note explaining the state, then the
      // button: the wearer reads why on the way to the thing that fixes it.
      final list = tester.widget<SnapFocusList>(find.byType(SnapFocusList));
      final geometry = list.geometry!.value;

      expect(
        geometry.centredIndex,
        list.elements.indexWhere((e) => e.snappable),
        reason: 'while degraded, the first landable row is Set up again',
      );
      expect(
        geometry.centredDistance,
        lessThan(list.itemExtent / 2),
        reason: 'landed on the row, not merely nearest to it',
      );
    });
  });
}
