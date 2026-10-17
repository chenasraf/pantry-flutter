import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/overflow_grid.dart';
import 'package:pantry/widgets/overflow_menu.dart';

import '../helpers/test_app.dart';

void main() {
  Widget opener(void Function(BuildContext) onTap) => Builder(
    builder: (context) =>
        TextButton(onPressed: () => onTap(context), child: const Text('open')),
  );

  /// A "View" group of a radio set and a checkbox, a "Manage" group of two
  /// actions, and a one-row "Trash" group, all driven by [state].
  List<OverflowGroup> groupsFor(ValueNotifier<Map<String, Object>> state) => [
    OverflowGroup(
      id: 'view',
      icon: Icons.sort,
      label: 'Sort & view',
      entries: [
        for (final key in ['newest', 'oldest'])
          OverflowRadioAction(
            value: 'sort_$key',
            label: key == 'newest' ? 'Newest' : 'Oldest',
            selected: state.value['sort'] == key,
          ),
        const OverflowDivider(),
        OverflowCheckboxAction(
          value: 'toggle',
          label: 'Show who added',
          checked: state.value['toggle'] == true,
        ),
      ],
    ),
    const OverflowGroup(
      id: 'manage',
      icon: Icons.tune,
      label: 'Manage',
      entries: [
        OverflowAction(value: 'categories', icon: Icons.tag, label: 'Cats'),
        OverflowAction(value: 'stores', icon: Icons.store, label: 'Stores'),
      ],
    ),
    const OverflowGroup(
      id: 'trash',
      icon: Icons.delete_outline,
      label: 'Trash',
      entries: [
        OverflowAction(
          value: 'view_trash',
          icon: Icons.delete_outline,
          label: 'View trash',
        ),
      ],
    ),
    const OverflowGroup(
      id: 'empty',
      icon: Icons.block,
      label: 'Empty group',
      entries: [OverflowDivider()],
    ),
  ];

  late ValueNotifier<Map<String, Object>> state;
  late List<String> toggled;
  String? picked;

  setUp(() {
    state = ValueNotifier({'sort': 'newest', 'toggle': false});
    toggled = [];
    picked = null;
  });

  void onToggle(String value) {
    toggled.add(value);
    if (value.startsWith('sort_')) {
      state.value = {...state.value, 'sort': value.substring(5)};
    } else {
      state.value = {...state.value, 'toggle': state.value['toggle'] != true};
    }
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        opener((context) async {
          picked = await showOverflowGridSheet(
            context,
            groups: () => groupsFor(state),
            listenable: state,
            onToggle: onToggle,
          );
        }),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a tile per non-empty group, chevrons on drill-ins', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.byType(OverflowGroupTile), findsNWidgets(3));
    expect(find.text('Sort & view'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Empty group'), findsNothing);
    // A one-row group is labelled by its row, which it opens directly.
    expect(find.text('View trash'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
  });

  testWidgets('a one-row group acts on its row and closes', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('View trash'));
    await tester.pumpAndSettle();

    expect(picked, 'view_trash');
    expect(find.byType(OverflowGroupTile), findsNothing);
  });

  testWidgets('a group opens its page, and back returns to the grid', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNothing);
    expect(find.text('Cats'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNWidgets(3));
    expect(find.text('Cats'), findsNothing);
  });

  testWidgets('system back leaves the page before closing the sheet', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNWidgets(3));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNothing);
    expect(picked, isNull);
  });

  testWidgets('the sheet drops from the top and swipes up to close', (
    tester,
  ) async {
    await openSheet(tester);

    final screen = tester.getSize(find.byType(MaterialApp));
    final tile = tester.getRect(find.byType(OverflowGroupTile).first);
    expect(tile.top, lessThan(screen.height / 2));

    await tester.fling(
      find.byType(OverflowGroupTile).first,
      const Offset(0, -300),
      1500,
    );
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNothing);
    expect(picked, isNull);
  });

  testWidgets('an action row on a page closes with its value', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();

    expect(picked, 'stores');
    expect(toggled, isEmpty);
  });

  testWidgets('toggles apply in place and keep the page open', (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Sort & view'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show who added'));
    await tester.pumpAndSettle();

    expect(toggled, ['sort_oldest', 'toggle']);
    expect(picked, isNull);
    expect(find.text('Oldest'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    final selected = tester
        .widgetList<OverflowRadioIndicator>(find.byType(OverflowRadioIndicator))
        .map((r) => r.selected)
        .toList();
    expect(selected, [false, true]);
  });

  testWidgets('the popover shows the same grid and drills in', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        Align(
          alignment: AlignmentDirectional.topEnd,
          child: opener((context) async {
            picked = await showOverflowGridPopover(
              context,
              groups: () => groupsFor(state),
              listenable: state,
              onToggle: onToggle,
            );
          }),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(OverflowGroupTile), findsNWidgets(3));

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cats'));
    await tester.pumpAndSettle();

    expect(picked, 'categories');
    expect(find.byType(OverflowGroupTile), findsNothing);
  });

  testWidgets('icons in a row line up whatever their labels wrap to', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 460,
          child: OverflowGridPanel(
            dense: true,
            groups: () => const [
              OverflowGroup(
                id: 'short',
                icon: Icons.checklist,
                label: 'Short',
                entries: [
                  OverflowAction(value: 'a', icon: Icons.checklist, label: 'A'),
                ],
              ),
              OverflowGroup(
                id: 'long',
                icon: Icons.history,
                label: 'History',
                entries: [
                  OverflowAction(
                    value: 'b',
                    icon: Icons.history,
                    label: 'A label long enough to wrap onto two lines',
                  ),
                ],
              ),
            ],
            onAction: (_) {},
            onToggle: (_) {},
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byIcon(Icons.checklist)).dy,
      tester.getTopLeft(find.byIcon(Icons.history)).dy,
    );
  });

  group('the list popover', () {
    Future<void> openList(WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: opener((context) async {
              picked = await showOverflowListPopover(
                context,
                entries: () => groupsFor(state).first.entries,
                listenable: state,
                onToggle: onToggle,
              );
            }),
          ),
        ),
      );
      await tester.tap(find.text('open'));
    }

    testWidgets('zooms and fades in from its anchor', (tester) async {
      await openList(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      final scale = tester.widget<ScaleTransition>(
        find
            .ancestor(
              of: find.text('Newest'),
              matching: find.byType(ScaleTransition),
            )
            .first,
      );
      expect(scale.scale.value, inExclusiveRange(0.94, 1.0));
      await tester.pumpAndSettle();
    });

    testWidgets('toggles keep it open and an action closes it', (tester) async {
      await openList(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();
      expect(toggled, ['sort_oldest']);
      expect(find.text('Show who added'), findsOneWidget);

      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('Show who added'), findsNothing);
      expect(picked, isNull);
    });

    testWidgets('without onToggle every row closes it', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          opener((context) async {
            picked = await showOverflowListPopover(
              context,
              entries: () => groupsFor(state).first.entries,
            );
          }),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show who added'));
      await tester.pumpAndSettle();

      expect(picked, 'toggle');
      expect(find.text('Show who added'), findsNothing);
    });
  });
}
