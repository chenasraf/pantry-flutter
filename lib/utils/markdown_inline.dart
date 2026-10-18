import 'package:flutter/services.dart';

/// The inline formats a GFM table cell can hold.
enum InlineStyle { bold, italic, strikethrough, code, link }

/// A run of inline markdown source: either a [marker] (`**`, `](url)`, …) or
/// content carrying the [styles] its enclosing markers apply. Concatenating
/// every segment's [text] gives back the source exactly.
class InlineSegment {
  final String text;
  final bool marker;
  final Set<InlineStyle> styles;

  const InlineSegment(this.text, {this.marker = false, this.styles = const {}});
}

class _Syntax {
  final RegExp pattern;
  final InlineStyle style;

  /// Length of the opening marker. Group 1 holds the content, except for code
  /// spans, whose fence length varies: group 1 is the fence, group 2 the code.
  final int openLength;

  const _Syntax(this.pattern, this.style, this.openLength);

  bool get isCode => style == InlineStyle.code;
}

/// Checked in order, so on a tie at the same offset `**` wins over `*`.
final _syntaxes = [
  _Syntax(RegExp(r'(`+)(.+?)\1'), InlineStyle.code, 0),
  _Syntax(RegExp(r'\[([^\]]+)\]\(([^)]*)\)'), InlineStyle.link, 1),
  _Syntax(RegExp(r'\*\*(?=\S)(.+?)(?<=\S)\*\*'), InlineStyle.bold, 2),
  _Syntax(RegExp(r'__(?=\S)(.+?)(?<=\S)__'), InlineStyle.bold, 2),
  _Syntax(RegExp(r'~~(?=\S)(.+?)(?<=\S)~~'), InlineStyle.strikethrough, 2),
  _Syntax(RegExp(r'\*(?=[^\s*])(.+?)(?<=[^\s*])\*'), InlineStyle.italic, 1),
  _Syntax(
    RegExp(r'(?<!\w)_(?=[^\s_])(.+?)(?<=[^\s_])_(?!\w)'),
    InlineStyle.italic,
    1,
  ),
];

/// Splits [source] into marker and styled content segments.
List<InlineSegment> parseInlineMarkdown(String source) =>
    _parse(source, const {});

List<InlineSegment> _parse(String source, Set<InlineStyle> styles) {
  final segments = <InlineSegment>[];
  var rest = source;
  while (rest.isNotEmpty) {
    RegExpMatch? best;
    _Syntax? bestSyntax;
    for (final syntax in _syntaxes) {
      final match = syntax.pattern.firstMatch(rest);
      if (match != null && (best == null || match.start < best.start)) {
        best = match;
        bestSyntax = syntax;
      }
    }
    if (best == null || bestSyntax == null) {
      segments.add(InlineSegment(rest, styles: styles));
      break;
    }
    if (best.start > 0) {
      segments.add(
        InlineSegment(rest.substring(0, best.start), styles: styles),
      );
    }
    final whole = best[0]!;
    final code = bestSyntax.isCode;
    final inner = code ? best[2]! : best[1]!;
    final open = whole.substring(
      0,
      code ? best[1]!.length : bestSyntax.openLength,
    );
    final close = whole.substring(open.length + inner.length);
    final innerStyles = {...styles, bestSyntax.style};
    segments
      ..add(InlineSegment(open, marker: true, styles: innerStyles))
      ..addAll(
        // Code spans hold literal text; nothing inside them is markdown.
        code
            ? [InlineSegment(inner, styles: innerStyles)]
            : _parse(inner, innerStyles),
      )
      ..add(InlineSegment(close, marker: true, styles: innerStyles));
    rest = rest.substring(best.end);
  }
  return segments;
}

/// The marker written around a selection for each wrapping style. Italic uses
/// `_` so it can't run into a neighbouring `**`.
const _wrapMarkers = {
  InlineStyle.bold: '**',
  InlineStyle.italic: '_',
  InlineStyle.strikethrough: '~~',
  InlineStyle.code: '`',
};

/// Whether [style]'s markers directly enclose the selection in [value] — the
/// state in which [toggleInlineStyle] unwraps rather than wraps.
bool isInlineStyleActive(TextEditingValue value, InlineStyle style) {
  final marker = _wrapMarkers[style];
  if (marker == null || !value.selection.isValid) return false;
  return _enclosingMarkers(value, marker) != null;
}

/// Adds or removes [style]'s markers around the selection in [value]. A link
/// wraps the selection as `[text]()` with the caret left in the parentheses
/// for the address.
TextEditingValue toggleInlineStyle(TextEditingValue value, InlineStyle style) {
  final selection = value.selection;
  if (!selection.isValid) return value;
  final text = value.text;
  final start = selection.start;
  final end = selection.end;

  if (style == InlineStyle.link) {
    final selected = text.substring(start, end);
    final wrapped = '[$selected]()';
    return TextEditingValue(
      text: text.replaceRange(start, end, wrapped),
      selection: TextSelection.collapsed(offset: start + wrapped.length - 1),
    );
  }

  final marker = _wrapMarkers[style]!;
  final enclosing = _enclosingMarkers(value, marker);
  if (enclosing != null) {
    final (openAt, closeAt) = enclosing;
    final unwrapped = text
        .replaceRange(closeAt, closeAt + marker.length, '')
        .replaceRange(openAt, openAt + marker.length, '');
    final shift = openAt < start ? marker.length : 0;
    return TextEditingValue(
      text: unwrapped,
      selection: TextSelection(
        baseOffset: start - shift,
        extentOffset: end - shift - (openAt < start ? 0 : marker.length * 2),
      ),
    );
  }

  return TextEditingValue(
    text: text
        .replaceRange(end, end, marker)
        .replaceRange(start, start, marker),
    selection: TextSelection(
      baseOffset: start + marker.length,
      extentOffset: end + marker.length,
    ),
  );
}

/// Offsets of the opening and closing [marker] enclosing the selection,
/// either just outside it (`**|sel|**`) or as its own first and last
/// characters (`|**sel**|`).
(int, int)? _enclosingMarkers(TextEditingValue value, String marker) {
  final text = value.text;
  final start = value.selection.start;
  final end = value.selection.end;
  final m = marker.length;

  bool markerAt(int at) {
    if (at < 0 || at + m > text.length) return false;
    if (text.substring(at, at + m) != marker) return false;
    // A lone `_` or `` ` `` that is really half of a longer run (`__`) isn't
    // this marker.
    final ch = marker[0];
    final before = at > 0 ? text[at - 1] : '';
    final after = at + m < text.length ? text[at + m] : '';
    return marker.length > 1 || (before != ch && after != ch);
  }

  if (markerAt(start - m) && markerAt(end)) return (start - m, end);
  if (end - start >= m * 2 && markerAt(start) && markerAt(end - m)) {
    return (start, end - m);
  }
  return null;
}
