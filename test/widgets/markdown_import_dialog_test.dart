import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/markdown_import_dialog.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/services/item_memory_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';

void main() {
  Widget wrapped(Widget child) => MaterialApp(
    home: Scaffold(body: Builder(builder: (_) => child)),
  );

  const dairy = Category(
    id: 12,
    houseId: 1,
    name: 'Dairy',
    icon: 'milk',
    color: '#3366ff',
    sortOrder: 0,
    createdAt: 0,
    updatedAt: 0,
  );

  MarkdownImportDialog dialog({
    String reusePref = 'ask',
    bool reuseFeatureAvailable = true,
    List<Category> categories = const [],
  }) => MarkdownImportDialog(
    houseId: 1,
    listId: 3,
    categories: categories,
    reusePref: reusePref,
    reuseFeatureAvailable: reuseFeatureAvailable,
  );

  /// Opens [build] over a host route; the returned getter reads what the
  /// dialog popped with.
  Future<MarkdownImportResult? Function()> open(
    WidgetTester tester,
    MarkdownImportDialog Function() build,
  ) async {
    MarkdownImportResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<MarkdownImportResult>(
                  context: context,
                  builder: (_) => build(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  // The paste field is the first TextField in the dialog.
  Finder pasteField() => find.byType(TextField).first;

  testWidgets('parsing pasted text lists found items, all selected', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(dialog()));

    await tester.enterText(pasteField(), '- Milk\n- [x] Bread');
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text('2 items found'), findsOneWidget);
    // All selected by default → confirm label counts both.
    expect(find.text('Add 2 items'), findsOneWidget);

    final boxes = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .toList();
    expect(boxes.where((b) => b.value == true).length, 2);
  });

  testWidgets('non-empty text with no items shows the empty message', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(dialog()));

    await tester.enterText(pasteField(), 'just some prose, no list here');
    await tester.pumpAndSettle();

    expect(find.text('No list items found in the text.'), findsOneWidget);
    expect(find.text('Add 0 items'), findsOneWidget);
  });

  testWidgets('deselect all disables the confirm button', (tester) async {
    await tester.pumpWidget(wrapped(dialog()));

    await tester.enterText(pasteField(), '- Milk\n- Bread');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deselect all'));
    await tester.pumpAndSettle();

    expect(find.text('Add 0 items'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add 0 items'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('reuse checkbox shows when pref is "ask"', (tester) async {
    await tester.pumpWidget(wrapped(dialog(reusePref: 'ask')));
    await tester.enterText(pasteField(), '- Milk');
    await tester.pumpAndSettle();

    expect(
      find.text('Reuse existing items instead of adding duplicates'),
      findsOneWidget,
    );
  });

  testWidgets('reuse checkbox hidden when pref already "reuse"', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(dialog(reusePref: 'reuse')));
    await tester.enterText(pasteField(), '- Milk');
    await tester.pumpAndSettle();

    expect(
      find.text('Reuse existing items instead of adding duplicates'),
      findsNothing,
    );
  });

  testWidgets('reuse checkbox hidden when feature unavailable', (tester) async {
    await tester.pumpWidget(
      wrapped(dialog(reusePref: 'ask', reuseFeatureAvailable: false)),
    );
    await tester.enterText(pasteField(), '- Milk');
    await tester.pumpAndSettle();

    expect(
      find.text('Reuse existing items instead of adding duplicates'),
      findsNothing,
    );
  });

  testWidgets('confirm emits one submission per selected item', (tester) async {
    MarkdownImportResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<MarkdownImportResult>(
                  context: context,
                  builder: (_) => dialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(pasteField(), '- Milk\n- [x] Bread');
    await tester.pumpAndSettle();

    // Drop the second item from the selection.
    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add 1 item'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.submissions.length, 1);
    expect(result!.submissions.single.name, 'Milk');
    expect(result!.forceReuse, isFalse);
  });

  group('guesses', () {
    tearDown(() => ServerVersionService.instance.debugSeed());

    testWidgets('a typed quantity splits off the name', (tester) async {
      final result = await open(tester, dialog);
      await tester.enterText(pasteField(), '- 2 L Milk');
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('2 L'), findsOneWidget);

      await tester.tap(find.text('Add 1 item'));
      await tester.pumpAndSettle();
      final s = result()!.submissions.single;
      expect(s.name, 'Milk');
      expect(s.quantity, '2 L');
      expect(s.suggestionRejected, isNull);
    });

    testWidgets('dropping a typed quantity keeps the line whole', (
      tester,
    ) async {
      final result = await open(tester, dialog);
      await tester.enterText(pasteField(), '- 2 L Milk');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove suggestion'));
      await tester.pumpAndSettle();
      expect(find.text('2 L Milk'), findsOneWidget);

      await tester.tap(find.text('Add 1 item'));
      await tester.pumpAndSettle();
      final s = result()!.submissions.single;
      expect(s.name, '2 L Milk');
      expect(s.quantity, isNull);
      expect(s.suggestionRejected, isNull);
    });

    testWidgets('a remembered category is offered and can be dropped', (
      tester,
    ) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.40.0'),
      );
      ItemMemoryService.instance.debugSeed(1, {
        'categories': [
          {
            'nameKey': 'milk',
            'categoryId': 12,
            'uses': 3,
            'rejections': 0,
            'updatedAt': 1,
          },
        ],
        'quantities': [
          {'listId': 3, 'nameKey': 'milk', 'quantity': '1 L'},
        ],
        'serverTime': 1,
      });
      final result = await open(
        tester,
        () => dialog(categories: const [dairy]),
      );
      await tester.enterText(pasteField(), '- Milk');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListView, 'Dairy'), findsOneWidget);
      expect(find.text('1 L'), findsOneWidget);

      // Drop both: the remembered amount first, then the category.
      await tester.tap(find.byTooltip('Remove suggestion').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove suggestion').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove suggestion'), findsNothing);

      await tester.tap(find.text('Add 1 item'));
      await tester.pumpAndSettle();
      final s = result()!.submissions.single;
      expect(s.name, 'Milk');
      expect(s.quantity, isNull);
      expect(s.categoryId, isNull);
      expect(s.suggestionRejected?.toJson(), {
        'categoryId': 12,
        'quantity': true,
      });
    });

    testWidgets('a picked shared category wins over a guess', (tester) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.40.0'),
      );
      ItemMemoryService.instance.debugSeed(1, {
        'categories': [
          {
            'nameKey': 'milk',
            'categoryId': 12,
            'uses': 3,
            'rejections': 0,
            'updatedAt': 1,
          },
        ],
        'serverTime': 1,
      });
      const bakery = Category(
        id: 13,
        houseId: 1,
        name: 'Bakery',
        icon: 'bread',
        color: '#aa7733',
        sortOrder: 1,
        createdAt: 0,
        updatedAt: 0,
      );
      final result = await open(
        tester,
        () => dialog(categories: const [dairy, bakery]),
      );
      await tester.enterText(pasteField(), '- Milk');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove suggestion'), findsOneWidget);

      await tester.ensureVisible(find.text('Bakery'));
      await tester.tap(find.text('Bakery'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove suggestion'), findsNothing);

      await tester.tap(find.text('Add 1 item'));
      await tester.pumpAndSettle();
      final s = result()!.submissions.single;
      expect(s.categoryId, 13);
      expect(s.suggestionRejected, isNull);
    });
  });
}
