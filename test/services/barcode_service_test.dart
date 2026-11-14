import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/barcode_service.dart';

void main() {
  group('BarcodeService.isValidEan', () {
    test('accepts 6–14 digit codes', () {
      expect(BarcodeService.isValidEan('123456'), isTrue); // 6
      expect(BarcodeService.isValidEan('4001724819103'), isTrue); // EAN-13
      expect(BarcodeService.isValidEan('01234567890123'), isTrue); // 14
    });

    test('trims surrounding whitespace', () {
      expect(BarcodeService.isValidEan('  4001724819103  '), isTrue);
    });

    test('rejects too-short, too-long, and non-digit input', () {
      expect(BarcodeService.isValidEan('12345'), isFalse); // 5
      expect(BarcodeService.isValidEan('012345678901234'), isFalse); // 15
      expect(BarcodeService.isValidEan('40017a4819103'), isFalse);
      expect(BarcodeService.isValidEan(''), isFalse);
    });
  });

  group('BarcodeService.resultFromOffProduct', () {
    test('prefers the plain product name', () {
      final r = BarcodeService.resultFromOffProduct('4001724819103', {
        'lang': 'de',
        'product_name': 'Coca-Cola Zero',
        'product_name_de': 'Zero Cola',
        'brands': 'Coca-Cola, The Coca-Cola Company',
        'categories': 'Beverages, Sodas',
        'image_url': 'https://example.test/img.jpg',
      })!;

      expect(r.name, 'Coca-Cola Zero');
      expect(r.brand, 'Coca-Cola');
      expect(r.category, 'Beverages');
      expect(r.imageUrl, 'https://example.test/img.jpg');
      expect(r.provider, 'openfoodfacts');
    });

    test('uses the language-suffixed name when the plain one is empty', () {
      final r = BarcodeService.resultFromOffProduct('12345678', {
        'lang': 'de',
        'product_name': '  ',
        'product_name_de': 'Apple juice',
        'product_name_en': 'Orange juice',
      })!;

      expect(r.name, 'Apple juice');
    });

    test('falls back to the English name when the lang one is empty', () {
      final r = BarcodeService.resultFromOffProduct('12345678', {
        'lang': 'de',
        'product_name': '',
        'product_name_en': 'Apple juice',
        'generic_name': 'Juice',
      })!;

      expect(r.name, 'Apple juice');
    });

    test('uses the first category when the product is unnamed', () {
      final r = BarcodeService.resultFromOffProduct('4063367386923', {
        'lang': 'de',
        'product_name': '',
        'product_name_de': '',
        'generic_name': '',
        'generic_name_de': '',
        'brands': 'Acme, Acme Foods',
        'categories': 'Iced teas, Sweetened beverages',
      })!;

      expect(r.name, 'Iced teas');
      expect(r.brand, 'Acme');
      expect(r.category, 'Iced teas');
    });

    test('uses the first brand when unnamed and uncategorized', () {
      final r = BarcodeService.resultFromOffProduct('12345678', {
        'product_name': '',
        'brands': 'Acme, Acme Foods',
      })!;

      expect(r.name, 'Acme');
      expect(r.category, isNull);
    });

    test('returns null when there is nothing to name the product', () {
      final r = BarcodeService.resultFromOffProduct('12345678', {
        'product_name': '',
        'image_url': 'https://example.test/img.jpg',
      });

      expect(r, isNull);
    });
  });

  group('BarcodeResult.fromJson', () {
    test('reads all PantryBarcode keys', () {
      final r = BarcodeResult.fromJson({
        'ean': '4001724819103',
        'name': 'Coca-Cola Zero',
        'brand': 'Coca-Cola',
        'category': 'Beverages',
        'imageUrl': 'https://example.test/img.jpg',
        'provider': 'openfoodfacts',
      });

      expect(r.ean, '4001724819103');
      expect(r.name, 'Coca-Cola Zero');
      expect(r.brand, 'Coca-Cola');
      expect(r.category, 'Beverages');
      expect(r.imageUrl, 'https://example.test/img.jpg');
      expect(r.provider, 'openfoodfacts');
    });

    test('tolerates null optional fields and defaults the provider', () {
      final r = BarcodeResult.fromJson({'ean': '12345678', 'name': 'Generic'});

      expect(r.brand, isNull);
      expect(r.category, isNull);
      expect(r.imageUrl, isNull);
      expect(r.provider, 'openfoodfacts');
    });

    test('toJson omits null optional fields', () {
      const r = BarcodeResult(
        ean: '12345678',
        name: 'Generic',
        provider: 'openfoodfacts',
      );

      final json = r.toJson();
      expect(json.containsKey('brand'), isFalse);
      expect(json.containsKey('category'), isFalse);
      expect(json.containsKey('imageUrl'), isFalse);
      expect(json['ean'], '12345678');
      expect(json['name'], 'Generic');
    });
  });
}
