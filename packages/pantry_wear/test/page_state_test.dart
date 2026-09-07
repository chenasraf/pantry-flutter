import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_rail.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';

import 'wear_fixtures.dart';

/// What a page remembers while the wearer is looking at another one.
///
/// A `PageView` builds only the page on screen, so a page swiped away is torn
/// down and rebuilt from nothing on the way back. On a wrist that costs more
/// than on a phone: the way back to where you were is a swipe *through* the
/// pages that just forgot themselves, and there is no scrollbar to re-find your
/// place with.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory dir;
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(const ['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_page_state_test');
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

  Future<ChecklistsController> pumpShell(
    WidgetTester tester, {
    int items = 12,
  }) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      lists: [testList()],
      items: [
        for (var i = 1; i <= items; i++) testItem(id: i, name: 'Item $i'),
      ],
      done: [
        testItem(id: 90, name: 'Bought already', done: true),
        testItem(id: 91, name: 'Also bought', done: true),
      ],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// Which page the shell is on, read off the rail — a page type cannot say,
  /// since more than one is mounted now.
  int page(WidgetTester tester) =>
      tester.widget<WearRail>(find.byType(WearRail, skipOffstage: false)).page;

  /// Swipe the pager one page along. From the middle of the screen, so the
  /// exit strip on the leading edge never sees it.
  Future<void> turnPage(WidgetTester tester, {required bool forward}) async {
    await tester.flingFrom(
      const Offset(225, 225),
      Offset(forward ? -150 : 150, 0),
      800,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an expanded Done section is still expanded on the way back', (
    tester,
  ) async {
    // Few enough that the Done header is on screen: a sliver never builds a
    // row far below the fold, so asserting against one proves nothing.
    await pumpShell(tester, items: 2);

    final header = find.text(m.checklists.completedCount(2));
    expect(header, findsOneWidget);
    expect(find.text('Bought already'), findsNothing);

    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(find.text('Bought already'), findsOneWidget);

    await turnPage(tester, forward: true);
    expect(page(tester), 1);
    await turnPage(tester, forward: false);
    expect(page(tester), 0);

    // Collapsing on the way past would make the section something the wearer
    // has to re-open every time they glance at another page.
    expect(find.text('Bought already'), findsOneWidget);
  });

  testWidgets('and a list comes back where it was left, not at the top', (
    tester,
  ) async {
    await pumpShell(tester);

    final list = tester.state<SnapFocusListState>(
      find.byType(SnapFocusList).first,
    );
    // The page's own controller, held across the round trip: if the page were
    // torn down this would be disposed and have no clients to answer with.
    final scroll = list.widget.controller;
    list.step(4);
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    expect(offset, greaterThan(0));

    await turnPage(tester, forward: true);
    await turnPage(tester, forward: false);

    expect(scroll.hasClients, isTrue, reason: 'the page survived the trip');
    expect(scroll.offset, closeTo(offset, 1));
  });
}
