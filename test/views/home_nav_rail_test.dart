import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:pantry/views/home/home_nav_rail.dart';

import '../helpers/test_app.dart';

void main() {
  const destinations = <NavDestination>[
    (icon: Icons.checklist, label: 'Checklists'),
    (icon: Icons.photo, label: 'Photo Board'),
    (icon: Icons.sticky_note_2, label: 'Notes Wall'),
  ];

  List<NavRailNested> lists({VoidCallback? onTap}) => [
    NavRailNested(
      icon: Icons.shopping_cart,
      color: const Color(0xFF4CAF50),
      label: 'Groceries',
      selected: true,
      onTap: onTap ?? () {},
    ),
    NavRailNested(
      icon: Icons.build,
      color: null,
      label: 'Hardware',
      selected: false,
      onTap: onTap ?? () {},
    ),
  ];

  Widget harness({
    bool extended = false,
    int index = 0,
    int? nestedIndex = 0,
    List<NavRailNested>? nested,
    ValueChanged<int>? onDestinationSelected,
  }) => wrapForTest(
    HomeNavRail(
      extended: extended,
      selectedIndex: index,
      onDestinationSelected: onDestinationSelected ?? (_) {},
      destinations: destinations,
      nestedIndex: nestedIndex,
      nested: nested ?? lists(),
    ),
  );

  /// Vertical midpoint of the row carrying [label], used to assert ordering.
  double centerY(WidgetTester tester, String label) =>
      tester.getCenter(find.text(label)).dy;

  testWidgets('nests the lists under the checklists destination', (
    tester,
  ) async {
    await tester.pumpWidget(harness(extended: true));
    await tester.pumpAndSettle();

    expect(
      centerY(tester, 'Checklists'),
      lessThan(centerY(tester, 'Groceries')),
    );
    expect(centerY(tester, 'Groceries'), lessThan(centerY(tester, 'Hardware')));
    expect(
      centerY(tester, 'Hardware'),
      lessThan(centerY(tester, 'Photo Board')),
    );
  });

  testWidgets('the list icon sits on its own color', (tester) async {
    await tester.pumpWidget(harness(extended: true));
    await tester.pumpAndSettle();

    final badge = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.shopping_cart),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = badge.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFF4CAF50));
    expect(decoration.borderRadius, isNotNull);

    // White ink over a mid-green, which is too dark to carry black.
    final icon = tester.widget<Icon>(find.byIcon(Icons.shopping_cart));
    expect(icon.color, Colors.white);
  });

  testWidgets('a colorless list falls back to the theme tint', (tester) async {
    await tester.pumpWidget(harness(extended: true));
    await tester.pumpAndSettle();

    final badge = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.build),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((badge.decoration as BoxDecoration).color, isNotNull);
  });

  testWidgets('the narrow rail keeps the lists as tooltipped icons', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is Tooltip && w.message == 'Groceries'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
  });

  testWidgets('tapping a list reports it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(extended: true, nested: lists(onTap: () => taps++)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('without a nested destination the rail is just sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(extended: true, nestedIndex: -1, nested: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checklists'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);
  });
}
