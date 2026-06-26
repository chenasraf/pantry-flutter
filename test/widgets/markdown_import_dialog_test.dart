import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/markdown_import_dialog.dart';

void main() {
  Widget wrapped(Widget child) => MaterialApp(
    home: Scaffold(body: Builder(builder: (_) => child)),
  );

  MarkdownImportDialog dialog({
    String reusePref = 'ask',
    bool reuseFeatureAvailable = true,
  }) => MarkdownImportDialog(
    categories: const [],
    reusePref: reusePref,
    reuseFeatureAvailable: reuseFeatureAvailable,
  );

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
}
