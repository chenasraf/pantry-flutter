import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_wear/src/notes/note_blocks.dart';
import 'package:pantry_wear/src/notes/note_markdown.dart';

import 'note_fixtures.dart';

/// The reader the notes page is built on.
///
/// The first group is the load-bearing one: the watch decides *which* checkbox
/// you tapped by counting task lines as it renders them, and core decides which
/// one to rewrite by counting task lines as it rewrites them. If those two
/// counts ever disagree, a tap silently ticks a different line — a wrong write,
/// with nothing on screen to say so. [parseNoteBlocks] asks core rather than
/// counting for itself, and these hold it to that.
void main() {
  group('task ordinals agree with core', () {
    test('every rendered task maps to the line core rewrites', () {
      for (final note in sampleNotes) {
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

    test('a block\'s text is the text core would carry on the write', () {
      // The queued op names its line by text as well as ordinal, so the two
      // have to be the same string — a trimmed or de-marked one would fail to
      // re-anchor and drop the write.
      for (final note in sampleNotes) {
        final drawn = parseNoteBlocks(note.body)
            .where((b) => b.kind == NoteBlockKind.task)
            .map((b) => b.text)
            .toList();
        expect(drawn, taskLines(note.body).map((l) => l.text).toList());
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

    test('an ordered marker and an upper-case tick are both task lines', () {
      // Whatever core reads as a task line the page must draw as one: a block
      // parser that missed either would draw it as a bullet and shift every
      // later ordinal by one.
      final blocks = parseNoteBlocks('1. [X] Meter reading\n2. [ ] Photo');
      expect(blocks.map((b) => b.kind), everyElement(NoteBlockKind.task));
      expect(blocks.first.checked, isTrue);
      expect(blocks.map((b) => b.taskOrdinal), [0, 1]);
    });

    test('progress counts only task lines', () {
      expect(taskProgress(sampleNotes.first.body), (done: 2, total: 6));
      expect(taskProgress('just prose'), (done: 0, total: 0));
      expect(taskProgress(null), (done: 0, total: 0));
    });

    test('inline markers are stripped, link text is kept', () {
      expect(flattenInline('**bold** and `code`'), 'bold and code');
      expect(flattenInline('[report here](https://x.test)'), 'report here');
    });
  });

  group('measuring', () {
    final metrics = NoteBlockMetrics();

    test('a task row claims the snap extent even on one short line', () {
      // The rows around a task are deliberately variable, which is what makes
      // this exception easy to talk yourself into. Slack a row gives up becomes
      // a gap, not a tighter list.
      const short = NoteBlock(
        kind: NoteBlockKind.task,
        text: 'Tea',
        taskOrdinal: 0,
      );
      expect(metrics.extentOf(short, 200), kTaskRowExtent);
    });

    test('a paragraph grows with its text and shrinks with its width', () {
      const long = NoteBlock(
        kind: NoteBlockKind.paragraph,
        text: 'The engineer needs the boiler pressure written down.',
      );
      const brief = NoteBlock(kind: NoteBlockKind.paragraph, text: 'Short.');
      expect(
        metrics.extentOf(long, 200),
        greaterThan(metrics.extentOf(brief, 200)),
      );
      expect(
        metrics.extentOf(long, 140),
        greaterThan(metrics.extentOf(long, 400)),
      );
    });

    test('the same block at the same width answers the same', () {
      const block = NoteBlock(kind: NoteBlockKind.paragraph, text: 'Bin day');
      expect(metrics.extentOf(block, 180), metrics.extentOf(block, 180));
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
  });
}
