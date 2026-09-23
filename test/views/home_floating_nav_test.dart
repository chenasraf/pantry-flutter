import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/home/home_floating_nav.dart';

import '../helpers/test_app.dart';

void main() {
  const destinations = <NavDestination>[
    (icon: Icons.checklist, label: 'Checklists'),
    (icon: Icons.photo, label: 'Photo Board'),
    (icon: Icons.sticky_note_2, label: 'Notes Wall'),
  ];

  // The Spanish set is the widest the app ships, and the one that decides
  // whether a label fits beside two other icons and the trailing button.
  const longDestinations = <NavDestination>[
    (icon: Icons.checklist, label: 'Listas'),
    (icon: Icons.photo, label: 'Tablero de fotos'),
    (icon: Icons.sticky_note_2, label: 'Muro de notas'),
  ];

  /// Width the label is actually revealed at — the clip around it, not the
  /// text's own laid-out size, which stays constant however little shows.
  double revealedWidth(WidgetTester tester, String label) => tester
      .getSize(
        find
            .ancestor(
              of: find.text(label, skipOffstage: false),
              matching: find.byType(ClipRect),
            )
            .first,
      )
      .width;

  Widget harness(
    List<NavDestination> dests, {
    int index = 0,
    NavPrimaryAction? action,
    bool visible = true,
    ValueChanged<int>? onTap,
  }) => wrapForTest(
    HomeFloatingNav(
      pageController: PageController(initialPage: index),
      currentIndex: index,
      onTap: onTap ?? (_) {},
      destinations: dests,
      action: action,
      visible: visible,
    ),
  );

  testWidgets('labels only the selected destination', (tester) async {
    await tester.pumpWidget(harness(destinations, index: 0));
    await tester.pumpAndSettle();

    expect(revealedWidth(tester, 'Checklists'), greaterThan(0));
    // The other two are collapsed to nothing, down to their icon alone.
    expect(revealedWidth(tester, 'Photo Board'), 0);
    expect(revealedWidth(tester, 'Notes Wall'), 0);
    expect(
      tester.getSize(find.byIcon(Icons.photo)).width,
      greaterThan(0),
      reason: 'unselected destinations keep their icon',
    );
  });

  testWidgets('the pill hugs its destinations at the leading edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      harness(
        destinations,
        action: const NavPrimaryAction(icon: Icons.add, label: 'Add'),
      ),
    );
    await tester.pumpAndSettle();

    // The label's nearest Material ancestor is the pill itself; the slots
    // inside it draw their indicator with a plain decoration.
    final pill = tester.getRect(
      find
          .ancestor(
            of: find.text('Checklists'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(pill.left, lessThan(20), reason: 'sits at the leading edge');

    // Destinations sit one gap apart rather than spread across the pill — the
    // property that survives however wide the active label happens to be.
    final photo = tester.getCenter(find.byIcon(Icons.photo));
    final notes = tester.getCenter(find.byIcon(Icons.sticky_note_2));
    expect((notes.dx - photo.dx).abs(), lessThan(70));
  });

  testWidgets('the widest locale still fits a phone-width bar', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (var i = 0; i < longDestinations.length; i++) {
      await tester.pumpWidget(
        harness(
          longDestinations,
          index: i,
          action: const NavPrimaryAction(icon: Icons.add, label: 'Add'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'destination $i overflowed the pill',
      );
    }
  });

  testWidgets('a destination skipped over never expands on the way past', (
    tester,
  ) async {
    final pageController = PageController();
    final jump = ValueNotifier<({int from, int to})?>((from: 0, to: 2));
    addTearDown(jump.dispose);

    await tester.pumpWidget(
      wrapForTest(
        Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView(
                controller: pageController,
                children: const [
                  SizedBox.shrink(),
                  SizedBox.shrink(),
                  SizedBox.shrink(),
                ],
              ),
            ),
            HomeFloatingNav(
              pageController: pageController,
              jump: jump,
              currentIndex: 0,
              onTap: (_) {},
              destinations: destinations,
              action: null,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Halfway to the far destination, the page is sitting exactly on the one
    // in between — the moment the middle label used to reach full width.
    unawaited(
      pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 280),
        curve: Curves.linear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(
      revealedWidth(tester, 'Photo Board'),
      0,
      reason: 'the skipped destination stayed collapsed',
    );
    // ...while the two real endpoints are mid-handover.
    expect(revealedWidth(tester, 'Checklists'), greaterThan(0));
    expect(revealedWidth(tester, 'Notes Wall'), greaterThan(0));
  });

  testWidgets('taps report the destination index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(harness(destinations, index: 0, onTap: taps.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sticky_note_2));
    expect(taps, [2]);
  });

  testWidgets('drops the pill when there is nowhere else to go', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const [
        (icon: Icons.checklist, label: 'Checklists'),
      ], action: const NavPrimaryAction(icon: Icons.add, label: 'Add')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checklists'), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('draws nothing with neither destinations nor an action', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const []));
    await tester.pumpAndSettle();

    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('an extended action shows its label beside the icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        destinations,
        action: const NavPrimaryAction(
          icon: Icons.play_arrow,
          label: 'Resume shopping',
          extended: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume shopping'), findsOneWidget);
  });

  testWidgets('a section claiming the bottom edge slides the bar away', (
    tester,
  ) async {
    await tester.pumpWidget(harness(destinations, visible: false));
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find
          .ancestor(
            of: find.byIcon(Icons.checklist),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    );
    expect(opacity.opacity, 0);
  });
}
