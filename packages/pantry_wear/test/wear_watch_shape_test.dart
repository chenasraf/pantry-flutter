import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/shopping/trip_reminders_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/wear_choice_page.dart';
import 'package:pantry_wear/src/widgets/wear_metrics.dart';

import 'wear_fixtures.dart';

/// Whether what the watch draws is inside the glass it is drawn on.
///
/// A round screen is a circle inscribed in the square the viewport reports, so
/// three quarters of the reported width is simply not there at the top and
/// bottom of it. A page laid out to the square puts its rows in the part of it
/// that does not exist, and the wearer reads the middle of every line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const host = MethodChannel('dev.casraf.pantry/wear');

  late Directory dir;
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(const ['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_shape_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async => dir.path);
    messenger.setMockMethodCallHandler(host, (call) async => true);
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      final key = call.arguments['key'] as String? ?? '';
      return switch (call.method) {
        'read' => storage[key],
        'write' => storage[key] = call.arguments['value'] as String,
        'readAll' => Map<String, String>.from(storage),
        _ => null,
      };
    });
    await PrefsService.instance.load();
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  // The glass in logical pixels, which is the only size that tells the truth
  // here: a watch reports around 227 of them for 454 real ones, and the rail's
  // lines are a fixed number of pixels tall whatever the screen is. Measured at
  // twice that, everything looks comfortable that is not.
  const diameter = 227.0;

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(diameter * 2, diameter * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  /// How far outside the circle the furthest corner of [rect] falls, in pixels.
  double overhang(Rect rect) {
    const centre = Offset(diameter / 2, diameter / 2);
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    final furthest = corners.map((c) => (c - centre).distance).reduce(math.max);
    return furthest - diameter / 2;
  }

  /// Every line the page is drawing, and whether the glass holds it.
  ///
  /// Text boxes rather than rows: a row is a pill, and the bezel takes the
  /// corners a pill does not have. What Google's rule is about — and what a
  /// wearer loses — is the line inside it.
  void expectTextInsideGlass(WidgetTester tester, {String? reason}) {
    const screen = Rect.fromLTWH(0, 0, diameter, diameter);
    for (final element in find.byType(Text).evaluate()) {
      final rect = tester.getRect(find.byElementPredicate((e) => e == element));
      if (rect.isEmpty) continue;
      // A line the wearer has not scrolled to yet is laid out past the bottom
      // of the glass, and a line half onto the screen is what scrolling looks
      // like. Neither is the screen's shape cutting a line the wearer is being
      // shown, which is the whole of what this asks.
      if (!screen.contains(rect.topLeft) ||
          !screen.contains(rect.bottomRight)) {
        continue;
      }
      expect(
        overhang(rect),
        lessThanOrEqualTo(0.5),
        reason:
            '${(element.widget as Text).data} is outside the round screen'
            '${reason == null ? '' : ' — $reason'}',
      );
    }
  }

  List<WearChoice<int>> choices(int count) => [
    for (var i = 0; i < count; i++)
      WearChoice(
        value: i,
        label: 'A household with a long enough name to fill a row $i',
        icon: Icons.home_outlined,
      ),
  ];

  testWidgets('the settings page keeps every row inside the circle', (
    tester,
  ) async {
    await pump(tester, const WearSettingsPage());
    expectTextInsideGlass(tester);
  });

  testWidgets('and still does with the list scrolled to either end', (
    tester,
  ) async {
    await pump(tester, const WearSettingsPage());
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));

    for (final at in [
      scroll.position.minScrollExtent,
      scroll.position.maxScrollExtent,
    ]) {
      scroll.position.jumpTo(at);
      await tester.pumpAndSettle();
      expectTextInsideGlass(tester, reason: 'scrolled to $at');
    }
  });

  testWidgets('a picker keeps its choices inside the circle', (tester) async {
    await pump(
      tester,
      WearChoicePage<int>(
        choices: choices(6),
        selected: 0,
        empty: 'nothing to choose',
        onSelected: (_) async {},
      ),
    );
    expectTextInsideGlass(tester);
  });

  testWidgets('and so does the one that takes a set', (tester) async {
    await pump(
      tester,
      WearMultiChoicePage<int>(
        choices: choices(6),
        selected: const {0, 2},
        empty: 'nothing to choose',
        onChanged: (_) {},
      ),
    );
    expectTextInsideGlass(tester);
  });

  testWidgets('a page of prose keeps its lines inside the circle', (
    tester,
  ) async {
    await pump(
      tester,
      TripRemindersPage(
        reminders: [
          for (var i = 0; i < 3; i++)
            ShoppingReminder(
              id: i,
              houseId: 1,
              text:
                  'Bring the tote bags, and the deposit bottles that have been '
                  'by the door since the weekend',
              showOn: ShoppingReminderMoment.onStart,
              enabled: true,
              position: i,
              createdAt: 0,
              updatedAt: 0,
            ),
        ],
      ),
    );
    expectTextInsideGlass(tester);
  });

  testWidgets('a list name too long for the rail ends in a visible ellipsis', (
    tester,
  ) async {
    const name = 'Weekly big shop for the whole household and the dog';
    final list = testList(name: name);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: list,
      lists: [list],
      items: [testItem(id: 1, name: 'Milk')],
    );
    addTearDown(controller.dispose);
    await pump(tester, WearShell(controller: controller));

    final title = find.text(name);
    expect(title, findsOneWidget);

    // Elided, and elided somewhere the wearer can see: the rail's title line
    // rides where the glass has least width, so a line laid out to the width
    // the viewport reports puts its own ellipsis behind the bezel — which
    // reads as a name that simply stops.
    final rendered = tester.renderObject<RenderParagraph>(title);
    expect(
      rendered.didExceedMaxLines,
      isTrue,
      reason: 'the fixture has to be long enough to elide at all',
    );
    expect(overhang(tester.getRect(title)), lessThanOrEqualTo(0.5));
  });

  testWidgets('and the check is one a square layout fails', (tester) async {
    // The layout the pages had: rows laid out to the width the viewport
    // reports, which on a round screen is the width of a square that is mostly
    // not there.
    await pump(
      tester,
      Scaffold(
        body: ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 44,
          ),
          children: const [
            SizedBox(height: 49, child: Center(child: Text('Language'))),
          ],
        ),
      ),
    );

    // Not the text's own width — the box it is laid out in, which is where the
    // next word would go.
    final rect = tester.getRect(
      find
          .ancestor(of: find.text('Language'), matching: find.byType(SizedBox))
          .first,
    );
    expect(overhang(rect), greaterThan(0.5));
  });

  testWidgets('the band a page of prose takes is the square the circle holds', (
    tester,
  ) async {
    late EdgeInsetsDirectional band;
    await pump(
      tester,
      Builder(
        builder: (context) {
          band = WearMetrics.bandInsets(context);
          return const SizedBox.shrink();
        },
      ),
    );

    // Half the inscribed square's diagonal is the radius, so each side gives up
    // (1 - 1/sqrt(2)) / 2 of the diameter.
    final given = (1 - 1 / math.sqrt2) / 2 * diameter;
    expect(band.start, closeTo(given, 1));
    expect(band.top, closeTo(given, 1));
  });
}
