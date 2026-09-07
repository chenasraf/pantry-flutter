/// A run of text, either plain or carrying the [url] it links to.
class LinkSegment {
  final String text;
  final String? url;

  const LinkSegment(this.text, [this.url]);

  bool get isLink => url != null;

  @override
  bool operator ==(Object other) =>
      other is LinkSegment && other.text == text && other.url == url;

  @override
  int get hashCode => Object.hash(text, url);

  @override
  String toString() => 'LinkSegment($text, $url)';
}

final _linkRegex = RegExp(
  // Scheme-qualified or www-prefixed web address
  r'(?:[a-z][a-z0-9+.-]*://|www\.)[^\s<>"'
  "'"
  r']+'
  // Bare email address
  r"|[\w.!#$%&*+/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)+",
  caseSensitive: false,
);

/// Trailing characters that read as sentence punctuation rather than part of a
/// URL. A closing bracket only counts as punctuation when the match has no
/// matching opener, so `https://en.wikipedia.org/wiki/Dart_(language)` survives.
const _trailingPunctuation = '.,;:!?\'"«»“”‘’';

/// Split [text] into plain and link segments, detecting web addresses and bare
/// email addresses. Link segments carry a launchable URL — email addresses get
/// a `mailto:` scheme and `www.` addresses an `https://` one — while [text]
/// keeps whatever the user typed.
List<LinkSegment> detectLinks(String text) {
  final segments = <LinkSegment>[];
  var cursor = 0;

  for (final match in _linkRegex.allMatches(text)) {
    var raw = match[0]!;
    raw = raw.substring(0, _linkEnd(raw));
    if (raw.isEmpty) continue;

    final start = match.start;
    if (start > cursor) {
      segments.add(LinkSegment(text.substring(cursor, start)));
    }
    segments.add(LinkSegment(raw, _toUrl(raw)));
    cursor = start + raw.length;
  }

  if (cursor < text.length) segments.add(LinkSegment(text.substring(cursor)));
  return segments;
}

/// Whether [text] holds at least one detectable link.
bool hasLink(String text) => detectLinks(text).any((s) => s.isLink);

/// The index just past the last character that still belongs to [raw], after
/// shedding trailing punctuation and unbalanced closing brackets.
int _linkEnd(String raw) {
  var end = raw.length;
  while (end > 0) {
    final char = raw[end - 1];
    if (_trailingPunctuation.contains(char)) {
      end--;
    } else if (_closers.containsKey(char) &&
        !_isBalanced(raw.substring(0, end), char)) {
      end--;
    } else {
      break;
    }
  }
  return end;
}

const _closers = {')': '(', ']': '[', '}': '{'};

bool _isBalanced(String text, String closer) {
  final opener = _closers[closer]!;
  var depth = 0;
  for (final char in text.split('')) {
    if (char == opener) depth++;
    if (char == closer) depth--;
  }
  return depth == 0;
}

String _toUrl(String raw) {
  if (raw.contains('@') && !raw.contains('://')) return 'mailto:$raw';
  if (raw.toLowerCase().startsWith('www.')) return 'https://$raw';
  return raw;
}
