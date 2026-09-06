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
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// When the live-trip chip is on the watch face and when it is not.
///
/// The chip outlives the process that posted it, so none of this can be settled
/// by what the app remembers: a launch acts on the trip it finds, and the only
/// thing that extends the half hour Android gives the chip is posting it again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const chip = MethodChannel('dev.casraf.pantry/ongoing_activity');
  const tile = MethodChannel('dev.casraf.pantry/tile');
  const dataLayer = MethodChannel('dev.casraf.pantry/data_layer');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final calls = <MethodCall>[];
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    calls.clear();
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(chip, (call) async {
        calls.add(call);
        return null;
      })
      ..setMockMethodCallHandler(tile, (_) async => null)
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
    ChecklistService.instance
      ..cacheLists(1, [testList()])
      ..selectedListId = testList().id;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(chip, null)
      ..setMockMethodCallHandler(tile, null)
      ..setMockMethodCallHandler(dataLayer, null)
      ..setMockMethodCallHandler(secureStorage, null);
    ShoppingService.instance.cacheSession(null);
  });

  List<String> methods() => [for (final c in calls) c.method];

  /// The launch path: the real controller, unstarted, met by the shell. A cache
  /// store's debounced write cannot drain inside the tester's fake-async zone,
  /// so the trip is laid down in real time before the pump.
  Future<ChecklistsController> launch(
    WidgetTester tester, {
    ShoppingSession? session,
  }) async {
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
    controller.start();
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('a trip found in the cache puts the chip on the watch face', (
    tester,
  ) async {
    final controller = await launch(
      tester,
      session: testSession(activeStoreId: 7, storeIds: const [7]),
    );

    expect(methods(), contains('post'));
    // One string and nothing else. A store the phone can advance past would be
    // a chip naming a shop the wearer has walked out of, inside the window the
    // timeout does not bound.
    final posted = calls.firstWhere((c) => c.method == 'post');
    expect((posted.arguments as Map).keys, ['status']);
    expect((posted.arguments as Map)['status'], isNotEmpty);

    controller.dispose();
  });

  testWidgets('a launch with no trip clears a chip left behind by one', (
    tester,
  ) async {
    final controller = await launch(tester);

    // The trip may have been closed on the phone while the watch was dead, so
    // finding none is a reason to cancel rather than nothing to do.
    expect(methods(), contains('cancel'));
    expect(methods(), isNot(contains('post')));

    controller.dispose();
  });

  testWidgets('a poll that finds the same trip does not redraw the chip', (
    tester,
  ) async {
    final controller = await launch(
      tester,
      session: testSession(activeStoreId: 7, storeIds: const [7]),
    );
    calls.clear();

    await controller.refresh();
    await tester.pumpAndSettle();

    expect(calls, isEmpty);

    controller.dispose();
  });

  testWidgets('coming back to a live trip restarts its half hour', (
    tester,
  ) async {
    final controller = await launch(
      tester,
      session: testSession(activeStoreId: 7, storeIds: const [7]),
    );
    calls.clear();

    controller.setActive(false);
    controller.setActive(true);
    await tester.pumpAndSettle();

    // Re-posting an identical notification is the only thing that resets
    // Android's timeout, which is what makes an expiry mid-shop recoverable.
    expect(methods(), contains('post'));

    controller.dispose();
  });

  testWidgets('going quiet leaves the chip up', (tester) async {
    final controller = await launch(
      tester,
      session: testSession(activeStoreId: 7, storeIds: const [7]),
    );
    calls.clear();

    controller.setActive(false);
    await tester.pumpAndSettle();

    // A wrist going down is the wearer walking an aisle, not the trip ending.
    expect(calls, isEmpty);

    controller.dispose();
  });
}
