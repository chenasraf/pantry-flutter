/// How much of a description is read before flattening. A preview occupies a
/// single line, so text past this point can never be drawn, and a description
/// has no length limit — the cap keeps a row's cost the same whether its
/// description is a word or an essay. It sits well above the widest row a
/// maximised desktop window can fit, so the ellipsis a reader sees is always
/// the text widget's own rather than this cut.
const int _scanLimit = 500;

/// A line carrying no text of its own: a thematic break, a code fence, or a
/// table's separator row.
final _structuralLine = RegExp(
  r'^\s*(?:(?:[-*_]\s*){3,}|[`~]{3,}.*|\|?[\s:|-]*\|[\s:|-]*)$',
);

/// What opens a line without being part of what it says: blockquote carets, an
/// ATX heading's hashes, a list bullet or number, a task list's checkbox.
final _lineMarkers = RegExp(
  r'^(?:\s*>)*\s*(?:#{1,6}\s+|(?:[-*+]|\d+[.)])\s+)?(?:\[[ xX]\]\s*)?',
);

final _htmlComment = RegExp(r'<!--.*?-->', dotAll: true);
final _image = RegExp(r'!\[([^\]]*)\]\([^)]*\)');
final _inlineLink = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final _refLink = RegExp(r'\[([^\]]*)\]\[[^\]]*\]');
final _autolink = RegExp(r'<((?:https?|mailto):[^>\s]+)>');
final _htmlTag = RegExp(r'</?[A-Za-z][^>]*>');
final _code = RegExp(r'`+([^`]*)`+');
final _strong = RegExp(r'(\*\*|__|~~)(?=\S)(.+?)(?<=\S)\1');
// Bounded by non-word characters so a snake_case identifier or a lone
// multiplication sign isn't read as an emphasis delimiter.
final _emphasis = RegExp(
  r'(?<![A-Za-z0-9])([*_])(?=\S)(.+?)(?<=\S)\1(?![A-Za-z0-9])',
);
final _escape = RegExp(r'\\([\\`*_{}\[\]()#+\-.!>~|])');
final _whitespace = RegExp(r'\s+');

/// Escaped punctuation is parked on a private-use code point for the length of
/// the inline passes and put back at the end. Stripping the backslash up front
/// would leave a bare `*` for the emphasis pass to read as a delimiter, and
/// stripping it last means the emphasis pass gets there first.
const int _guardBase = 0xE100;
final _guarded = RegExp(r'[-]');

/// Separates two lines of the source. Every newline is a visible break where
/// the description is rendered in full, so each one earns a mark here rather
/// than dissolving into a space that reads as though the author wrote one
/// running sentence.
const String _lineSep = ' · ';

/// [source] as one line of plain text — the opening of a Markdown description,
/// for a row that has room to show it but not to render it.
///
/// Formatting is dropped rather than approximated: a preview is read at a
/// glance beside an item's name, and half-rendered syntax (`**`, `- [x]`) is
/// noise at that size. Links and images keep their text and alt text, which is
/// the part a reader recognises the item by.
///
/// Returns an empty string for a description carrying no text of its own — a
/// horizontal rule, an image with no alt text — so callers can fall back to
/// whatever they show for an item with no description to preview.
String markdownPreview(String source) {
  var scanned = source.length > _scanLimit
      ? source.substring(0, _scanLimit)
      : source;
  // Never cut between the halves of a surrogate pair: the orphan renders as a
  // replacement glyph, and it would sit at the end of every preview of a
  // description long enough to be cut mid-emoji.
  if (scanned.length < source.length &&
      _isHighSurrogate(scanned.codeUnitAt(scanned.length - 1))) {
    scanned = scanned.substring(0, scanned.length - 1);
  }

  final lines = <String>[];
  for (final line in scanned.split(RegExp(r'\r?\n'))) {
    if (_structuralLine.hasMatch(line)) continue;
    final stripped = line.replaceFirst(_lineMarkers, '').trim();
    if (stripped.isNotEmpty) lines.add(stripped);
  }

  return lines
      .join(_lineSep)
      .replaceAllMapped(
        _escape,
        (m) => String.fromCharCode(_guardBase + m[1]!.codeUnitAt(0)),
      )
      .replaceAll(_htmlComment, '')
      .replaceAllMapped(_image, (m) => m[1]!)
      .replaceAllMapped(_inlineLink, (m) => m[1]!)
      .replaceAllMapped(_refLink, (m) => m[1]!)
      .replaceAllMapped(_autolink, (m) => m[1]!)
      .replaceAll(_htmlTag, '')
      .replaceAllMapped(_code, (m) => m[1]!)
      .replaceAllMapped(_strong, (m) => m[2]!)
      .replaceAllMapped(_emphasis, (m) => m[2]!)
      .replaceAllMapped(
        _guarded,
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - _guardBase),
      )
      .replaceAll(_whitespace, ' ')
      .trim();
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
