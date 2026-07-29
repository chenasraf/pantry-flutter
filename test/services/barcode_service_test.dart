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
