import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_wear/pantry_wear.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_rail.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/widgets/wear_choice_page.dart';

import 'wear_fixtures.dart';

/// What a turn of the bezel steers, and the rule that outranks the answer:
/// exactly one reader of the detent stream, whichever way the setting points.
///
/// A second reader is not an error anywhere — the stream is broadcast and
/// every covered page stays mounted, so it is simply one turn moving two
/// things. Rotary is not injectable over adb, so counting is the only way to
/// hold the rule.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const rotary = EventChannel('dev.casraf.pantry/rotary');
  const host = MethodChannel('dev.casraf.pantry/wear_host');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};
  final bezel = _StreamHandler();

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockStreamHandler(rotary, bezel)
      ..setMockMethodCallHandler(secureStorage, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'readAll':
            return Map<String, String>.from(storage);
          case 'write':
            storage[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            storage.remove(args['key'] as String);
            return null;
        }
        return null;
      });
    await PrefsService.instance.setWearCrownTurnsPages(false);
  });

  tearDown(() async {
    await PrefsService.instance.setWearCrownTurnsPages(false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockStreamHandler(rotary, null)
      ..setMockMethodCallHandler(host, null)
      ..setMockMethodCallHandler(secureStorage, null);
  });

  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      lists: [testList()],
      categories: [testCategory(id: 1, name: 'Dairy')],
      items: [
        testItem(id: 1, name: 'Milk', categoryId: 1),
        testItem(id: 2, name: 'Apples', categoryId: 1),
      ],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  /// One detent, delivered and then settled. Clockwise reads negative — the
  /// axis reports the opposite of what the wrist means.
  Future<void> turn(WidgetTester tester, {required bool clockwise}) async {
    // A platform stream event crosses the messenger on the real event loop,
    // which the tester's fake-async zone never runs — the emit is delivered
    // to nobody without this.
    await tester.runAsync(() async {
      bezel.emit(clockwise ? -1.0 : 1.0);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  /// Which page the shell is on. Found `skipOffstage: false`, or a route
  /// standing over the pager makes the question unanswerable rather than
  /// answering it — which is exactly when it is being asked.
  int page(WidgetTester tester) =>
      tester.widget<WearRail>(find.byType(WearRail, skipOffstage: false)).page;

  double? pagerOffset(WidgetTester tester) => tester
      .widget<PageView>(find.byType(PageView, skipOffstage: false))
      .controller
      ?.page;

  testWidgets('by default the crown scrolls the page, and the pager stays', (
    tester,
  ) async {
    await launch(tester);

    expect(RotaryService.instance.readerCount, 1);
    final before = tester.getTopLeft(find.text('Milk')).dy;
    await turn(tester, clockwise: true);

    // The turn was read — by the list, which moved under it.
    expect(tester.getTopLeft(find.text('Milk')).dy, lessThan(before));
    expect(page(tester), 0);
    expect(pagerOffset(tester), 0);
    expect(RotaryService.instance.readerCount, 1);
  });

  testWidgets('handed the pager, the crown turns pages and clockwise goes on', (
    tester,
  ) async {
    await PrefsService.instance.setWearCrownTurnsPages(true);
    await launch(tester);

    // The page went quiet as the shell took over; the count never doubles.
    expect(RotaryService.instance.readerCount, 1);

    await turn(tester, clockwise: true);
    expect(page(tester), 1);
    expect(pagerOffset(tester), 1);

    await turn(tester, clockwise: false);
    expect(page(tester), 0);
    expect(pagerOffset(tester), 0);
    expect(RotaryService.instance.readerCount, 1);

    // The ends hold: a turn back from the first page is not a way out of the
    // app, which is the leading edge's job and nothing else's.
    await turn(tester, clockwise: false);
    expect(page(tester), 0);
  });

  testWidgets('the setting is followed by a shell already drawn', (
    tester,
  ) async {
    await launch(tester);

    await PrefsService.instance.setWearCrownTurnsPages(true);
    await tester.pumpAndSettle();

    expect(RotaryService.instance.readerCount, 1);
    await turn(tester, clockwise: true);
    expect(page(tester), 1);
  });

  testWidgets('a route pushed over the pager takes the crown back', (
    tester,
  ) async {
    await PrefsService.instance.setWearCrownTurnsPages(true);
    await launch(tester);

    // Pushed straight onto the navigator, the way a page pushes its own routes
    // — which the shell's own bookkeeping never sees.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => WearChoicePage<int>(
            choices: const [WearChoice(value: 1, label: 'One')],
            selected: 1,
            empty: '',
            onSelected: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The route scrolls its own list, and the shell is not turning pages
    // underneath it.
    expect(RotaryService.instance.readerCount, 1);
    await turn(tester, clockwise: true);
    expect(page(tester), 0);

    navigator.pop();
    await tester.pumpAndSettle();

    // And the pop hands it back rather than leaving the shell mute.
    expect(RotaryService.instance.readerCount, 1);
    await turn(tester, clockwise: true);
    expect(page(tester), 1);
  });

  testWidgets('the row is offered on a watch that reports a rotary encoder', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          host,
          (call) async => call.method == 'hasRotary' ? true : null,
        );

    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text(m.wear.crown), findsOneWidget);
    expect(find.text(m.wear.crownScrollsList), findsOneWidget);
  });

  testWidgets('a watch with no rotary encoder is not offered the row', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          host,
          (call) async => call.method == 'hasRotary' ? false : null,
        );

    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text(m.wear.crown), findsNothing);
    // The rest of the page is untouched by the answer.
    expect(find.text(m.wear.refreshInterval), findsOneWidget);
  });

  /// A trip's five pages, opened on the done page — the one that used to read
  /// nothing, being the only page in either pager that was not a focus list.
  Future<void> launchDonePage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      stores: [testStore(id: 1, name: 'Corner shop')],
      categories: [testCategory(id: 1, name: 'Dairy')],
      session: testSession(activeStoreId: 1),
      items: [testItem(id: 9, name: 'Eggs', categoryId: 1)],
      done: [
        testItem(id: 1, name: 'Bread', categoryId: 1),
        testItem(id: 2, name: 'Milk', categoryId: 1),
        testItem(id: 3, name: 'Apples', categoryId: 1),
      ],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: WearShell(controller: controller)),
    );
    await tester.pumpAndSettle();
    // A session opens on its checklist; done is the next page along.
    await tester.fling(
      find.byType(PageView).first,
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(page(tester), 2);
  }

  testWidgets('the done page reads the crown like every other page', (
    tester,
  ) async {
    await launchDonePage(tester);

    expect(RotaryService.instance.readerCount, 1);
    final before = tester.getTopLeft(find.text('Bread')).dy;
    await turn(tester, clockwise: true);

    expect(tester.getTopLeft(find.text('Bread')).dy, lessThan(before));
    expect(page(tester), 2);
  });

  testWidgets('and goes quiet when the crown turns pages', (tester) async {
    await PrefsService.instance.setWearCrownTurnsPages(true);
    await launchDonePage(tester);

    // One reader, and it is the shell: the page holds no subscription to be
    // scrolled by the same detent. Its stillness cannot be asserted directly —
    // a `PageView` builds only the page on screen, so the turn that would
    // prove it also takes the page out of the tree — which is exactly why the
    // rule is carried by the count.
    expect(RotaryService.instance.readerCount, 1);
    await turn(tester, clockwise: true);

    expect(page(tester), 3);
    expect(RotaryService.instance.readerCount, 1);
  });

  testWidgets('a platform that will not answer leaves the row standing', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(host, (call) async {
          throw PlatformException(code: 'no');
        });

    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text(m.wear.crown), findsOneWidget);
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  /// Block bodies, deliberately: an expression body returns the value it
  /// assigns however the method is declared, and the sink coming back as a
  /// result is a codec failure on every activation.
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    _sink = events;
  }

  @override
  void onCancel(Object? arguments) {
    _sink = null;
  }

  void emit(Object? event) => _sink?.success(event);
}
