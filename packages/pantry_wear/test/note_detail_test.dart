import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_wear/src/notes/note_detail_page.dart';
import 'package:pantry_wear/src/notes/note_route.dart';
import 'package:pantry_wear/src/notes/notes_controller.dart';
import 'package:pantry_wear/src/notes/notes_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_detail.dart';

import 'note_fixtures.dart';

/// What a note's body cannot say for itself, and the two ways to it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.casraf.pantry/wear_host');
  final handoffs = <String>[];

  setUp(() {
    WearShape.markFrom(['round']);
    handoffs.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'openOnPhone') {
            handoffs.add((call.arguments as Map)['url'] as String);
          }
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NotesController seeded() {
    final controller = NotesController.seeded(
      houseId: 4,
      notes: sampleNoteRecords(houseId: 4),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Widget host(NotesController controller) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: NotesPage(controller: controller, active: true, rotary: true),
    ),
  );

  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// How many lists are listening to the crown. The detent stream is broadcast
  /// and the pager keeps both of its pages mounted, so this is the number that
  /// must never exceed one.
  int rotaryListeners(WidgetTester tester) => tester
      .widgetList<SnapFocusList>(
        find.byType(SnapFocusList, skipOffstage: false),
      )
      .where((list) => list.rotaryActive)
      .length;

  /// The hand-off sits under the facts, which on a watch is past the fold.
  Future<void> reachHandoff(WidgetTester tester) async {
    final button = find.byType(OpenOnPhoneButton);
    await tester.scrollUntilVisible(
      button,
      60,
      scrollable: find.byType(Scrollable).last,
    );
    // Built is not the same as reachable: the list stops the moment the button
    // exists, which on a round screen is with it still off the bottom.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the page draws on both screen shapes', (tester) async {
    sizeToWatch(tester);
    for (final shape in ['round', 'square']) {
      WearShape.markFrom([shape]);
      await tester.pumpWidget(
        MaterialApp(
          home: NoteDetailPage(
            note: noteOf(sampleNotes.first, houseId: 4),
            progress: (done: 2, total: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hardware shop'), findsOneWidget);
      expect(find.text('someone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a hold on a card opens the note on its facts', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // The first card is the focused row on a wall that has just opened.
    await tester.longPress(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteRoute), findsOneWidget);
    expect(find.byType(NoteDetailPage), findsOneWidget);
    expect(find.text('someone'), findsOneWidget);
    // Six task lines, two of them ticked.
    expect(find.text('4 left'), findsOneWidget);
  });

  testWidgets('a tap opens the same route on the body instead', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteRoute), findsOneWidget);
    expect(find.text('Masking tape'), findsOneWidget);
    expect(find.byType(NoteDetailPage), findsNothing);
  });

  testWidgets('a mis-aimed hold costs a scroll, never a route', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // The second card is below the centre line on a wall that has just opened.
    await tester.longPress(find.text('Boiler service'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteRoute), findsNothing);

    await tester.longPress(find.text('Boiler service'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailPage), findsOneWidget);
  });

  testWidgets('the body is one swipe from the facts, and takes the crown back', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    // Neither focus list is steering: the wall underneath is covered and the
    // body is the page beside the one in front of the wearer. The facts scroll
    // on their own rotary hook, which is not one of these.
    expect(rotaryListeners(tester), 0);

    await tester.drag(find.byType(NoteDetailPage), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Masking tape'), findsOneWidget);
    // The wall and the body are both mounted; only the body listens.
    expect(find.byType(SnapFocusList, skipOffstage: false), findsNWidgets(2));
    expect(rotaryListeners(tester), 1);
  });

  testWidgets('and hands the phone the note, not the wall', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Hardware shop'));
    await tester.pumpAndSettle();
    await reachHandoff(tester);
    await tester.tap(find.byType(OpenOnPhoneButton));
    await tester.pumpAndSettle();

    expect(handoffs, ['pantry://note/4/1']);
  });

  testWidgets('a note nobody has edited says when it was written, once', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: NoteDetailPage(
          note: noteOf(sampleNotes.first, houseId: 4),
          progress: (done: 2, total: 6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The fixtures are written and last touched at the same moment, so the
    // updated row would say exactly what the added row above it already did.
    expect(find.text('ADDED'), findsOneWidget);
    expect(find.text('UPDATED'), findsNothing);
  });

  testWidgets('a synced note is marked, and its path stays off the wrist', (
    tester,
  ) async {
    sizeToWatch(tester);
    ServerVersionService.instance.debugSeed(
      features: {'note-file-sync': true},
      featuresAuthoritative: true,
    );
    addTearDown(ServerVersionService.instance.debugSeed);

    final note = noteOf(
      sampleNotes.first,
      houseId: 4,
      syncFileId: 256,
      syncPath: '/Templates/Hardware shop.md',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NoteDetailPage(note: note, progress: (done: 2, total: 6)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync_alt), findsOneWidget);
    expect(find.textContaining('Templates'), findsNothing);
  });
}
