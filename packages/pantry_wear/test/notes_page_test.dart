import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_wear/src/notes/note_blocks.dart';
import 'package:pantry_wear/src/notes/note_markdown.dart';
import 'package:pantry_wear/src/notes/note_route.dart';
import 'package:pantry_wear/src/notes/notes_controller.dart';
import 'package:pantry_wear/src/notes/notes_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/undo_window.dart';

import 'note_fixtures.dart';

/// The checks the notes page earned.
///
/// Everything here analysed clean before it was pumped, which is the whole
/// reason the page has tests at all: a watch layout fails by drawing the wrong
/// thing quietly, not by throwing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final notes = sampleNoteRecords();

  NotesController seeded() {
    final controller = NotesController.seeded(houseId: 1, notes: notes);
    addTearDown(controller.dispose);
    return controller;
  }

  Widget host(NotesController controller) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: NotesPage(controller: controller, active: true, rotary: true),
    ),
  );

  /// A watch-sized window, so a pushed route gets watch geometry too rather
  /// than the 800×600 a test window defaults to.
  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// How many lists are listening to the crown. The detent stream is broadcast
  /// and a covered list stays mounted, so this is the number that must never
  /// exceed one.
  ///
  /// Offstage is not skipped: a route pushed over the wall takes the wall
  /// offstage but leaves it mounted and subscribed, which is the entire thing
  /// being counted. A count without `skipOffstage: false` finds only the
  /// visible list and passes while proving nothing.
  int rotaryListeners(WidgetTester tester) => tester
      .widgetList<SnapFocusList>(
        find.byType(SnapFocusList, skipOffstage: false),
      )
      .where((list) => list.rotaryActive)
      .length;

  /// The queue is the write sink. Offline so nothing tries to reach a server:
  /// what is asserted is the op's effect, not its delivery.
  ///
  /// The reset is deliberately not awaited. A cache store's drain, once started
  /// inside `testWidgets`, is never driven to completion by the fake-async
  /// zone, so awaiting `clear()` hangs the whole file. `SyncQueue.clear` empties
  /// its ops synchronously before it touches disk, which is the whole of what
  /// the next test needs.
  void queueOffline() {
    SyncManager.instance.setOnline(false);
    addTearDown(() => unawaited(SyncManager.instance.reset()));
  }

  tearDown(() => WearShape.markFrom(['round']));

  testWidgets('the wall draws on both screen shapes', (tester) async {
    sizeToWatch(tester);
    for (final shape in ['round', 'square']) {
      WearShape.markFrom([shape]);
      await tester.pumpWidget(host(seeded()));
      await tester.pumpAndSettle();

      expect(find.text('Hardware shop'), findsOneWidget);
      expect(find.text('Boiler service'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a card carrying tasks says what is left, not what it says', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // "Hardware shop" holds six task lines, two of them ticked.
    expect(find.text('4 left'), findsOneWidget);
  });

  testWidgets('a card with no tasks previews its prose, and an empty one an '
      'em dash', (tester) async {
    sizeToWatch(tester);
    final controller = NotesController.seeded(
      houseId: 1,
      // "Spare key with Dana" has no body at all; "House rules for sitters" is
      // prose and headings with nothing to tick.
      notes: [noteOf(sampleNotes[4]), noteOf(sampleNotes[3])],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('·'), findsOneWidget);
  });

  testWidgets('an off-centre card scrolls; only the centred one opens', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // The second card is below the centre line on a wall that has just opened.
    await tester.tap(find.text('Boiler service'));
    await tester.pumpAndSettle();
    expect(
      find.byType(NoteRoute),
      findsNothing,
      reason: 'a mis-aim must cost a scroll, never a route',
    );

    // It is now the focused row, so the second tap acts.
    await tester.tap(find.text('Boiler service'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteRoute), findsOneWidget);
  });

  testWidgets('a note takes the crown with it', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    expect(rotaryListeners(tester), 1);

    // The first card is the focused row on a wall that has just opened.
    await tester.tap(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteRoute), findsOneWidget);
    // The wall underneath stays mounted — that is the whole hazard, and the
    // reason the count below means something: two lists exist, one listens. If
    // the covered one kept its subscription, a single turn of the bezel would
    // scroll both it and the note sitting over it.
    expect(find.byType(SnapFocusList, skipOffstage: false), findsNWidgets(2));
    expect(rotaryListeners(tester), 1);
  });

  testWidgets('prose is unlandable and task rows claim the snap extent', (
    tester,
  ) async {
    sizeToWatch(tester);
    final controller = seeded();
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    // "Boiler service" is the note whose tasks are interleaved with prose.
    await tester.tap(find.text('Boiler service'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boiler service'));
    await tester.pumpAndSettle();

    final list = tester.widget<SnapFocusList>(
      find.descendant(
        of: find.byType(NoteRoute),
        matching: find.byType(SnapFocusList),
      ),
    );
    final blocks = parseNoteBlocks(
      controller.bodyOf(notes[1])!,
    ).where((b) => b.kind != NoteBlockKind.task).length;

    expect(list.elements.where((e) => e.snappable), isNotEmpty);
    expect(list.elements.where((e) => !e.snappable).length, blocks);
    for (final element in list.elements.where((e) => e.snappable)) {
      expect(
        element.extent,
        greaterThanOrEqualTo(kTaskRowExtent),
        reason:
            'a task row that gives up slack leaves a gap, not a tighter '
            'list',
      );
    }
  });

  testWidgets('a tick queues the change, not the document', (tester) async {
    sizeToWatch(tester);
    queueOffline();
    final controller = seeded();
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    // The first task line of the note, already on the centre line.
    // "Picture hooks" starts ticked, so the tap unticks it.
    expect(taskLines(controller.bodyOf(notes.first)!)[0].checked, isTrue);

    await tester.tap(find.text('Picture hooks'));
    // Nothing is written while the undo window is still draining.
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.bodyOf(notes.first), notes.first.content);

    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    // The queue is the optimistic update: a read has to see it, and the body
    // it produces differs from the snapshot by exactly the one line.
    final after = controller.bodyOf(notes.first)!;
    expect(taskLines(after)[0].checked, isFalse);
    expect(after.length, notes.first.content!.length);
  });

  testWidgets('a second tap inside the window takes the tick back', (
    tester,
  ) async {
    sizeToWatch(tester);
    queueOffline();
    final controller = seeded();
    await tester.pumpWidget(host(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hardware shop'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Picture hooks'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Picture hooks'));
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(controller.bodyOf(notes.first), notes.first.content);
  });

  group('the queue wins over any snapshot', () {
    test('a pending tick is laid back over a body that predates it', () {
      queueOffline();
      const before = '- [ ] Wood glue\n- [ ] Sandpaper\n';

      SyncManager.instance.enqueue(
        SyncOp(
          uuid: 'op-1',
          entity: SyncEntity.note,
          op: SyncOpKind.toggle,
          houseId: 1,
          entityId: 9,
          body: {'ordinal': 1, 'text': 'Sandpaper', 'checked': true},
          createdAt: 0,
        ),
      );

      expect(
        SyncManager.instance.pendingNoteContent(1, 9, before),
        '- [ ] Wood glue\n- [x] Sandpaper\n',
      );
      // Another note's body is untouched, and so is another house's.
      expect(SyncManager.instance.pendingNoteContent(1, 8, before), before);
      expect(SyncManager.instance.pendingNoteContent(2, 9, before), before);
    });

    test('an op follows its line when one is inserted above it', () {
      queueOffline();

      SyncManager.instance.enqueue(
        SyncOp(
          uuid: 'op-1',
          entity: SyncEntity.note,
          op: SyncOpKind.toggle,
          houseId: 1,
          entityId: 9,
          body: {'ordinal': 0, 'text': 'Wood glue', 'checked': true},
          createdAt: 0,
        ),
      );

      // A housemate added a line above it while the write sat in the queue.
      expect(
        SyncManager.instance.pendingNoteContent(
          1,
          9,
          '- [ ] Masking tape\n- [ ] Wood glue\n',
        ),
        '- [ ] Masking tape\n- [x] Wood glue\n',
      );
    });
  });

  group('the wall as the controller orders it', () {
    test('pinned notes lead', () {
      final controller = NotesController.seeded(
        houseId: 1,
        notes: [
          noteOf(sampleNotes[1]),
          noteOf(sampleNotes[0]), // the pinned one
          noteOf(sampleNotes[2]),
        ],
      );
      addTearDown(controller.dispose);
      expect(controller.notes.first.title, 'Hardware shop');
    });

    test('progress reads through the queue, not the snapshot', () {
      queueOffline();
      final note = noteOf(sampleNotes.first);
      final controller = NotesController.seeded(houseId: 1, notes: [note]);
      addTearDown(controller.dispose);

      expect(controller.progressOf(note), (done: 2, total: 6));
      controller.setTaskLine(
        note,
        ordinal: 1,
        text: 'Masking tape',
        checked: true,
      );
      expect(controller.progressOf(note), (done: 3, total: 6));
    });

    test('a tick that would change nothing queues nothing', () {
      queueOffline();
      final note = Note(
        id: 9,
        houseId: 1,
        title: 'Shed',
        content: '- [x] Padlock\n',
        createdBy: 'someone',
        sortOrder: 0,
        createdAt: 0,
        updatedAt: 0,
      );
      final controller = NotesController.seeded(houseId: 1, notes: [note]);
      addTearDown(controller.dispose);

      final before = SyncManager.instance.pendingCount.value;
      controller.setTaskLine(note, ordinal: 0, text: 'Padlock', checked: true);
      expect(SyncManager.instance.pendingCount.value, before);
      expect(controller.bodyOf(note), note.content);
    });
  });
}
