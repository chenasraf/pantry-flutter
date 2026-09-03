import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';

void main() {
  tearDown(() => ServerVersionService.instance.debugSeed());

  void seedPerStore(bool enabled) {
    ServerVersionService.instance.debugSeed(
      features: {if (enabled) kItemPricePerStoreFeature: true},
      featuresAuthoritative: true,
    );
  }

  const storeless = ItemPrice(
    priceType: 'set',
    priceMin: 5,
    priceCurrency: 'USD',
  );
  const forStore = ItemPrice(
    storeId: 12,
    priceType: 'range',
    priceMin: 4,
    priceMax: 6,
    priceCurrency: 'USD',
  );

  test('null prices omit the field in both modes', () {
    seedPerStore(true);
    expect(itemPriceBody(null, isUpdate: false), isEmpty);
    expect(itemPriceBody(null, isUpdate: true), isEmpty);
    seedPerStore(false);
    expect(itemPriceBody(null, isUpdate: true), isEmpty);
  });

  group('item-price-per-store server', () {
    setUp(() => seedPerStore(true));

    test('sends the full prices array', () {
      final body = itemPriceBody(const [storeless, forStore], isUpdate: false);
      expect(body.keys, ['prices']);
      final prices = body['prices'] as List;
      expect(prices, hasLength(2));
      expect(prices[1]['storeId'], 12);
      expect(prices[1]['priceMax'], 6);
    });

    test('an empty list is sent as an empty array (clears all)', () {
      expect(itemPriceBody(const [], isUpdate: true), {'prices': []});
    });
  });

  group('legacy single-price server', () {
    setUp(() => seedPerStore(false));

    test('collapses to the store-less price as flat fields', () {
      final body = itemPriceBody(const [storeless, forStore], isUpdate: false);
      expect(body, {'priceType': 'set', 'priceMin': 5, 'priceCurrency': 'USD'});
    });

    test('a range store-less price includes the max', () {
      final body = itemPriceBody(const [
        ItemPrice(
          priceType: 'range',
          priceMin: 4,
          priceMax: 6,
          priceCurrency: 'USD',
        ),
      ], isUpdate: false);
      expect(body['priceMax'], 6);
    });

    test('no usable store-less price clears via the sentinel on update', () {
      // Only a per-store price exists — nothing the legacy server can store.
      expect(itemPriceBody(const [forStore], isUpdate: true), {
        'priceType': '',
      });
    });

    test('no usable store-less price sends nothing on create', () {
      expect(itemPriceBody(const [forStore], isUpdate: false), isEmpty);
      expect(itemPriceBody(const [], isUpdate: false), isEmpty);
    });

    test('an empty list clears via the sentinel on update', () {
      expect(itemPriceBody(const [], isUpdate: true), {'priceType': ''});
    });
  });
}
