import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/watch/watch_pairing_view.dart';

/// How many pairing pages one request for a pairing page is worth.
///
/// The watch asks for it over `pantry://watch-setup`, and settings offers the
/// same page from a row — two directions with no sight of each other, and a
/// wearer who taps twice is an ordinary thing rather than a mistake. Every ask
/// means the same thing, so answering each one with a route of its own leaves
/// the user pressing back through pages they already finished with to reach the
/// one they started on.
///
/// The asks are made against the page *underneath*, which is where both of them
/// come from: the deep link is answered by the home view while whatever it
/// raised is still covering it.
void main() {
  final navigator = GlobalKey<NavigatorState>();
  late BuildContext home;

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: Builder(
        builder: (context) {
          home = context;
          return const Scaffold();
        },
      ),
    ),
  );

  testWidgets('asking twice puts one pairing page on screen', (tester) async {
    await pump(tester);

    WatchPairingView.open(home);
    await tester.pumpAndSettle();
    WatchPairingView.open(home);
    await tester.pumpAndSettle();

    expect(find.byType(WatchPairingView), findsOneWidget);

    // And one back gesture is the whole way out, rather than the first of
    // however many asks happened to land.
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(WatchPairingView), findsNothing);
  });

  testWidgets('and closing it lets the next ask through', (tester) async {
    await pump(tester);

    WatchPairingView.open(home);
    await tester.pumpAndSettle();
    expect(WatchPairingView.isOpen, isTrue);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(WatchPairingView.isOpen, isFalse);

    WatchPairingView.open(home);
    await tester.pumpAndSettle();
    expect(find.byType(WatchPairingView), findsOneWidget);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
  });
}
