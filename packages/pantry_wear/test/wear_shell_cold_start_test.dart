import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_rail.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// What the watch opens on, when the trip it should open on is only knowable
/// from the cache.
///
/// `mode` derives from the session, and the session is read asynchronously, so
/// at `initState` it is always `browse` however live the trip is. Drawing the
/// pager on that answer means every cold start mid-shop — launcher, Tile, deep
/// link, watch-face chip — puts the wearer on the empty browse checklist and
/// then takes it away from them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dataLayer = MethodChannel('dev.casraf.pantry/data_layer');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      // The mirror reports scope as soon as one resolves, and a watch with no
      // paired phone is not what this is about.
      ..setMockMethodCallHandler(dataLayer, (_) async => false)
      ..setMockMethodCallHandler(secureStorage, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'readAll':
            return Map<String, String>.from(storage);
          case 'write':
            storage[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            storage.remove(args['key'] as String);
            return null;
        }
        return null;
      });
    await PrefsService.instance.setLastHouseId(1);
    HouseService.instance.cache.setList('houses', [
      const House(
        id: 1,
        name: 'Home',
        ownerUid: 'casraf',
        role: 'owner',
        createdAt: 0,
        updatedAt: 0,
      ),
    ], (h) => h.toJson());
    // A watch that has been used before. Resolving scope from nothing writes
    // it back, and a cache store's debounced write cannot drain inside the
    // widget tester's fake-async zone — which is not what these are about.
    ChecklistService.instance
      ..cacheLists(1, [testList()])
      ..selectedListId = testList().id;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(dataLayer, null)
      ..setMockMethodCallHandler(secureStorage, null);
    ShoppingService.instance.cacheSession(null);
  });

  /// The real controller, unstarted — which is the state the shell meets at
  /// `initState` on every launch. The shell only starts the one it makes
  /// itself, so driving [ChecklistsController.start] here is the launch path
  /// with the fetch legs failing the way they do off a network.
  Future<ChecklistsController> launch(
    WidgetTester tester, {
    ShoppingSession? session,
  }) async {
    // A cache store's debounced write cannot drain inside the widget tester's
    // fake-async zone, so the trip is laid down in real time before the pump.
    if (session != null) {
      await tester.runAsync(() async {
        ShoppingService.instance.cacheSession(session);
        await ShoppingService.instance.cache.flush();
      });
    }
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController();
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    return controller;
  }

  /// The page set that is up, and where in it. A `PageView` builds only the
  /// page on screen, so the pages themselves cannot say which set is mounted —
  /// the rail names both, and the dots it draws are what a wearer sees change.
  ({int page, int pages})? pager(WidgetTester tester) {
    final rail = find.byType(WearRail);
    if (rail.evaluate().isEmpty) return null;
    final widget = tester.widget<WearRail>(rail);
    return (page: widget.page, pages: widget.pages);
  }

  testWidgets('a trip in the cache is the pager the watch opens on', (
    tester,
  ) async {
    final controller = await launch(
      tester,
      session: testSession(activeStoreId: 7, storeIds: const [7]),
    );
    // Nothing until the read resolves — not an empty pager, which is the one
    // thing that cannot be un-drawn.
    expect(pager(tester), isNull);

    controller.start();
    // Frame by frame to the settle: the defect is not that the browse pager is
    // drawn for long, it is that it is drawn at all. Every frame is either the
    // gate or the session's five pages; the browse four never appear.
    for (var i = 0; i < 6; i++) {
      final drawn = pager(tester);
      if (drawn != null) expect(drawn, (page: 1, pages: 5));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(pager(tester), (page: 1, pages: 5));
    // The dots and the pager disagreeing is its own failure, so the page the
    // rail claims has to be the page the pager is actually on.
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller?.page?.round(),
      1,
    );
    // A cold start is not a transition, so nothing is held out of the wearer's
    // way when the app finally draws.
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.byType(WearRail),
              matching: find.byType(IgnorePointer),
            ),
          )
          .every((w) => !w.ignoring),
      isTrue,
    );

    // The poll it started outlives the tree unless it is torn down here: a
    // tearDown callback runs after the binding has already checked for it.
    controller.dispose();
  });

  testWidgets('no trip still opens on the checklist, and opens at all', (
    tester,
  ) async {
    final controller = await launch(tester);
    expect(pager(tester), isNull);

    controller.start();
    await tester.pumpAndSettle();

    // The gate ends on the read finishing, so the ordinary launch reaches its
    // pager rather than sitting on the ground plane for good.
    expect(pager(tester), (page: 0, pages: 4));

    controller.dispose();
  });
}
