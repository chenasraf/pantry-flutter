import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/widgets/checklist_selector.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

void main() {
  ChecklistList listA() =>
      makeChecklistList(id: 1, name: 'Groceries', icon: 'cart');
  ChecklistList listB() =>
      makeChecklistList(id: 2, name: 'Hardware', icon: 'wrench');

  testWidgets('renders current list name in the closed state', (tester) async {
    final a = listA();
    final b = listB();
    await tester.pumpWidget(
      wrapForTest(
        ChecklistSelector(
          lists: [a, b],
          currentList: a,
          onSelected: (_) {},
          onCreateNew: () {},
        ),
      ),
    );

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Hardware'), findsNothing);
  });

  testWidgets('opening the dropdown shows all lists plus "+ New list"', (
    tester,
  ) async {
    final a = listA();
    final b = listB();
    await tester.pumpWidget(
      wrapForTest(
        ChecklistSelector(
          lists: [a, b],
          currentList: a,
          onSelected: (_) {},
          onCreateNew: () {},
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();

    // Each list shows in the open menu in addition to the closed-state copy.
    expect(find.text('Groceries'), findsNWidgets(2));
    expect(find.text('Hardware'), findsOneWidget);
    expect(find.text('New list'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('selecting a different list invokes onSelected', (tester) async {
    final a = listA();
    final b = listB();
    ChecklistList? selected;
    var createNewCalls = 0;

    await tester.pumpWidget(
      wrapForTest(
        ChecklistSelector(
          lists: [a, b],
          currentList: a,
          onSelected: (l) => selected = l,
          onCreateNew: () => createNewCalls++,
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();

    expect(selected?.id, 2);
    expect(createNewCalls, 0);
  });

  testWidgets('selecting "+ New list" invokes onCreateNew and not onSelected', (
    tester,
  ) async {
    final a = listA();
    final b = listB();
    ChecklistList? selected;
    var createNewCalls = 0;

    await tester.pumpWidget(
      wrapForTest(
        ChecklistSelector(
          lists: [a, b],
          currentList: a,
          onSelected: (l) => selected = l,
          onCreateNew: () => createNewCalls++,
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New list'));
    await tester.pumpAndSettle();

    expect(createNewCalls, 1);
    expect(selected, isNull);
  });

  testWidgets(
    'after tapping "+ New list" the closed state still shows the current list',
    (tester) async {
      final a = listA();
      final b = listB();

      await tester.pumpWidget(
        wrapForTest(
          ChecklistSelector(
            lists: [a, b],
            currentList: a,
            onSelected: (_) {},
            onCreateNew: () {},
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();

      // Sentinel must not leak into the closed-state label.
      expect(find.text('New list'), findsNothing);
      expect(find.text('Groceries'), findsOneWidget);
    },
  );
}
