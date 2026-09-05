import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_wear/src/prototype/note_markdown.dart';
import 'package:pantry_wear/src/prototype/notes_prototype.dart';
import 'package:pantry_wear/src/prototype/proto_note_data.dart';
import 'package:pantry_wear/src/prototype/variant_note_document.dart';

/// PROTOTYPE — the checks worth having while the notes page is being judged.
///
/// The first is the load-bearing one: the watch decides *which* checkbox you
/// tapped by counting task lines as it renders them, and core decides which
/// one to flip by counting task lines as it rewrites them. If those two counts
/// ever disagree, a tap silently ticks a different line — a wrong write, with
/// nothing on screen to say so.
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

    test('a toggle changes exactly one character', () {
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

  group('the page', () {
    testWidgets('the wall says what is left rather than previewing prose', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: NotesPrototype()));
      await tester.pumpAndSettle();

      // "Hardware shop" has 6 tasks, 2 ticked.
      expect(find.text('4 left'), findsOneWidget);
    });

    testWidgets('a tap on a task reports the ordinal it drew', (tester) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final fired = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantNoteDocument(
              body: protoNotes.first.body,
              onToggle: fired.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wood glue'));
      expect(fired, [4]);
    });

    testWidgets('a read-only document does not fire', (tester) async {
      tester.view.physicalSize = const Size(480, 480);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VariantNoteDocument(body: protoNotes.first.body),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing to assert but the absence of a crash and of a handler: the
      // point is that variant C's reading surface cannot write.
      await tester.tap(find.text('Wood glue'));
      await tester.pump();
    });
  });
}
