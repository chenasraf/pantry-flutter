import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/main.dart' show rootScaffoldMessengerKey;
import 'package:pantry/utils/undo_snackbar.dart';

/// Hosts the widgets under test with a [ScaffoldMessenger] wired to
/// [rootScaffoldMessengerKey] (the key both helpers post to). When
/// [accessibleNavigation] is true an action SnackBar would default to never
/// auto-dismissing — the exact scenario that left toasts stuck open
/// (issue #100) — so it doubles as the regression harness for the helper's
/// `persist: false` opt-out.
Widget _host({bool accessibleNavigation = false}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(accessibleNavigation: accessibleNavigation),
        child: ScaffoldMessenger(
          key: rootScaffoldMessengerKey,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    ),
  );
}

void main() {
  group('showAppSnackBar', () {
    testWidgets('displays the message', (tester) async {
      await tester.pumpWidget(_host());

      showAppSnackBar(message: 'Saved', duration: const Duration(seconds: 4));
      await tester.pump(); // process show + schedule the dismissal timer
      await tester.pump(const Duration(milliseconds: 300)); // enter animation

      expect(find.text('Saved'), findsOneWidget);

      // Drain the timer so the test doesn't end with one pending.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('auto-dismisses after its duration', (tester) async {
      await tester.pumpWidget(_host());

      showAppSnackBar(message: 'Saved', duration: const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('is a no-op when the root messenger is not mounted', (
      tester,
    ) async {
      // No ScaffoldMessenger carrying the root key in the tree.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      showAppSnackBar(message: 'Nope');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nope'), findsNothing);
      // No timer was scheduled, so the test ends clean.
    });

    testWidgets('replaces the previous snackbar', (tester) async {
      await tester.pumpWidget(_host());

      showAppSnackBar(message: 'First', duration: const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('First'), findsOneWidget);

      showAppSnackBar(message: 'Second', duration: const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });
  });

  group('showUndoSnackBar', () {
    testWidgets('shows the message and undo label', (tester) async {
      await tester.pumpWidget(_host());

      showUndoSnackBar(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async {},
        duration: const Duration(seconds: 6),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Item removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('tapping undo runs onUndo and dismisses', (tester) async {
      await tester.pumpWidget(_host());

      var undone = false;
      showUndoSnackBar(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async => undone = true,
        duration: const Duration(seconds: 6),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undone, isTrue);
      expect(find.text('Item removed'), findsNothing);
    });

    testWidgets('surfaces undoFailedMessage when onUndo throws', (
      tester,
    ) async {
      await tester.pumpWidget(_host());

      showUndoSnackBar(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async => throw Exception('boom'),
        undoFailedMessage: 'Could not undo',
        duration: const Duration(seconds: 6),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Could not undo'), findsOneWidget);

      // The failure toast schedules its own timer; drain it.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('regression: issue #100 (toasts stuck open)', () {
    testWidgets('action snackbar still auto-dismisses under accessible '
        'navigation', (tester) async {
      // With accessible navigation on, an action snackbar defaults to NOT
      // auto-dismissing — it waits for the user. That is what pinned the
      // delete/archive toasts open. The helper's `persist: false` must opt
      // back into auto-dismissal regardless.
      await tester.pumpWidget(_host(accessibleNavigation: true));

      showUndoSnackBar(
        message: 'Item removed',
        undoLabel: 'Undo',
        onUndo: () async {},
        duration: const Duration(seconds: 6),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Item removed'), findsOneWidget);

      // Well past the duration — an action snackbar without `persist: false`
      // would still be here (see Flutter's own "accessible navigation behavior
      // with action" test). Ours is gone.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Item removed'), findsNothing);
    });

    testWidgets('plain message snackbar auto-dismisses under accessible '
        'navigation', (tester) async {
      await tester.pumpWidget(_host(accessibleNavigation: true));

      showAppSnackBar(message: 'Saved', duration: const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });
  });
}
