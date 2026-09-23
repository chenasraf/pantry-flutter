import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/overflow_menu.dart';
import 'package:pantry_core/utils/note_sort.dart';
import 'package:pantry_core/utils/photo_sort.dart';

import '../helpers/test_app.dart';

void main() {
  Widget opener(void Function(BuildContext) onTap) => Builder(
    builder: (context) =>
        TextButton(onPressed: () => onTap(context), child: const Text('open')),
  );

  testWidgets('sheet renders actions and checkboxes and returns the pick', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrapForTest(
        opener((context) async {
          picked = await showOverflowMenuSheet(context, const [
            OverflowAction(
              value: 'select',
              icon: Icons.checklist,
              label: 'Select photos',
            ),
            OverflowDivider(),
            OverflowCheckboxAction(
              value: 'folders_first',
              label: 'Folders first',
              checked: true,
            ),
          ]);
        }),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Select photos'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);

    await tester.tap(find.text('Folders first'));
    await tester.pumpAndSettle();

    expect(picked, 'folders_first');
  });

  testWidgets('normalizeOverflow collapses stray dividers', (tester) async {
    final entries = normalizeOverflow(const [
      OverflowDivider(),
      OverflowAction(value: 'a', icon: Icons.sort, label: 'A'),
      OverflowDivider(),
      OverflowDivider(),
      OverflowAction(value: 'b', icon: Icons.sort, label: 'B'),
      OverflowDivider(),
    ]);

    expect(entries.length, 3);
    expect(entries[1], isA<OverflowDivider>());
  });

  testWidgets('sort dialog lists the photo sort options and returns the pick', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrapForTest(
        opener((context) async {
          picked = await showOverflowSortDialog(
            context,
            title: 'Sort',
            options: photoSortOptions(),
            selected: 'custom',
          );
        }),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Caption A–Z'), findsOneWidget);
    expect(find.text('Caption Z–A'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();

    expect(picked, 'newest');
  });

  testWidgets('sort dialog lists the note sort options', (tester) async {
    String? picked;
    await tester.pumpWidget(
      wrapForTest(
        opener((context) async {
          picked = await showOverflowSortDialog(
            context,
            title: 'Sort',
            options: noteSortOptions(),
            selected: 'newest',
          );
        }),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Title A–Z'), findsOneWidget);

    await tester.tap(find.text('Title Z–A'));
    await tester.pumpAndSettle();

    expect(picked, 'title_desc');
  });
}
