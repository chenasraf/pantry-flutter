import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_centre.dart';

import 'wear_fixtures.dart';

/// What the wearer's own font size does to the watch.
///
/// The rows are drawn to fixed extents, which is what lets the list snap and
/// the falloff be quoted in rows — and a fixed extent is exactly what a larger
/// system font runs out of. The geometry has to move with the type or the line
/// leaves through the bottom of its card, so these pump the same screens at a
/// size the wearer can choose and ask that everything still fits.
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
    dir = await Directory.systemTemp.createTemp('wear_font_size_test');
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
    SyncManager.instance.pendingCount.value = 0;
    await dir.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester, {double? fontScale}) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (fontScale != null) {
      tester.platformDispatcher.textScaleFactorTestValue = fontScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      lists: [testList()],
      // Chipped and quantified: the centre card's second line is the tightest
      // thing on the page, and a bare item would leave it empty.
      items: [
        for (var i = 1; i <= 8; i++)
          testItem(
            id: i,
            name: 'Item $i',
            quantity: '2 kg',
            categoryId: 7,
            storeIds: const [3],
            labelIds: const [1, 2],
          ),
      ],
      categories: [testCategory(id: 7, name: 'Vegetables')],
      stores: [testStore(id: 3, name: 'Corner shop')],
      done: [testItem(id: 90, name: 'Bought already', done: true)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  /// The extent the checklist is laying its rows out at.
  double rowExtent(WidgetTester tester) =>
      tester.widget<SnapFocusList>(find.byType(SnapFocusList).first).itemExtent;

  testWidgets('a larger system font is given a taller row to sit in', (
    tester,
  ) async {
    await pumpShell(tester);
    final drawn = rowExtent(tester);

    await pumpShell(tester, fontScale: 1.3);
    expect(rowExtent(tester), greaterThan(drawn));
  });

  testWidgets('and a smaller one does not shrink the target', (tester) async {
    await pumpShell(tester);
    final drawn = rowExtent(tester);

    // A row is aimed at with a fingertip, and a fingertip does not shrink with
    // the type.
    await pumpShell(tester, fontScale: 0.8);
    expect(rowExtent(tester), drawn);
  });

  for (final scale in const [1.15, 1.3, 1.5, 2.0]) {
    testWidgets('nothing runs off its card at a font scale of $scale', (
      tester,
    ) async {
      await pumpShell(tester, fontScale: scale);
      // An overflow is reported as an exception on the frame that paints it,
      // which is the whole of "the wearer's line is cut off by the edge".
      expect(tester.takeException(), isNull);
      expect(find.text('Item 1'), findsOneWidget);
    });
  }

  testWidgets('nor on any other page of the pager', (tester) async {
    await pumpShell(tester, fontScale: 1.5);

    // Notes, photos and the account page in turn: a `PageView` builds only
    // what is near the fold, so the one page that opens proves nothing about
    // the three behind it.
    for (var i = 0; i < 3; i++) {
      await tester.flingFrom(
        const Offset(225, 225),
        const Offset(-150, 0),
        800,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'page ${i + 1}');
    }
  });

  testWidgets('nor in the panel the rail drops', (tester) async {
    await pumpShell(tester, fontScale: 1.5);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Both buttons whole and on the glass, rather than the second one pushed
    // through the bottom edge by the first one's larger label.
    for (final label in [m.shopping.startShopping, m.wear.changeList]) {
      final button = tester.getRect(find.text(label));
      expect(button.top, greaterThanOrEqualTo(0));
      expect(button.bottom, lessThanOrEqualTo(450));
    }
  });

  testWidgets('the rail says a queue in its dot and never in a count', (
    tester,
  ) async {
    SyncManager.instance.pendingCount.value = 3;
    await pumpShell(tester);

    // The rail's title line is the width of a wrist. What is waiting is the
    // account page's to say, beside the identity it is queued against.
    expect(find.text(m.wear.queued(3)), findsNothing);
  });

  testWidgets('a page that outgrows the glass scrolls instead of clipping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WearCentre(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 12; i++)
                  const Text(
                    'a line of prose the wearer asked to be able to '
                    'read',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    // The last line is below the fold rather than cut off at it.
    expect(position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('and stays centred while it still fits', (tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WearCentre(child: Text('one short line'))),
      ),
    );
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.maxScrollExtent, 0);
    expect(tester.getCenter(find.text('one short line')).dy, closeTo(225, 1));
  });
}
