import 'package:flutter/material.dart';

import 'package:pantry_core/utils/markdown_list.dart';

/// A watch-sized reader for the markdown a note body holds.
///
/// The phone renders note bodies with `flutter_markdown_plus`, which draws
/// tables, images, blockquotes, code fences and horizontal rules. None of
/// those survive contact with a 450px circle, and the package is an app
/// dependency rather than a core one — so the watch carries this instead: it
/// covers headings, paragraphs, bullets, ordered items and task lines, and
/// draws anything else as its own literal text rather than dropping it. A
/// wearer seeing a stray `|` learns more than a wearer seeing a gap.
enum NoteBlockKind { heading, paragraph, bullet, task, literal }

@immutable
class NoteBlock {
  final NoteBlockKind kind;
  final String text;

  /// 1 or 2 for a heading; nesting depth for a list line.
  final int level;

  /// Position among the task lines of the document, counting only task lines,
  /// in document order — the ordinal [setChecklistItem] addresses. Null on
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

/// Split a markdown body into the blocks a watch draws.
///
/// Consecutive prose lines join into one paragraph, the way markdown itself
/// treats them — a note written on a desktop is hard-wrapped, and drawing each
/// wrapped line as its own block would shred it.
///
/// What counts as a task line is core's answer, never a second regex here:
/// [taskLines] holds no state across lines, so asking it about one line gives
/// the same verdict it will give about that line when the queued write drains.
/// The ordinal the page draws is then the ordinal core rewrites by
/// construction. Two counters that merely agree today would disagree silently,
/// and a disagreement is a write landing on the wrong line with nothing on
/// screen to show it.
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

    final task = taskLines(line);
    if (task.length == 1) {
      flush();
      out.add(
        NoteBlock(
          kind: NoteBlockKind.task,
          text: task.single.text,
          level: (line.length - line.trimLeft().length) ~/ 2,
          taskOrdinal: taskCount++,
          checked: task.single.checked,
        ),
      );
      continue;
    }

    final list = _listRe.firstMatch(line);
    if (list != null) {
      flush();
      out.add(
        NoteBlock(
          kind: NoteBlockKind.bullet,
          text: list.group(2)!.trim(),
          level: list.group(1)!.length ~/ 2,
        ),
      );
      continue;
    }

    paragraph.add(line.trim());
  }
  flush();
  return out;
}

/// How many task lines a body holds, and how many are ticked. Drives the wall
/// card's progress, which is the whole point of the page once ticking is the
/// only write.
({int done, int total}) taskProgress(String? body) {
  if (body == null) return (done: 0, total: 0);
  final lines = taskLines(body);
  var done = 0;
  for (final line in lines) {
    if (line.checked) done++;
  }
  return (done: done, total: lines.length);
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
