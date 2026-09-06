import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/widgets/wear_mechanics.dart';

/// Which edge the back gesture lives on.
///
/// Route (a) turns the system dismiss off for the whole app, so this strip is
/// the only way out of a pushed route — which makes the edge it sits on the
/// difference between a route the wearer can leave and one they cannot.
///
/// It follows the **device's** language, not the app's. Someone reading Pantry
/// in Hebrew on an English watch swipes back the way every other app on that
/// watch does, because the gesture was learnt out there rather than in here.
void main() {
  const size = 450.0;

  Future<bool Function()> pump(
    WidgetTester tester, {
    required Locale system,
    required TextDirection app,
  }) async {
    tester.view.physicalSize = const Size(size, size);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = system;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: app,
          child: EdgeDismissible(
            onDismiss: () => popped = true,
            child: const ColoredBox(color: Color(0xFF000000)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => popped;
  }

  /// A drag starting inside the leading 15% of one edge, travelling inwards.
  Future<void> swipeInFrom(WidgetTester tester, {required bool left}) async {
    final from = Offset(left ? 20 : size - 20, size / 2);
    await tester.dragFrom(from, Offset(left ? 200 : -200, 0));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a Hebrew app on an English watch still goes back from the left',
    (tester) async {
      final popped = await pump(
        tester,
        system: const Locale('en'),
        app: TextDirection.rtl,
      );

      await swipeInFrom(tester, left: true);
      expect(
        popped(),
        isTrue,
        reason: 'the app being RTL must not move a system gesture',
      );
    },
  );

  testWidgets('and the app language does not put one on the other edge', (
    tester,
  ) async {
    final popped = await pump(
      tester,
      system: const Locale('en'),
      app: TextDirection.rtl,
    );

    await swipeInFrom(tester, left: false);
    expect(popped(), isFalse);
  });

  testWidgets('an English app on a Hebrew watch goes back from the right', (
    tester,
  ) async {
    final popped = await pump(
      tester,
      system: const Locale('he'),
      app: TextDirection.ltr,
    );

    await swipeInFrom(tester, left: false);
    expect(popped(), isTrue);
  });

  testWidgets('a swipe that starts outside the strip is the content\'s', (
    tester,
  ) async {
    final popped = await pump(
      tester,
      system: const Locale('en'),
      app: TextDirection.ltr,
    );

    // Well inside the page: the strip is 15% of the width, and everything past
    // it belongs to whatever the route is drawing.
    await tester.dragFrom(
      const Offset(size / 2, size / 2),
      const Offset(200, 0),
    );
    await tester.pumpAndSettle();
    expect(popped(), isFalse);
  });
}
