import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_rail.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// Where the pager stands after the trip moves to another shop.
///
/// Moving is done from the progression page, and that page describes the walk
/// between shops rather than the shopping. Left where it was, the wearer
/// arrives in the next aisle looking at a list of shop names and has to swipe
/// to reach the one thing the move was made for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory dir;
  final storage = <String, String>{};

  final corner = testStore(id: 7, name: 'Corner shop');
  final hardware = testStore(id: 8, name: 'Hardware store', sortOrder: 1);

  setUp(() async {
    WearShape.markFrom(const ['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_advance_landing_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async => dir.path);
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      return switch (call.method) {
        'read' => storage[args['key'] as String],
        'write' => storage[args['key'] as String] = args['value'] as String,
        'readAll' => Map<String, String>.from(storage),
        _ => null,
      };
    });
    await PrefsService.instance.load();
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  Future<ChecklistsController> pumpTrip(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      stores: [corner, hardware],
      items: [for (var i = 1; i <= 4; i++) testItem(id: i, name: 'Item $i')],
      session: testSession(activeStoreId: 7, storeIds: const [7, 8]),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// Which page the shell is on, read off the rail — a `PageView` builds only
  /// the page on screen, so the pages themselves cannot say.
  int page(WidgetTester tester) =>
      tester.widget<WearRail>(find.byType(WearRail, skipOffstage: false)).page;

  /// Swipe the pager one page along, from the middle of the screen so the exit
  /// strip on the leading edge never sees it.
  Future<void> turnPage(WidgetTester tester, {required bool forward}) async {
    await tester.flingFrom(
      const Offset(225, 225),
      Offset(forward ? -150 : 150, 0),
      800,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('moving to another shop puts its list back under the thumb', (
    tester,
  ) async {
    final controller = await pumpTrip(tester);
    expect(page(tester), 1, reason: 'a trip opens on its checklist');

    await turnPage(tester, forward: false);
    expect(page(tester), 0, reason: 'progression, where the move is made');

    controller.seedSession(
      testSession(activeStoreId: 8, storeIds: const [7, 8]),
    );
    await tester.pumpAndSettle();

    expect(page(tester), 1);
  });

  testWidgets('a poll that reports the same shop leaves the pager alone', (
    tester,
  ) async {
    final controller = await pumpTrip(tester);

    await turnPage(tester, forward: false);
    expect(page(tester), 0);

    controller.seedSession(
      testSession(activeStoreId: 7, storeIds: const [7, 8]),
    );
    await tester.pumpAndSettle();

    // Every poll re-emits the trip. Landing on the checklist for each of them
    // would take the page the wearer chose away from them once a minute.
    expect(page(tester), 0);
  });
}
