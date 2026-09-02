import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/link_detection.dart';

void main() {
  group('detectLinks', () {
    List<String> urls(String text) =>
        detectLinks(text).where((s) => s.isLink).map((s) => s.url!).toList();

    test('leaves plain text as a single segment', () {
      expect(detectLinks('just some text'), [
        const LinkSegment('just some text'),
      ]);
    });

    test('splits around an http address', () {
      expect(detectLinks('see https://example.com now'), [
        const LinkSegment('see '),
        const LinkSegment('https://example.com', 'https://example.com'),
        const LinkSegment(' now'),
      ]);
    });

    test('gives www addresses an https scheme', () {
      expect(urls('www.example.com/path'), ['https://www.example.com/path']);
    });

    test('gives bare email addresses a mailto scheme', () {
      expect(urls('write to a.b+c@example.co.uk please'), [
        'mailto:a.b+c@example.co.uk',
      ]);
    });

    test('keeps an @ inside a web address out of the email match', () {
      expect(urls('https://user@example.com/x'), [
        'https://user@example.com/x',
      ]);
    });

    test('drops trailing sentence punctuation', () {
      expect(urls('go to https://example.com/a.'), ['https://example.com/a']);
      expect(urls('"https://example.com",'), ['https://example.com']);
    });

    test('keeps balanced brackets but drops unbalanced ones', () {
      expect(urls('https://en.wikipedia.org/wiki/Dart_(language)'), [
        'https://en.wikipedia.org/wiki/Dart_(language)',
      ]);
      expect(urls('(see https://example.com/a)'), ['https://example.com/a']);
    });

    test('finds several links in one value', () {
      expect(urls('https://a.example and https://b.example'), [
        'https://a.example',
        'https://b.example',
      ]);
    });

    test('detects non-http schemes', () {
      expect(urls('ftp://files.example.com/x'), ['ftp://files.example.com/x']);
    });

    test('hasLink reports whether anything was found', () {
      expect(hasLink('nothing here'), isFalse);
      expect(hasLink('here: me@example.com'), isTrue);
    });
  });
}
