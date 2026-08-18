import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// Shared markdown ⇄ Quill conversion used by the WYSIWYG editor. Notes and item
/// descriptions are stored (and co-edited by the Nextcloud web app) as raw
/// markdown, so these converters are tuned for a faithful, idempotent
/// round-trip — see test/utils/markdown_quill_roundtrip_test.dart.

/// gitHubFlavored gives us task-list checkboxes (`- [ ]`) and strikethrough,
/// which the app relies on. [md.Document] is single-use per parse, so build a
/// fresh converter each time rather than sharing one instance.
MarkdownToDelta _mdToDelta() => MarkdownToDelta(
  markdownDocument: md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  ),
);

/// The relaxed escaper only escapes markdown metacharacters inside styled runs,
/// so plain prose keeps its punctuation (`bread.` stays `bread.`, not `bread\.`).
final _deltaToMd = DeltaToMarkdown(
  customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
);

/// Parse [markdown] into a Quill [Delta].
Delta markdownToDelta(String markdown) => _mdToDelta().convert(markdown);

/// Serialize a Quill [delta] back to markdown, trimming the trailing newline
/// Quill always keeps on its document. An empty delta yields empty markdown —
/// [DeltaToMarkdown] builds a [Document] internally, which rejects an empty delta.
String deltaToMarkdown(Delta delta) {
  if (delta.isEmpty) return '';
  return _deltaToMd.convert(delta).trimRight();
}

/// The markdown [source] as it would be re-emitted after a round-trip through
/// the editor. Comparing a field's current value against the normalized form of
/// what was loaded lets callers tell a real edit from cosmetic normalization,
/// so merely opening and closing a field never rewrites stored markdown.
String normalizeMarkdown(String source) =>
    deltaToMarkdown(markdownToDelta(source));

/// Build a Quill [Document] from [markdown]. Empty input yields an empty
/// document; otherwise the parsed delta is given the trailing newline
/// [Document.fromDelta] requires.
Document markdownToDocument(String markdown) {
  if (markdown.trim().isEmpty) return Document();
  return Document.fromDelta(_withTrailingNewline(markdownToDelta(markdown)));
}

/// Read the current markdown out of a Quill [document].
String documentToMarkdown(Document document) =>
    deltaToMarkdown(document.toDelta());

Delta _withTrailingNewline(Delta delta) {
  final ops = delta.toList();
  if (ops.isEmpty) return Delta()..insert('\n');
  final last = ops.last.data;
  if (last is String && last.endsWith('\n')) return delta;
  return Delta.from(delta)..insert('\n');
}
