import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/checklist_sort_button.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('renders sort icon button', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        ChecklistSortButton(currentSort: 'custom', onSelected: (_) {}),
      ),
    );
    expect(find.byIcon(Icons.sort), findsOneWidget);
  });

  testWidgets('tapping opens menu with all sort options', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        ChecklistSortButton(currentSort: 'custom', onSelected: (_) {}),
      ),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Name A–Z'), findsOneWidget);
    expect(find.text('Name Z–A'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('selecting an option invokes onSelected with value', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      wrapForTest(
        ChecklistSortButton(
          currentSort: 'custom',
          onSelected: (v) => selected = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Name A–Z'));
    await tester.pumpAndSettle();

    expect(selected, 'name_asc');
  });
}
