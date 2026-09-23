import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/checklists/checklist_item_tile.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/widgets/item_description.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// Longer than any row under test can draw, so every placement has to decide
/// what to do about it rather than happening to fit.
const _long =
    'a description far too long to sit on one line of a phone-width row, '
    'which is the whole reason it is truncated';

/// An item's description is a chip's worth of icon until the reader asks for
/// it on the row itself, at which point it either takes a line of its own —
/// and the icon goes, having nothing left to say the line doesn't — or fills
/// out the chip it was hiding behind, trading width for a row that stays one
/// line tall. Either way it truncates rather than growing the row.
void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  late ChecklistsController controller;

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'read':
              return storage[args['key'] as String];
            case 'write':
              storage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
          }
          return null;
        });
    // Editing from the dialog enqueues a sync op; offline it stays queued
    // rather than failing against no server and leaving a retry timer behind.
    SyncManager.instance.setOnline(false);
    controller = ChecklistsController(houseId: 1);
  });

  tearDown(() async {
    controller.dispose();
    await PrefsService.instance.clear();
    SyncManager.instance.setOnline(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<void> pumpTile(WidgetTester tester, ListItem item) async {
    await tester.pumpWidget(
      wrapForTest(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PrefsService>.value(
              value: PrefsService.instance,
            ),
            ChangeNotifierProvider<ChecklistsController>.value(
              value: controller,
            ),
          ],
          child: ListView(
            children: [
              ChecklistItemTile(
                item: item,
                category: null,
                houseId: 1,
                isCardsView: false,
                onToggle: (_) {},
                onView: (_) {},
                onEdit: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('the icon stands in for the description by default', (
    tester,
  ) async {
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '1.5%'),
    );

    expect(find.byType(ItemDescriptionLine), findsNothing);
    expect(find.byIcon(Icons.notes), findsOneWidget);
  });

  testWidgets('the description takes a line of its own once asked for', (
    tester,
  ) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '1.5%'),
    );

    expect(find.text('1.5%'), findsOneWidget);
    // Never both: the icon would only repeat the line beside it.
    expect(find.byIcon(Icons.notes), findsNothing);
  });

  testWidgets('the line reads as text, not as markup', (tester) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '**1.5%**\n- fresh'),
    );

    expect(find.text('1.5% · fresh'), findsOneWidget);
  });

  testWidgets('one line, however long the description', (tester) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: _long),
    );

    final line = tester.widget<Text>(
      find.descendant(
        of: find.byType(ItemDescriptionLine),
        matching: find.byType(Text),
      ),
    );
    expect(line.maxLines, 1);
    expect(line.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the line opens the description in full', (tester) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '1.5%'),
    );

    await tester.tap(find.byType(ItemDescriptionLine));
    await tester.pumpAndSettle();

    expect(find.text(m.checklists.viewItem.descriptionLabel), findsOneWidget);
  });

  testWidgets('turning the description detail off hides the line too', (
    tester,
  ) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await PrefsService.instance.setItemChipVisible(
      ItemChipKind.note.key,
      false,
    );
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '1.5%'),
    );

    expect(find.byType(ItemDescriptionLine), findsNothing);
    expect(find.byIcon(Icons.notes), findsNothing);
  });

  testWidgets('a description with no text of its own keeps the icon', (
    tester,
  ) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    await pumpTile(
      tester,
      makeListItem(id: 1, name: 'Milk', description: '![](photo.png)'),
    );

    expect(find.byType(ItemDescriptionLine), findsNothing);
    expect(find.byIcon(Icons.notes), findsOneWidget);
  });

  testWidgets('selecting an item is not interrupted by its description', (
    tester,
  ) async {
    await PrefsService.instance.setItemDescriptionDisplay('line');
    var toggled = 0;
    await tester.pumpWidget(
      wrapForTest(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PrefsService>.value(
              value: PrefsService.instance,
            ),
            ChangeNotifierProvider<ChecklistsController>.value(
              value: controller,
            ),
          ],
          child: ListView(
            children: [
              ChecklistItemTile(
                item: makeListItem(id: 1, name: 'Milk', description: '1.5%'),
                category: null,
                houseId: 1,
                isCardsView: false,
                selectionMode: true,
                onSelectToggle: (_) => toggled++,
                onToggle: (_) {},
                onView: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('1.5%'));
    await tester.pumpAndSettle();

    expect(toggled, 1);
    expect(find.text(m.checklists.viewItem.descriptionLabel), findsNothing);
  });

  group('in the chip', () {
    testWidgets('the note chip carries the description rather than standing '
        'in for it', (tester) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: '**1.5%**'),
      );

      // The row stays one line tall: the text joins the chip it would
      // otherwise have hidden behind.
      expect(find.byType(ItemDescriptionLine), findsNothing);
      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(find.text('1.5%'), findsOneWidget);
    });

    testWidgets('a long description truncates instead of growing the chip', (
      tester,
    ) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: _long),
      );

      final label = tester.widget<Text>(
        find.descendant(
          of: find.byType(ItemDescriptionChip),
          matching: find.byType(Text),
        ),
      );
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and is capped rather than taking the row', (tester) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: _long),
      );

      // Half of the row's *content* width, which is narrower still than the
      // tile once the checkbox and padding are out of it.
      final tile = tester.getSize(find.byType(ChecklistItemTile)).width;
      final chip = tester.getSize(find.byType(ItemDescriptionChip)).width;
      expect(chip, lessThan(tile / 2));
    });

    testWidgets('but a hover reads what the cap cut off', (tester) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: _long),
      );

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(ItemDescriptionChip),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, _long);
      // Hover only: a long press on a touch screen still belongs to the row,
      // where it starts a selection.
      expect(tooltip.triggerMode, TooltipTriggerMode.manual);
    });

    testWidgets('and a long press over it still starts a selection', (
      tester,
    ) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      var selected = 0;
      await tester.pumpWidget(
        wrapForTest(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<PrefsService>.value(
                value: PrefsService.instance,
              ),
              ChangeNotifierProvider<ChecklistsController>.value(
                value: controller,
              ),
            ],
            child: ListView(
              children: [
                ChecklistItemTile(
                  item: makeListItem(id: 1, name: 'Milk', description: '1.5%'),
                  category: null,
                  houseId: 1,
                  isCardsView: false,
                  onLongPressSelect: (_) => selected++,
                  onToggle: (_) {},
                  onView: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(ItemDescriptionChip));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('so the item\'s other details stay beside it', (tester) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', quantity: '2 L', description: _long),
      );

      // Same run of the Wrap: an uncapped chip would have taken the full width
      // and pushed the quantity onto a line of its own.
      expect(
        tester.getCenter(find.byType(ItemDescriptionChip)).dy,
        tester.getCenter(find.text('2 L')).dy,
      );
    });

    testWidgets('tapping the chip opens the description in full', (
      tester,
    ) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: '1.5%'),
      );

      await tester.tap(find.text('1.5%'));
      await tester.pumpAndSettle();

      expect(find.text(m.checklists.viewItem.descriptionLabel), findsOneWidget);
    });

    testWidgets('a description with no text of its own leaves the chip its '
        'icon', (tester) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: '![](photo.png)'),
      );

      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(
        tester
            .widget<ItemDescriptionChip>(find.byType(ItemDescriptionChip))
            .text,
        isNull,
      );
    });

    testWidgets('turning the description detail off hides the chip too', (
      tester,
    ) async {
      await PrefsService.instance.setItemDescriptionDisplay('chip');
      await PrefsService.instance.setItemChipVisible(
        ItemChipKind.note.key,
        false,
      );
      await pumpTile(
        tester,
        makeListItem(id: 1, name: 'Milk', description: '1.5%'),
      );

      expect(find.byIcon(Icons.notes), findsNothing);
      expect(find.text('1.5%'), findsNothing);
    });
  });
}
