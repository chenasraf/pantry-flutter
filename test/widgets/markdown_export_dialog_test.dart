import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/views/checklists/markdown_export_dialog.dart';

import '../helpers/test_models.dart';

void main() {
  Widget wrapped(Widget child) => MaterialApp(
    home: Scaffold(body: Builder(builder: (_) => child)),
  );

  Category? noCategory(int? id) => null;

  final items = [
    makeListItem(id: 1, name: 'Apples', done: false),
    makeListItem(id: 2, name: 'Bananas', done: true),
  ];

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('excludes completed items by default', (tester) async {
    await tester.pumpWidget(
      wrapped(
        MarkdownExportDialog(
          listName: 'Groceries',
          items: items,
          categoryFor: noCategory,
        ),
      ),
    );

    final text = fieldText(tester);
    expect(text, contains('# Groceries'));
    expect(text, contains('Apples'));
    expect(text, isNot(contains('Bananas')));
  });

  testWidgets('including completed regenerates with done items', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapped(
        MarkdownExportDialog(
          listName: 'Groceries',
          items: items,
          categoryFor: noCategory,
        ),
      ),
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    final text = fieldText(tester);
    expect(text, contains('- [ ] Apples'));
    expect(text, contains('- [x] Bananas'));
  });

  testWidgets('toggling include back off discards manual edits', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapped(
        MarkdownExportDialog(
          listName: 'Groceries',
          items: items,
          categoryFor: noCategory,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'edited by hand');
    expect(fieldText(tester), 'edited by hand');

    // A content-changing toggle re-seeds from the list, dropping the edit.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(fieldText(tester), contains('# Groceries'));
    expect(fieldText(tester), isNot(equals('edited by hand')));
  });
}
