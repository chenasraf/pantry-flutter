import 'package:flutter/material.dart';

import 'package:pantry_core/utils/markdown_list.dart';

/// PROTOTYPE — a watch-sized reader for the markdown a note body holds.
///
/// The phone renders note bodies with `flutter_markdown_plus`, which draws
/// tables, images, blockquotes, code fences and horizontal rules. None of
/// those survive contact with a 450px circle, and the package is an app
/// dependency rather than a core one — so this parser exists partly to read
/// notes and partly to find out how much of markdown a watch actually owes a
/// household note.
///
/// It covers headings, paragraphs, bullets, ordered items and task lines, and
/// draws anything else as its own literal text rather than dropping it — a
/// wearer seeing a stray `|` learns more than a wearer seeing a gap.
enum NoteBlockKind { heading, paragraph, bullet, task, literal }

@immutable
class NoteBlock {
  final NoteBlockKind kind;
  final String text;

  /// 1 or 2 for a heading; nesting depth for a list line.
  final int level;

  /// Position among the task lines of the document, counting only task lines,
  /// in document order — the ordinal `toggleChecklistItem` addresses. Null on
  /// every non-task block.
  final int? taskOrdinal;
  final bool checked;

  const NoteBlock({
    required this.kind,
    required this.text,
    this.level = 0,
    this.taskOrdinal,
    this.checked = false,
  });
}

final _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final _listRe = RegExp(r'^(\s*)(?:[-*+]|\d+[.)])\s+(.+)$');
final _taskRe = RegExp(r'^\[([ xX])\]\s*(.*)$');

/// Split a markdown body into the blocks a watch draws.
///
/// Consecutive prose lines join into one paragraph, the way markdown itself
/// treats them — a note written on a desktop is hard-wrapped, and drawing each
/// wrapped line as its own block would shred it.
List<NoteBlock> parseNoteBlocks(String body) {
  final out = <NoteBlock>[];
  final paragraph = <String>[];
  var taskCount = 0;

  void flush() {
    if (paragraph.isEmpty) return;
    out.add(
      NoteBlock(kind: NoteBlockKind.paragraph, text: paragraph.join(' ')),
    );
    paragraph.clear();
  }

  for (final raw in body.split(RegExp(r'\r?\n'))) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      flush();
      out.add(
        NoteBlock(
          kind: NoteBlockKind.heading,
          text: heading.group(2)!.trim(),
          level: heading.group(1)!.length.clamp(1, 2),
        ),
      );
      continue;
    }

    final list = _listRe.firstMatch(line);
    if (list != null) {
      flush();
      final indent = list.group(1)!.length;
      final rest = list.group(2)!;
      final task = _taskRe.firstMatch(rest);
      if (task != null) {
        out.add(
          NoteBlock(
            kind: NoteBlockKind.task,
            text: task.group(2)!.trim(),
            level: indent ~/ 2,
            taskOrdinal: taskCount++,
            checked: task.group(1)!.toLowerCase() == 'x',
          ),
        );
      } else {
        out.add(
          NoteBlock(
            kind: NoteBlockKind.bullet,
            text: rest.trim(),
            level: indent ~/ 2,
          ),
        );
      }
      continue;
    }

    paragraph.add(line.trim());
  }
  flush();
  return out;
}

/// Set the task line at [ordinal] to [checked], returning [content] untouched
/// when it is already in that state.
///
/// The shape core needs, and the reason a queued tick carries a state rather
/// than a flip: an op saying "flip line 3" applied after a housemate ticked
/// line 3 unticks it, where one saying "line 3 is checked" is idempotent and
/// converges. Core has only the flip today; that is card 741.
String setChecklistItem(String content, int ordinal, bool checked) {
  final current = parseNoteBlocks(
    content,
  ).where((b) => b.kind == NoteBlockKind.task).toList();
  if (ordinal >= current.length) return content;
  if (current[ordinal].checked == checked) return content;
  return toggleChecklistItem(content, ordinal);
}

/// How many task lines a body holds, and how many are ticked. Drives the wall
/// card's progress, which is the whole point of the page once ticking is the
/// only write.
({int done, int total}) taskProgress(String body) {
  var done = 0;
  var total = 0;
  for (final b in parseNoteBlocks(body)) {
    if (b.kind != NoteBlockKind.task) continue;
    total++;
    if (b.checked) done++;
  }
  return (done: done, total: total);
}

final _inlineRe = RegExp(
  r'(\*\*|__)(.+?)\1'
  r'|(\*|_)(.+?)\3'
  r'|`([^`]+)`'
  r'|\[([^\]]+)\]\(([^)]+)\)',
);

/// Inline markdown, as far as a watch cares: bold, emphasis, code and the
/// *text* of a link. A link's target is dropped rather than shown — the watch
/// cannot open it, and a bare URL costs more width than the whole line it sits
/// on.
List<TextSpan> inlineSpans(String text, TextStyle base) {
  final spans = <TextSpan>[];
  var index = 0;
  for (final m in _inlineRe.allMatches(text)) {
    if (m.start > index) {
      spans.add(TextSpan(text: text.substring(index, m.start), style: base));
    }
    if (m.group(2) != null) {
      spans.add(
        TextSpan(
          text: m.group(2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    } else if (m.group(4) != null) {
      spans.add(
        TextSpan(
          text: m.group(4),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (m.group(5) != null) {
      spans.add(
        TextSpan(
          text: m.group(5),
          style: base.copyWith(
            fontFamily: 'monospace',
            color: base.color?.withValues(alpha: 0.85),
          ),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: m.group(6),
          style: base.copyWith(decoration: TextDecoration.underline),
        ),
      );
    }
    index = m.end;
  }
  if (index < text.length) {
    spans.add(TextSpan(text: text.substring(index), style: base));
  }
  return spans;
}

/// Strip inline markers without styling anything — for a wall card's preview,
/// where `**` costs two characters of a line that has about thirty.
String flattenInline(String text) =>
    text.replaceAllMapped(_inlineRe, (m) => m[2] ?? m[4] ?? m[5] ?? m[6] ?? '');
