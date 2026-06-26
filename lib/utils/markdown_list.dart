import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';

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
