import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_mechanics.dart';
import 'package:pantry_wear/src/widgets/wear_metrics.dart';

/// How far a turn of the bezel actually carries a list.
///
/// A detent lands while the last one is still animating — that *is* a turn, not
/// an edge case — so the two paths that carry the crown both remember where
/// they were heading. They remembered it in a way that threw itself away: a
/// cancelled animation's future completes exactly like a finished one, so the
/// aim that interrupted a step was cleared by the step it interrupted, and
/// every detent after the first re-measured from a list still in motion.
///
/// Worn as "large lists take a long time to scroll through". Ten detents
/// carried one row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const rotary = EventChannel('dev.casraf.pantry/rotary');
  final bezel = _StreamHandler();

  setUp(() {
    WearShape.markFrom(const ['round']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(rotary, bezel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(rotary, null);
  });

  /// One detent. A platform stream event crosses the messenger on the real
  /// event loop, which the tester's fake-async zone never runs — without
  /// [WidgetTester.runAsync] the emit reaches nobody and every assertion here
  /// would pass against a list that never moved.
  Future<void> detent(WidgetTester tester) async {
    await tester.runAsync(() async {
      bezel.emit(-1.0);
      await Future<void>.delayed(Duration.zero);
    });
  }

  Future<ScrollController> pumpFocusList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SnapFocusList(
            controller: scroll,
            itemExtent: WearMetrics.itemExtent,
            rotaryActive: true,
            elements: [
              for (var i = 0; i < 40; i++)
                FocusElement(
                  extent: WearMetrics.itemExtent,
                  builder: (context, d) => Text('row $i'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scroll;
  }

  testWidgets('a turn of the bezel carries a row per detent', (tester) async {
    final scroll = await pumpFocusList(tester);

    // Spaced inside the 140ms step, which is what a turned bezel does.
    for (var i = 0; i < 10; i++) {
      await detent(tester);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    expect(scroll.offset, closeTo(10 * WearMetrics.itemExtent, 1));
  });

  testWidgets('and letting each detent settle carries it no further', (
    tester,
  ) async {
    final scroll = await pumpFocusList(tester);

    for (var i = 0; i < 10; i++) {
      await detent(tester);
      await tester.pumpAndSettle();
    }

    // The same distance the test above measures for a fast turn. Turning the
    // bezel quickly used to cost nine of these ten rows.
    expect(
      scroll.offset,
      closeTo(10 * WearMetrics.itemExtent, 1),
      reason: 'a detent mid-flight must add to the aim, not restart from it',
    );
  });

  testWidgets('a page with no focus list carries the same way', (tester) async {
    // The settings page and the pickers behind it steer a plain scrollable,
    // which held the identical bug.
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RotaryScrollable(
            controller: scroll,
            active: true,
            child: ListView(
              controller: scroll,
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 54, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await detent(tester);
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    expect(scroll.offset, closeTo(10 * 48, 1));
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  // A block body, not an arrow: `void` is a static annotation in Dart, so an
  // arrow here returns the sink and the mock handler errors on activation.
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
