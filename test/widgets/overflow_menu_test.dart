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

  group('flattenOverflowGroups', () {
    const select = OverflowGroup(
      id: 'select',
      icon: Icons.checklist,
      label: 'Select',
      entries: [
        OverflowAction(value: 'select', icon: Icons.checklist, label: 'Sel'),
      ],
    );
    const manage = OverflowGroup(
      id: 'manage',
      icon: Icons.tune,
      label: 'Manage',
      entries: [
        OverflowAction(value: 'a', icon: Icons.tag, label: 'A'),
        OverflowAction(value: 'b', icon: Icons.store, label: 'B'),
      ],
    );
    const trash = OverflowGroup(
      id: 'trash',
      icon: Icons.delete,
      label: 'Trash',
      entries: [OverflowAction(value: 't', icon: Icons.delete, label: 'T')],
    );
    const archive = OverflowGroup(
      id: 'archive',
      icon: Icons.archive,
      label: 'Archive',
      entries: [OverflowAction(value: 'r', icon: Icons.archive, label: 'R')],
    );
    const empty = OverflowGroup(
      id: 'empty',
      icon: Icons.block,
      label: 'Empty',
      entries: [OverflowDivider()],
    );

    String describe(List<OverflowEntry> entries) => entries
        .map(
          (e) => switch (e) {
            OverflowDivider() => '|',
            OverflowHeader(:final label) => '#$label',
            _ => overflowEntryValue(e)!,
          },
        )
        .join(' ');

    test('heads multi-row groups and runs single-row ones together', () {
      final flat = flattenOverflowGroups([
        select,
        manage,
        empty,
        trash,
        archive,
      ]);

      expect(describe(flat), 'select | #Manage a b | t r');
    });

    test('a group reduced to one row loses its header', () {
      expect(
        describe(
          flattenOverflowGroups([
            manage,
            const OverflowGroup(
              id: 'view',
              icon: Icons.sort,
              label: 'View',
              entries: [
                OverflowDivider(),
                OverflowCheckboxAction(value: 'v', label: 'V', checked: true),
              ],
            ),
          ]),
        ),
        '#Manage a b | v',
      );
    });

    test('soleEntry ignores dividers and headers', () {
      expect(trash.soleEntry, isA<OverflowAction>());
      expect(manage.soleEntry, isNull);
      expect(empty.isEmpty, isTrue);
    });
  });

  testWidgets('sheet renders headers and radio rows', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        opener((context) {
          showOverflowMenuSheet(context, const [
            OverflowHeader('Sort & view'),
            OverflowRadioAction(value: 'n', label: 'Newest', selected: true),
          ]);
        }),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(OverflowHeaderLabel), findsOneWidget);
    expect(
      tester
          .widget<OverflowRadioIndicator>(find.byType(OverflowRadioIndicator))
          .selected,
      isTrue,
    );
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
