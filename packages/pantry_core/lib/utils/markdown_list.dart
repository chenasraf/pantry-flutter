import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';

/// Separator between the item name and its quantity/description on a line.
/// Spaced em dash (U+2014), matching the export format. Import strips
/// everything from the first occurrence so names round-trip cleanly.
const String kMarkdownSep = ' — ';

/// A single list item recovered from a Markdown document by
/// [parseMarkdownItems]: just its name and done state.
class ParsedMarkdownItem {
  final String name;
  final bool done;

  const ParsedMarkdownItem({required this.name, required this.done});

  @override
  bool operator ==(Object other) =>
      other is ParsedMarkdownItem && other.name == name && other.done == done;

  @override
  int get hashCode => Object.hash(name, done);

  @override
  String toString() => 'ParsedMarkdownItem(name: $name, done: $done)';
}

String _isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final mo = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$mo-$day';
}

final _newlineRun = RegExp(r'\s*\n\s*');

String _formatItemLine(ListItem item) {
  final checkbox = item.done ? '[x]' : '[ ]';
  final parts = <String>[item.name.trim()];
  final qty = item.quantity?.trim();
  if (qty != null && qty.isNotEmpty) parts.add(qty);
  final desc = item.description?.trim();
  if (desc != null && desc.isNotEmpty) {
    parts.add(desc.replaceAll(_newlineRun, ' '));
  }
  return '- $checkbox ${parts.join(kMarkdownSep)}';
}

/// Build a Markdown document for a list: a title, an export date, then items
/// grouped under `## Category` headings (categories in first-seen order,
/// uncategorized items last).
String buildListMarkdown(
  String listName,
  List<ListItem> items,
  Category? Function(int? id) categoryFor, {
  DateTime? now,
}) {
  final lines = <String>[
    '# $listName',
    '',
    '_${m.checklists.markdown.exported(_isoDate(now ?? DateTime.now()))}_',
    '',
  ];

  final groups = <int?, List<ListItem>>{};
  final order = <int?>[];
  for (final item in items) {
    final key = item.categoryId;
    final bucket = groups.putIfAbsent(key, () {
      order.add(key);
      return <ListItem>[];
    });
    bucket.add(item);
  }

  final uncategorized = m.checklists.markdown.uncategorized;
  // Categories in first-seen order; the uncategorized bucket (null key) last.
  final keys = order.where((k) => k != null).toList();
  if (groups.containsKey(null)) keys.add(null);

  for (final key in keys) {
    final heading = key == null
        ? uncategorized
        : (categoryFor(key)?.name ?? uncategorized);
    lines.add('## $heading');
    for (final item in groups[key]!) {
      lines.add(_formatItemLine(item));
    }
    lines.add('');
  }

  return '${lines.join('\n').trimRight()}\n';
}

// Bullet (-, *, +) or ordered (1. / 1)) list item; captures the trailing text.
final _itemRe = RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+(.+)$');
// A leading `[ ]` / `[x]` checkbox on the captured text.
final _checkboxRe = RegExp(r'^\[(.)\]\s*(.*)$');

// A whole task-list line: leading marker, then the `[ ]` / `[x]` checkbox.
// Group 1 is everything up to and including the marker whitespace; group 2 is
// the single state character between the brackets.
final _taskLineRe = RegExp(r'^(\s*(?:[-*+]|\d+[.)])\s+)\[([ xX])\]');

/// One task-list line of a Markdown document, as [taskLines] reports it.
class TaskLine {
  /// State of the `[ ]` / `[x]` checkbox.
  final bool checked;

  /// Everything after the checkbox, trimmed. Excludes the state character, so
  /// a line still answers to the same text once its checkbox has been written.
  final String text;

  const TaskLine({required this.checked, required this.text});

  @override
  bool operator ==(Object other) =>
      other is TaskLine && other.checked == checked && other.text == text;

  @override
  int get hashCode => Object.hash(checked, text);

  @override
  String toString() => 'TaskLine(checked: $checked, text: $text)';
}

/// The task-list lines of [content], in document order. Their positions are the
/// ordinals [setChecklistItem] and [toggleChecklistItem] address.
List<TaskLine> taskLines(String content) {
  final out = <TaskLine>[];
  for (final line in content.split(RegExp(r'\r?\n'))) {
    final match = _taskLineRe.firstMatch(line);
    if (match == null) continue;
    out.add(
      TaskLine(
        checked: match.group(2)! != ' ',
        text: line.substring(match.end).trim(),
      ),
    );
  }
  return out;
}

/// Which task line a write recorded against [ordinal], on a line then reading
/// [text], should land on in the [content] as it stands now — or null when no
/// line can be named without guessing.
///
/// An ordinal only names the same line while the task lines are unchanged. A
/// line inserted or deleted above it before the write lands would otherwise
/// point the write at a neighbour and set a *definite* state on it, which is
/// the silent corruption a target state exists to avoid. So the text decides:
/// the ordinal is honoured only while it still reads as [text], and otherwise
/// the write follows the one line that does. Two lines reading alike name
/// nothing, and re-anchoring on a guess is worse than dropping the write.
int? resolveTaskLine(
  String content, {
  required int ordinal,
  required String text,
}) {
  final lines = taskLines(content);
  if (ordinal >= 0 && ordinal < lines.length && lines[ordinal].text == text) {
    return ordinal;
  }
  int? found;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].text != text) continue;
    if (found != null) return null;
    found = i;
  }
  return found;
}

/// Set the checkbox at position [ordinal] (0-based, counting only task-list
/// lines in document order) to [checked] within a Markdown document.
///
/// Indentation, list marker and the rest of the line are preserved. Returns
/// [content] unchanged when [ordinal] names no task line or that line already
/// holds [checked], which is what makes a queued write idempotent: replayed,
/// or landed after someone else set the same state, it converges rather than
/// undoing them.
String setChecklistItem(String content, int ordinal, bool checked) {
  final lines = content.split(RegExp(r'\r?\n'));
  var seen = 0;
  for (var i = 0; i < lines.length; i++) {
    final match = _taskLineRe.firstMatch(lines[i]);
    if (match == null) continue;
    if (seen == ordinal) {
      if ((match.group(2)! != ' ') == checked) return content;
      final state = checked ? 'x' : ' ';
      lines[i] = '${match.group(1)!}[$state]${lines[i].substring(match.end)}';
      return lines.join('\n');
    }
    seen++;
  }
  return content;
}

/// [content] with a recorded task-line write landed on it: the line
/// [resolveTaskLine] names is set to [checked] and, with [sink], moved by
/// [sinkTaskLine]. A line that already holds [checked] is left where it is, so
/// a write replayed over a body that has caught up with it changes nothing.
String applyTaskLineWrite(
  String content, {
  required int ordinal,
  required String text,
  required bool checked,
  bool sink = false,
}) {
  final target = resolveTaskLine(content, ordinal: ordinal, text: text);
  if (target == null) return content;
  final updated = setChecklistItem(content, target, checked);
  if (!sink || updated == content) return updated;
  return sinkTaskLine(updated, target);
}

final _leadingWhitespaceRe = RegExp(r'^\s*');

/// [content] with the task line at [ordinal] moved among its siblings to the
/// edge of its own state: a checked line to just below the last unchecked one,
/// an unchecked line to just above the first checked one. A line already on
/// its side of that boundary stays put, so lines that were left out of order
/// are not reshuffled around it.
///
/// Siblings are the task lines at the same indent in one unbroken run; a blank
/// line, a shallower line, or a non-task line at that indent ends the run. A
/// line moves together with its more deeply indented lines (sub-items,
/// continuations).
String sinkTaskLine(String content, int ordinal) {
  final lines = content.split(RegExp(r'\r?\n'));
  int indentOf(String line) => _leadingWhitespaceRe.firstMatch(line)!.end;

  int? at;
  var seen = 0;
  for (var i = 0; i < lines.length && at == null; i++) {
    if (_taskLineRe.hasMatch(lines[i]) && seen++ == ordinal) at = i;
  }
  if (at == null) return content;
  final indent = indentOf(lines[at]);

  bool isSibling(int i) =>
      _taskLineRe.hasMatch(lines[i]) && indentOf(lines[i]) == indent;
  bool isChild(int i) =>
      lines[i].trim().isNotEmpty && indentOf(lines[i]) > indent;

  var runStart = at;
  for (var i = at - 1; i >= 0; i--) {
    if (isChild(i)) continue;
    if (!isSibling(i)) break;
    runStart = i;
  }

  final entries = <({int start, int end, bool checked})>[];
  var i = runStart;
  while (i < lines.length && isSibling(i)) {
    final start = i;
    final checked = _taskLineRe.firstMatch(lines[i])!.group(2)! != ' ';
    i++;
    while (i < lines.length && isChild(i)) {
      i++;
    }
    entries.add((start: start, end: i, checked: checked));
  }

  final target = entries.indexWhere((e) => e.start == at);
  final moving = entries[target];
  final int insertAt;
  if (moving.checked) {
    final lastUnchecked = entries.lastIndexWhere((e) => !e.checked);
    if (lastUnchecked < target) return content;
    insertAt = lastUnchecked + 1;
  } else {
    final firstChecked = entries.indexWhere((e) => e.checked);
    if (firstChecked == -1 || firstChecked > target) return content;
    insertAt = firstChecked;
  }

  final order = [...entries]..removeAt(target);
  order.insert(insertAt > target ? insertAt - 1 : insertAt, moving);
  final run = [for (final e in order) ...lines.sublist(e.start, e.end)];
  lines.replaceRange(runStart, i, run);
  return lines.join('\n');
}

/// Flip the `[ ]` / `[x]` state of the checkbox at position [ordinal] (0-based,
/// counting only task-list lines in document order) within a Markdown document.
///
/// Indentation, list marker and the rest of the line are preserved. If [ordinal]
/// doesn't correspond to a checkbox line, [content] is returned unchanged.
///
/// A flip is only safe against a document nobody else is holding. Anything that
/// queues the write wants [setChecklistItem] instead.
String toggleChecklistItem(String content, int ordinal) {
  final lines = taskLines(content);
  if (ordinal < 0 || ordinal >= lines.length) return content;
  return setChecklistItem(content, ordinal, !lines[ordinal].checked);
}

/// Parse list items out of a Markdown document. Headings, the export-date line
/// and any other prose are ignored. The quantity/description suffix produced by
/// [buildListMarkdown] is stripped so only the item name is returned.
List<ParsedMarkdownItem> parseMarkdownItems(String text) {
  final out = <ParsedMarkdownItem>[];
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final match = _itemRe.firstMatch(line);
    if (match == null) continue;
    var name = match.group(1)!.trim();
    var done = false;
    final cb = _checkboxRe.firstMatch(name);
    if (cb != null) {
      done = cb.group(1)!.toLowerCase() == 'x';
      name = cb.group(2)!.trim();
    }
    final sepIdx = name.indexOf(kMarkdownSep);
    if (sepIdx != -1) name = name.substring(0, sepIdx).trim();
    if (name.isEmpty) continue;
    out.add(ParsedMarkdownItem(name: name, done: done));
  }
  return out;
}
