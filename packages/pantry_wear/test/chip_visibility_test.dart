import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_wear/src/account/chip_visibility_page.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// What a checklist row is allowed to say, and who decides it.
///
/// Two halves that only mean something together: three of the nine kinds had
/// no draw code on the watch at all, so a picker offering them would have been
/// a lie about the screen it was on. The tests pair each toggle with the thing
/// it turns off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory dir;
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_chips_test');
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
    await PrefsService.instance.setHiddenItemChips({});
  });

  tearDown(() async {
    await PrefsService.instance.setHiddenItemChips({});
    await dir.delete(recursive: true);
  });

  Future<void> pumpRows(WidgetTester tester, ChecklistsController c) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home: WearShell(controller: c)));
    await tester.pumpAndSettle();
  }

  group('the three kinds the watch could not draw', () {
    testWidgets('labels draw as a count under one generic icon', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: [
            testItem(id: 1, name: 'Milk', labelIds: [7, 8, 9]),
          ],
        ),
      );

      // Three labels cost one short chip, not three long ones — and the id
      // list carries the number, so no label model came with it.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('an item with no labels spends nothing on them', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: [testItem(id: 1, name: 'Milk')],
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('one-time means it leaves the list, not that it has no rule', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: [
            testItem(id: 1, name: 'Milk', deleteOnDone: true),
            testItem(id: 2, name: 'Bread'),
          ],
        ),
      );

      // The phone's own reading of the flag, so one pref key means one thing
      // on both devices. A staple has neither glyph.
      expect(find.byIcon(Icons.looks_one_outlined), findsOneWidget);
      expect(find.byIcon(Icons.repeat), findsNothing);
    });

    testWidgets('a schedule wins over the flag, exactly as on the phone', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: [
            testItem(
              id: 1,
              name: 'Milk',
              deleteOnDone: true,
              rrule: 'FREQ=WEEKLY',
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.repeat), findsOneWidget);
      expect(find.byIcon(Icons.looks_one_outlined), findsNothing);
    });

    testWidgets('the list is named where the rail is not naming it', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testAllLists(),
          lists: [
            testList(id: 4, name: 'Groceries'),
            testList(id: 5, name: 'Hardware'),
          ],
          items: [
            testItem(id: 1, name: 'Milk', listId: 4),
            testItem(id: 2, name: 'Screws', listId: 5),
          ],
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('and dropped where it would only repeat the rail', (
      tester,
    ) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(id: 4, name: 'Groceries'),
          lists: [testList(id: 4, name: 'Groceries')],
          items: [testItem(id: 1, name: 'Milk', listId: 4)],
        ),
      );

      // Once on the rail, and never a second time as a chip on every row of
      // the one list it could possibly be — the same rule that drops the chip
      // naming the current grouping.
      expect(find.text('Groceries'), findsOneWidget);
    });
  });

  group('quantity is drawn once, and the toggle reaches it', () {
    threeWithQuantities() => [
      testItem(id: 1, name: 'Milk', quantity: '2 L'),
      testItem(id: 2, name: 'Bread', quantity: '500 g'),
      testItem(id: 3, name: 'Eggs', quantity: '12'),
    ];

    testWidgets('every row draws its quantity exactly once', (tester) async {
      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: threeWithQuantities(),
        ),
      );

      for (final quantity in ['2 L', '500 g', '12']) {
        expect(find.text(quantity), findsOneWidget);
      }
    });

    testWidgets('turning it off reaches the title line, not just a chip', (
      tester,
    ) async {
      // The toggle used to govern a meta chip while the title line drew its
      // own copy unconditionally, so switching quantity off left it on screen
      // on every row that was not the centred one.
      await PrefsService.instance.setHiddenItemChips({
        ItemChipKind.quantity.key,
      });

      await pumpRows(
        tester,
        ChecklistsController.seeded(
          houseId: 1,
          list: testList(),
          lists: [testList()],
          items: threeWithQuantities(),
        ),
      );

      for (final quantity in ['2 L', '500 g', '12']) {
        expect(find.text(quantity), findsNothing);
      }
    });
  });

  group('the picker', () {
    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WearSettingsPage())),
      );
      await tester.pumpAndSettle();
    }

    Future<void> pumpPicker(WidgetTester tester) async {
      await pumpSettings(tester);
      await tester.tap(await revealRow(tester, m.settings.visibleChipsTitle));
      await tester.pumpAndSettle();
    }

    testWidgets('offers all nine, and says how many are showing', (
      tester,
    ) async {
      await pumpSettings(tester);

      await revealRow(tester, m.settings.visibleChipsTitle);
      expect(find.text(m.wear.nSelected(9)), findsOneWidget);

      await tester.tap(find.text(m.settings.visibleChipsTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ChipVisibilityPage), findsOneWidget);
      for (final kind in ItemChipKind.values) {
        expect(
          await revealRow(tester, switch (kind) {
            ItemChipKind.category => m.settings.chipNames.category,
            ItemChipKind.store => m.settings.chipNames.store,
            ItemChipKind.label => m.settings.chipNames.label,
            ItemChipKind.quantity => m.settings.chipNames.quantity,
            ItemChipKind.price => m.settings.chipNames.price,
            ItemChipKind.note => m.settings.chipNames.note,
            ItemChipKind.oneTime => m.settings.chipNames.oneTime,
            ItemChipKind.recurring => m.settings.chipNames.recurring,
            ItemChipKind.list => m.settings.chipNames.list,
          }),
          findsOneWidget,
          reason: 'a toggle that changes nothing would be a lie about the row',
        );
      }
    });

    testWidgets('a toggle writes the phone\'s own stored format', (
      tester,
    ) async {
      await pumpPicker(tester);

      await tester.tap(await revealRow(tester, m.settings.chipNames.price));
      await tester.pumpAndSettle();

      expect(PrefsService.instance.hiddenItemChips, {'price'});
      expect(
        storage['hidden_item_chips'],
        'price',
        reason:
            'written through the phone\'s per-kind setter, so a later pair '
            'can seed from what this one leaves behind',
      );

      await tester.tap(await revealRow(tester, m.settings.chipNames.price));
      await tester.pumpAndSettle();

      expect(PrefsService.instance.hiddenItemChips, isEmpty);
    });

    testWidgets('the page stays open while the set is being chosen', (
      tester,
    ) async {
      await pumpPicker(tester);

      await tester.tap(await revealRow(tester, m.settings.chipNames.price));
      await tester.pumpAndSettle();
      await tester.tap(await revealRow(tester, m.settings.chipNames.note));
      await tester.pumpAndSettle();

      // A set is not finished until the wearer says so, and the back gesture
      // every pushed route already carries is what says it.
      expect(find.byType(ChipVisibilityPage), findsOneWidget);
      expect(PrefsService.instance.hiddenItemChips, {'price', 'note'});
    });
  });

  testWidgets('a hidden kind stops drawing on the row', (tester) async {
    await PrefsService.instance.setHiddenItemChips({'label'});

    await pumpRows(
      tester,
      ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        items: [
          testItem(id: 1, name: 'Milk', labelIds: [7, 8, 9]),
        ],
      ),
    );

    expect(find.text('3'), findsNothing);
  });
}
