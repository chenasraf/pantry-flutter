import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/views/checklists/checklist_item_tile.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

Widget _tile({required bool isCardsView, required bool withMeta}) {
  return ChecklistItemTile(
    item: makeListItem(
      name: 'Milk',
      categoryId: withMeta ? 1 : null,
      quantity: withMeta ? '2 L' : null,
    ),
    category: withMeta ? makeCategory(id: 1, name: 'Dairy') : null,
    houseId: 1,
    isCardsView: isCardsView,
    onToggle: (_) {},
    onView: (_) {},
    onEdit: (_) {},
    onDelete: (_) {},
  );
}

void main() {
  // Regression: the checkbox tap target must not request an unbounded height.
  // A ListView gives its children an unbounded main-axis extent, the same
  // condition that previously threw "BoxConstraints forces an infinite height".
  for (final cardsView in [false, true]) {
    for (final withMeta in [false, true]) {
      testWidgets('renders in a ListView without infinite-height error '
          '(cards=$cardsView, meta=$withMeta)', (tester) async {
        await tester.pumpWidget(
          wrapForTest(
            ChangeNotifierProvider<PrefsService>.value(
              value: PrefsService.instance,
              child: ListView(
                children: [_tile(isCardsView: cardsView, withMeta: withMeta)],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Milk'), findsOneWidget);
      });
    }
  }

  testWidgets('tapping the checkbox toggles the item', (tester) async {
    ListItemTapRecorder recorder = ListItemTapRecorder();
    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: ListView(
            children: [
              ChecklistItemTile(
                item: makeListItem(name: 'Milk'),
                category: null,
                houseId: 1,
                isCardsView: false,
                onToggle: recorder.onToggle,
                onView: recorder.onView,
                onEdit: recorder.onEdit,
                onDelete: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    // Tap near the left edge, level with the box — the padding band that used
    // to fall through to the row's (view) tap action.
    final tile = tester.getRect(find.byType(ChecklistItemTile));
    await tester.tapAt(Offset(tile.left + 6, tile.center.dy));
    await tester.pump();

    expect(recorder.toggled, 1);
    expect(recorder.viewed, 0);
  });

  testWidgets('archive mode shows the archive glyph, not a checkbox', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: ListView(
            children: [
              ChecklistItemTile(
                item: makeListItem(name: 'Milk', archivedAt: 1000),
                category: null,
                houseId: 1,
                isCardsView: false,
                archiveMode: true,
                onToggle: (_) {},
                onView: (_) {},
                onUnarchive: (_) {},
                onPermanentDelete: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // The archive view is read-only: the leading control is an archive glyph
    // rather than the completion checkbox.
    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
  });

  testWidgets('archive-mode row tap opens the read-only view', (tester) async {
    ListItemTapRecorder recorder = ListItemTapRecorder();
    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: ListView(
            children: [
              ChecklistItemTile(
                item: makeListItem(name: 'Milk', archivedAt: 1000),
                category: null,
                houseId: 1,
                isCardsView: false,
                archiveMode: true,
                onToggle: recorder.onToggle,
                onView: recorder.onView,
                onUnarchive: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Milk'));
    await tester.pump();

    expect(recorder.viewed, 1);
    expect(recorder.toggled, 0);
  });
}

class ListItemTapRecorder {
  int toggled = 0;
  int viewed = 0;
  int edited = 0;
  void onToggle(dynamic _) => toggled++;
  void onView(dynamic _) => viewed++;
  void onEdit(dynamic _) => edited++;
}
