import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/text_direction.dart';

void main() {
  group('detectTextDirection', () {
    test('null returns LTR', () {
      expect(detectTextDirection(null), TextDirection.ltr);
    });

    test('empty returns LTR', () {
      expect(detectTextDirection(''), TextDirection.ltr);
    });

    test('whitespace-only returns LTR', () {
      expect(detectTextDirection('   \t\n'), TextDirection.ltr);
    });

    test('English string returns LTR', () {
      expect(detectTextDirection('Hello world'), TextDirection.ltr);
    });

    test('CJK string returns LTR', () {
      expect(detectTextDirection('你好世界'), TextDirection.ltr);
      expect(detectTextDirection('こんにちは'), TextDirection.ltr);
      expect(detectTextDirection('안녕하세요'), TextDirection.ltr);
    });

    test('Cyrillic string returns LTR', () {
      expect(detectTextDirection('Привет мир'), TextDirection.ltr);
    });

    test('Greek string returns LTR', () {
      expect(detectTextDirection('Γειά σου'), TextDirection.ltr);
    });

    test('Hebrew string returns RTL', () {
      expect(detectTextDirection('שלום עולם'), TextDirection.rtl);
    });

    test('Arabic string returns RTL', () {
      expect(detectTextDirection('مرحبا بالعالم'), TextDirection.rtl);
    });

    test('Syriac string returns RTL', () {
      // Syriac letter alaph (U+0710)
      expect(detectTextDirection('\u0710\u0712\u0713'), TextDirection.rtl);
    });

    test('digits prefix followed by RTL is RTL', () {
      expect(detectTextDirection('123 שלום'), TextDirection.rtl);
    });

    test('punctuation prefix followed by RTL is RTL', () {
      expect(detectTextDirection('!!! مرحبا'), TextDirection.rtl);
    });

    test('emoji prefix followed by RTL is RTL', () {
      expect(detectTextDirection('🚀 שלום'), TextDirection.rtl);
    });

    test('digits prefix followed by LTR is LTR', () {
      expect(detectTextDirection('123 Hello'), TextDirection.ltr);
    });

    test('punctuation prefix followed by LTR is LTR', () {
      expect(detectTextDirection('??? Hello'), TextDirection.ltr);
    });

    test('emoji prefix followed by LTR is LTR', () {
      expect(detectTextDirection('🚀 Hello'), TextDirection.ltr);
    });

    test('only neutrals returns LTR', () {
      expect(detectTextDirection('123 !!!'), TextDirection.ltr);
      expect(detectTextDirection('🚀🌟'), TextDirection.ltr);
    });
  });
}
