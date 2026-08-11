import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

/// Fidelity checks for the markdown ⇄ Delta conversion behind the WYSIWYG
/// editor. These notes/descriptions are co-edited by the Nextcloud web app as
/// raw markdown, so what matters is:
///
///  1. The structures the app relies on (task-list checkboxes, links, lists,
///     headings, code) survive a round-trip exactly.
///  2. Conversion is *idempotent* — once a document has passed through the
///     editor, editing and saving it again does not keep rewriting it. This is
///     what prevents progressive corruption (e.g. escape characters piling up)
///     across repeated edits.
///
/// A WYSIWYG editor inevitably normalizes some cosmetic markdown (emphasis
/// `*x*` becomes `_x_`; a blank line is inserted between block elements). Those
/// render identically and, thanks to idempotency, only ever happen once.
void main() {
  final mdToDelta = MarkdownToDelta(
    markdownDocument: md.Document(
      encodeHtml: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ),
  );
  // The relaxed escaper only escapes inside styled runs, so plain prose keeps
  // its punctuation instead of turning "bread." into "bread\.".
  final deltaToMd = DeltaToMarkdown(
    customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
  );

  String normalize(String source) {
    final Delta delta = mdToDelta.convert(source);
    return deltaToMd.convert(delta).trimRight();
  }

  /// Structures we must never mangle: normalizing them returns them verbatim.
  void expectExact(String source) {
    expect(normalize(source), source, reason: 'source: $source');
  }

  /// The core guarantee: a second pass changes nothing.
  void expectIdempotent(String source) {
    final once = normalize(source);
    final twice = normalize(once);
    expect(twice, once, reason: 'not idempotent for: $source');
  }

  group('critical structures survive exactly', () {
    test('task-list checkboxes, both states', () {
      expectExact('- [ ] unchecked');
      expectExact('- [x] checked');
      expectExact('- [ ] milk\n- [x] eggs');
    });

    test('links', () {
      expectExact('[the docs](https://example.com)');
    });

    test('headings', () {
      expectExact('# Heading one');
      expectExact('## Heading two');
      expectExact('### Heading three');
    });

    test('bullet and numbered lists', () {
      expectExact('- one\n- two\n- three');
      expectExact('1. one\n2. two\n3. three');
    });

    test('bold and inline code', () {
      expectExact('This is **bold** text');
      expectExact('Some `inline code` here');
    });

    test('plain prose with punctuation is left alone', () {
      expectExact('Buy milk and bread.');
      expectExact('Remember: eggs, butter, and jam.');
    });
  });

  group('conversion is idempotent', () {
    test('emphasis normalizes once then holds', () {
      // *italic* -> _italic_ on the first pass, stable thereafter.
      expect(normalize('*italic*'), '_italic_');
      expectIdempotent('*italic*');
      expectIdempotent('~~struck~~');
    });

    test('a realistic mixed document is stable after one pass', () {
      const doc =
          '# Shopping\n'
          'Buy **milk** and *bread*.\n'
          '- [ ] milk\n'
          '- [x] eggs\n'
          '1. first\n'
          '2. second\n'
          '> remember the [coupon](https://example.com)';
      expectIdempotent(doc);
    });
  });
}
