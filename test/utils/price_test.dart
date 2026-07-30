import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/price.dart';

ListItem priced({
  String? priceType,
  double? priceMin,
  double? priceMax,
  String? priceCurrency,
}) => ListItem(
  id: 1,
  listId: 2,
  name: 'Milk',
  done: false,
  repeatFromCompletion: false,
  deleteOnDone: false,
  sortOrder: 0,
  createdAt: 100,
  updatedAt: 200,
  priceType: priceType,
  priceMin: priceMin,
  priceMax: priceMax,
  priceCurrency: priceCurrency,
);

String? fmt({
  String? priceType,
  double? priceMin,
  double? priceMax,
  String? priceCurrency,
}) => formatPrice(
  priceType: priceType,
  priceMin: priceMin,
  priceMax: priceMax,
  priceCurrency: priceCurrency,
);

void main() {
  group('formatPrice', () {
    test('returns null when there is no price', () {
      expect(fmt(priceType: null, priceMin: null), isNull);
      expect(fmt(priceType: 'set', priceMin: null), isNull);
    });

    test('places a before-symbol currency in front (USD)', () {
      expect(fmt(priceType: 'set', priceMin: 1, priceCurrency: 'USD'), r'$1');
    });

    test('places an after-symbol currency behind (ILS)', () {
      expect(fmt(priceType: 'set', priceMin: 1, priceCurrency: 'ILS'), '1₪');
    });

    test('renders a range with a plain hyphen', () {
      expect(
        fmt(
          priceType: 'range',
          priceMin: 1,
          priceMax: 10,
          priceCurrency: 'USD',
        ),
        r'$1-10',
      );
      expect(
        fmt(
          priceType: 'range',
          priceMin: 1,
          priceMax: 10,
          priceCurrency: 'ILS',
        ),
        '1-10₪',
      );
    });

    test('trims trailing zeros but keeps significant decimals', () {
      expect(fmt(priceType: 'set', priceMin: 1.0, priceCurrency: 'USD'), r'$1');
      expect(
        fmt(priceType: 'set', priceMin: 1.5, priceCurrency: 'USD'),
        r'$1.5',
      );
      expect(
        fmt(priceType: 'set', priceMin: 9.99, priceCurrency: 'USD'),
        r'$9.99',
      );
    });

    test('unknown currency shows the raw code before the amount', () {
      expect(fmt(priceType: 'set', priceMin: 5, priceCurrency: 'ZZZ'), 'ZZZ5');
    });

    test('a range missing its max falls back to the min only', () {
      expect(fmt(priceType: 'range', priceMin: 3, priceCurrency: 'USD'), r'$3');
    });
  });

  group('matchesPriceFilter', () {
    test('items with no price never match an active filter', () {
      expect(matchesPriceFilter(priced(), const PriceFilter(min: 1)), isFalse);
    });

    test('a set price is a zero-width range against min/max bounds', () {
      final item = priced(priceType: 'set', priceMin: 5, priceCurrency: 'USD');
      expect(matchesPriceFilter(item, const PriceFilter(min: 3)), isTrue);
      expect(matchesPriceFilter(item, const PriceFilter(min: 6)), isFalse);
      expect(matchesPriceFilter(item, const PriceFilter(max: 5)), isTrue);
      expect(matchesPriceFilter(item, const PriceFilter(max: 4)), isFalse);
    });

    test('a range price passes when it overlaps the filter bounds', () {
      final item = priced(
        priceType: 'range',
        priceMin: 5,
        priceMax: 10,
        priceCurrency: 'USD',
      );
      // Overlap on the low end.
      expect(matchesPriceFilter(item, const PriceFilter(max: 6)), isTrue);
      // Overlap on the high end.
      expect(matchesPriceFilter(item, const PriceFilter(min: 9)), isTrue);
      // Entirely below the filter's min.
      expect(matchesPriceFilter(item, const PriceFilter(min: 11)), isFalse);
      // Entirely above the filter's max.
      expect(matchesPriceFilter(item, const PriceFilter(max: 4)), isFalse);
    });

    test('a currency filter only matches items in that currency', () {
      final usd = priced(priceType: 'set', priceMin: 5, priceCurrency: 'USD');
      final ils = priced(priceType: 'set', priceMin: 5, priceCurrency: 'ILS');
      expect(
        matchesPriceFilter(usd, const PriceFilter(currency: 'USD')),
        isTrue,
      );
      expect(
        matchesPriceFilter(ils, const PriceFilter(currency: 'USD')),
        isFalse,
      );
      // Case-insensitive on the item's stored code.
      final lower = priced(priceType: 'set', priceMin: 5, priceCurrency: 'usd');
      expect(
        matchesPriceFilter(lower, const PriceFilter(currency: 'USD')),
        isTrue,
      );
    });

    test('null currency compares amounts verbatim across currencies', () {
      final ils = priced(priceType: 'set', priceMin: 5, priceCurrency: 'ILS');
      expect(matchesPriceFilter(ils, const PriceFilter(min: 3)), isTrue);
    });

    test('isActive reflects any set bound or currency', () {
      expect(PriceFilter.empty.isActive, isFalse);
      expect(const PriceFilter(min: 1).isActive, isTrue);
      expect(const PriceFilter(currency: 'USD').isActive, isTrue);
    });
  });
}
