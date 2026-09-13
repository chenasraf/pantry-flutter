import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/app_toast.dart';

/// Hosts an app wrapped in the toast host, which is what gives the helpers an
/// overlay to insert into.
Widget _host() {
  return MaterialApp(
    home: AppToastHost(
      textDirection: TextDirection.ltr,
      child: const Scaffold(body: SizedBox.expand()),
    ),
  );
}

/// Pumps past the enter animation so the card is on screen.
///
/// Never `pumpAndSettle` around a live toast: the border animates for the
/// whole of its life, so settling runs the clock out and dismisses it.
Future<void> _pumpIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(dismissAppToasts);

  group('showAppToast', () {
    testWidgets('displays the message', (tester) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'Saved', duration: const Duration(seconds: 4));
      await _pumpIn(tester);

      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('auto-dismisses after its duration', (tester) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'Saved', duration: const Duration(seconds: 4));
      await _pumpIn(tester);
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('is a no-op when no toast host is mounted', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(showAppToast(message: 'Nope'), isNull);
      await _pumpIn(tester);

      expect(find.text('Nope'), findsNothing);
    });

    testWidgets('replaces the previous toast', (tester) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'First', duration: const Duration(seconds: 4));
      await _pumpIn(tester);
      expect(find.text('First'), findsOneWidget);

      showAppToast(message: 'Second', duration: const Duration(seconds: 4));
      await _pumpIn(tester);

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('the close button dismisses it early', (tester) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'Saved', duration: const Duration(seconds: 30));
      await _pumpIn(tester);
      expect(find.text('Saved'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('an actionless toast still carries a close button', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'Saved', duration: const Duration(seconds: 4));
      await _pumpIn(tester);

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('showUndoToast', () {
    testWidgets('shows the message and undo label', (tester) async {
      await tester.pumpWidget(_host());

      showUndoToast(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async {},
        duration: const Duration(seconds: 6),
      );
      await _pumpIn(tester);

      expect(find.text('Item removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping undo runs onUndo and dismisses', (tester) async {
      await tester.pumpWidget(_host());

      var undone = false;
      showUndoToast(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async => undone = true,
        duration: const Duration(seconds: 6),
      );
      await _pumpIn(tester);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undone, isTrue);
      expect(find.text('Item removed'), findsNothing);
    });

    testWidgets('surfaces undoFailedMessage when onUndo throws', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      showUndoToast(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async => throw Exception('boom'),
        undoFailedMessage: 'Could not undo',
        duration: const Duration(seconds: 6),
      );
      await _pumpIn(tester);

      await tester.tap(find.text('Undo'));
      await _pumpIn(tester);

      expect(find.text('Could not undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('auto-dismisses even though it carries an action', (
      tester,
    ) async {
      // The bottom-anchored snackbar this replaced would sit open forever
      // under accessible navigation once it had an action attached.
      await tester.pumpWidget(_host());

      showUndoToast(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async {},
        duration: const Duration(seconds: 6),
      );
      await _pumpIn(tester);
      expect(find.text('Item removed'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Item removed'), findsNothing);
    });
  });

  group('placement', () {
    testWidgets('floats from the top, clear of the bottom of the screen', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      showAppToast(message: 'Saved', duration: const Duration(seconds: 30));
      await _pumpIn(tester);

      final card = tester.getRect(find.text('Saved'));
      final screen = tester.getRect(find.byType(MaterialApp));
      expect(card.top, lessThan(screen.height / 4));

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });
}
