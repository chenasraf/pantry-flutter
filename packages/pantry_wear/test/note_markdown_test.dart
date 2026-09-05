import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_wear/src/prototype/checklist_prototype.dart';
import 'package:pantry_wear/src/prototype/note_blocks.dart';
import 'package:pantry_wear/src/prototype/note_markdown.dart';
import 'package:pantry_wear/src/prototype/notes_page.dart';
import 'package:pantry_wear/src/prototype/proto_note_data.dart';
import 'package:pantry_wear/src/prototype/proto_tuning.dart';

/// The checks the notes page earned.
///
/// The first is the load-bearing one: the watch decides *which* checkbox you
/// tapped by counting task lines as it renders them, and core decides which
/// one to rewrite by counting task lines as it rewrites them. If those two
/// counts ever disagree, a tap silently ticks a different line — a wrong
/// write, with nothing on screen to say so.
void main() {
  group('task ordinals agree with core', () {
    test('every rendered task maps to the line core rewrites', () {
      for (final note in protoNotes) {
        final blocks = parseNoteBlocks(
          note.body,
        ).where((b) => b.kind == NoteBlockKind.task).toList();

        for (final block in blocks) {
          final ordinal = block.taskOrdinal!;
          final flipped = toggleChecklistItem(note.body, ordinal);
          final after = parseNoteBlocks(
            flipped,
          ).where((b) => b.kind == NoteBlockKind.task).toList();

          expect(
            after[ordinal].checked,
            !block.checked,
            reason:
                'note "${note.title}" ordinal $ordinal did not flip the line '
                'the watch drew at that position',
          );
          // Nothing else may move.
          for (var i = 0; i < blocks.length; i++) {
            if (i == ordinal) continue;
            expect(after[i].checked, blocks[i].checked);
            expect(after[i].text, blocks[i].text);
          }
        }
      }
    });

    test('a rewrite changes exactly one character', () {
      const body = '- [ ] Wood glue\n- [x] Sandpaper\n';
      final flipped = toggleChecklistItem(body, 0);
      expect(flipped.length, body.length);
      var diffs = 0;
      for (var i = 0; i < body.length; i++) {
        if (body[i] != flipped[i]) diffs++;
      }
      expect(diffs, 1);
    });
  });

  group('a tick sets a state rather than flipping one', () {
    const body = '- [ ] Wood glue\n- [x] Sandpaper\n';

    test('setting a line to what it already is changes nothing', () {
      // The whole point: a tick landing on a line a housemate already ticked
      // must converge, not undo them.
      expect(setChecklistItem(body, 1, true), same(body));
      expect(setChecklistItem(body, 0, false), same(body));
    });

    test('applying the same set twice is the same as applying it once', () {
      final once = setChecklistItem(body, 0, true);
      final twice = setChecklistItem(once, 0, true);
      expect(once, isNot(body));
      expect(twice, once);
    });

    test('an ordinal past the end is a no-op', () {
      expect(setChecklistItem(body, 9, true), same(body));
    });
  });

  group('parsing', () {
    test('hard-wrapped prose joins into one paragraph', () {
      final blocks = parseNoteBlocks('one line\nwrapped here\n\nsecond');
      expect(blocks.length, 2);
      expect(blocks.first.text, 'one line wrapped here');
    });

    test('a task inside prose still counts from the document start', () {
      final blocks = parseNoteBlocks(
        'intro\n\n- [ ] a\n\nmore prose\n\n- [x] b',
      );
      final tasks = blocks.where((b) => b.kind == NoteBlockKind.task).toList();
      expect(tasks.map((t) => t.taskOrdinal), [0, 1]);
    });

    test('a plain bullet is not a task', () {
      final blocks = parseNoteBlocks('- Green bin\n- [ ] Recycling');
      expect(blocks.first.kind, NoteBlockKind.bullet);
      expect(blocks.first.taskOrdinal, isNull);
      expect(blocks.last.kind, NoteBlockKind.task);
      expect(blocks.last.taskOrdinal, 0);
    });

    test('progress counts only task lines', () {
      expect(taskProgress(protoNotes.first.body), (done: 2, total: 6));
      expect(taskProgress('just prose'), (done: 0, total: 0));
    });

    test('inline markers are stripped, link text is kept', () {
      expect(flattenInline('**bold** and `code`'), 'bold and code');
      expect(flattenInline('[report here](https://x.test)'), 'report here');
    });
  });

  group('a note is drawn on its own colour', () {
    test('ink flips with the colour it has to sit on', () {
      // The two ends of the palette the phone offers.
      expect(
        noteInk(const Color(0xFFFFEB3B)),
        Colors.black87,
        reason: 'yellow',
      );
      expect(noteInk(const Color(0xFF9C27B0)), Colors.white, reason: 'purple');
      // An uncoloured note falls back to the card plane, which is near-black.
      expect(noteInk(kNotePlane), Colors.white);
    });

    testWidgets('a light note draws dark text, a dark note light', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesPage(
              tuning: ProtoTuning(),
              active: true,
              bodies: {for (final n in protoNotes) n.id: n.body},
              onSetTask: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Color titleColour(String title) =>
          tester.widget<Text>(find.text(title)).style!.color!;

      // "Boiler service" is amber; "Hardware shop" is blue.
      expect(titleColour('Boiler service'), Colors.black87);
      expect(titleColour('Hardware shop'), Colors.white);
    });
  });

  group('the page in the pager', () {
    /// One page, deliberately slowly. A `tester.drag` of a screen's width is a
    /// fling, and a fling carries the pager past more than one page — which is
    /// itself worth knowing, since the wearer's swipe is the slow kind.
    Future<void> swipeToNextPage(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(-24, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('notes is the third browse page, after checklists and photos', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ChecklistPrototype()));
      await tester.pumpAndSettle();

      await swipeToNextPage(tester);
      expect(find.text('Fridge shelf'), findsOneWidget, reason: 'photos');

      await swipeToNextPage(tester);
      // "Hardware shop" holds 6 tasks, 2 of them ticked.
      expect(find.text('4 left'), findsOneWidget);
      // A note without tasks previews its prose instead of a count.
      expect(find.textContaining('Green bin'), findsOneWidget);
    });
  });

  group('the notes page', () {
    Future<List<(int, int, bool)>> pumpNotes(WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final writes = <(int, int, bool)>[];
      final bodies = {for (final n in protoNotes) n.id: n.body};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotesPage(
              tuning: ProtoTuning(),
              active: true,
              bodies: bodies,
              onSetTask: (id, ordinal, checked) =>
                  writes.add((id, ordinal, checked)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return writes;
    }

    testWidgets('an off-centre tap scrolls the note here, the next opens it', (
      tester,
    ) async {
      await pumpNotes(tester);

      // The second note is off the centre line, so the first tap only brings
      // it here — a mis-aim costs a scroll, never a route.
      await tester.tap(find.text('Boiler service'));
      await tester.pumpAndSettle();
      expect(find.text('Clear the cupboard under the stairs'), findsNothing);

      // It is now the focused row, so the identical tap acts.
      await tester.tap(find.text('Boiler service'));
      await tester.pumpAndSettle();
      expect(find.text('Clear the cupboard under the stairs'), findsOneWidget);
    });

    testWidgets('an off-centre task scrolls rather than writing', (
      tester,
    ) async {
      final writes = await pumpNotes(tester);

      await tester.tap(find.text('Hardware shop'));
      await tester.pumpAndSettle();

      // Third task down, well off the centre line.
      await tester.tap(find.text('6mm wall plugs'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(writes, isEmpty);

      // Centred now, so it commits.
      await tester.tap(find.text('6mm wall plugs'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(writes, [(1, 2, true)]);
    });

    testWidgets('a tick reports an absolute state, after its undo window', (
      tester,
    ) async {
      final writes = await pumpNotes(tester);

      await tester.tap(find.text('Hardware shop'));
      await tester.pumpAndSettle();

      // "Picture hooks" is ticked in the source, so setting it must ask for
      // false — the op carries where the line is going, not that it moved.
      await tester.tap(find.text('Picture hooks'));
      await tester.pump();
      expect(writes, isEmpty, reason: 'the undo window has not drained yet');

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(writes, [(1, 0, false)]);
    });
  });
}
