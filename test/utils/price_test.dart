import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/price.dart';

ItemPrice price({
  int? storeId,
  String? priceType,
  double? priceMin,
  double? priceMax,
  String? priceCurrency,
}) => ItemPrice(
  storeId: storeId,
  priceType: priceType,
  priceMin: priceMin,
  priceMax: priceMax,
  priceCurrency: priceCurrency,
);

ListItem priced(List<ItemPrice> prices) => ListItem(
  id: 1,
  listId: 2,
  name: 'Milk',
  done: false,
  repeatFromCompletion: false,
  deleteOnDone: false,
  sortOrder: 0,
  createdAt: 100,
  updatedAt: 200,
  prices: prices,
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

  group('storelessPrice / resolveItemPrice', () {
    final storeless = price(
      priceType: 'set',
      priceMin: 5,
      priceCurrency: 'USD',
    );
    final forStore12 = price(
      storeId: 12,
      priceType: 'set',
      priceMin: 4,
      priceCurrency: 'USD',
    );

    test('storelessPrice returns the null-store entry, else null', () {
      expect(storelessPrice([storeless, forStore12]), storeless);
      expect(storelessPrice([forStore12]), isNull);
    });

    test(
      'resolveItemPrice prefers the store price, falls back to store-less',
      () {
        expect(resolveItemPrice([storeless, forStore12], 12), forStore12);
        // No entry for store 99 → store-less fallback.
        expect(resolveItemPrice([storeless, forStore12], 99), storeless);
        // Non-store context resolves the store-less price directly.
        expect(resolveItemPrice([storeless, forStore12], null), storeless);
        // Neither exists.
        expect(resolveItemPrice([forStore12], 99), isNull);
      },
    );
  });

  group('ListItem price extension', () {
    test('hasPrice / formattedPrice read the store-less price', () {
      final item = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'USD'),
        price(storeId: 12, priceType: 'set', priceMin: 4, priceCurrency: 'USD'),
      ]);
      expect(item.hasPrice, isTrue);
      expect(item.formattedPrice, r'$5');
    });

    test('store-only item has no store-less price', () {
      final item = priced([
        price(storeId: 12, priceType: 'set', priceMin: 4, priceCurrency: 'USD'),
      ]);
      expect(item.hasPrice, isFalse);
      expect(item.formattedPrice, isNull);
      // But it resolves for that store.
      expect(item.hasPriceFor(12), isTrue);
      expect(item.formattedPriceFor(12), r'$4');
    });

    test('formattedPriceFor falls back to the store-less price', () {
      final item = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'USD'),
      ]);
      expect(item.formattedPriceFor(99), r'$5');
    });
  });

  group('matchesPriceFilter', () {
    test('items with no price never match an active filter', () {
      expect(
        matchesPriceFilter(priced(const []), const PriceFilter(min: 1)),
        isFalse,
      );
    });

    test('a set price is a zero-width range against min/max bounds', () {
      final item = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'USD'),
      ]);
      expect(matchesPriceFilter(item, const PriceFilter(min: 3)), isTrue);
      expect(matchesPriceFilter(item, const PriceFilter(min: 6)), isFalse);
      expect(matchesPriceFilter(item, const PriceFilter(max: 5)), isTrue);
      expect(matchesPriceFilter(item, const PriceFilter(max: 4)), isFalse);
    });

    test('a range price passes when it overlaps the filter bounds', () {
      final item = priced([
        price(
          priceType: 'range',
          priceMin: 5,
          priceMax: 10,
          priceCurrency: 'USD',
        ),
      ]);
      // Overlap on the low end.
      expect(matchesPriceFilter(item, const PriceFilter(max: 6)), isTrue);
      // Overlap on the high end.
      expect(matchesPriceFilter(item, const PriceFilter(min: 9)), isTrue);
      // Entirely below the filter's min.
      expect(matchesPriceFilter(item, const PriceFilter(min: 11)), isFalse);
      // Entirely above the filter's max.
      expect(matchesPriceFilter(item, const PriceFilter(max: 4)), isFalse);
    });

    test('matches when any of the item prices falls in range', () {
      // Store-less price is out of range; a per-store price is in range.
      final item = priced([
        price(priceType: 'set', priceMin: 20, priceCurrency: 'USD'),
        price(storeId: 12, priceType: 'set', priceMin: 4, priceCurrency: 'USD'),
      ]);
      expect(matchesPriceFilter(item, const PriceFilter(max: 5)), isTrue);
    });

    test('a currency filter only matches prices in that currency', () {
      final usd = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'USD'),
      ]);
      final ils = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'ILS'),
      ]);
      expect(
        matchesPriceFilter(usd, const PriceFilter(currency: 'USD')),
        isTrue,
      );
      expect(
        matchesPriceFilter(ils, const PriceFilter(currency: 'USD')),
        isFalse,
      );
      // Case-insensitive on the price's stored code.
      final lower = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'usd'),
      ]);
      expect(
        matchesPriceFilter(lower, const PriceFilter(currency: 'USD')),
        isTrue,
      );
    });

    test('null currency compares amounts verbatim across currencies', () {
      final ils = priced([
        price(priceType: 'set', priceMin: 5, priceCurrency: 'ILS'),
      ]);
      expect(matchesPriceFilter(ils, const PriceFilter(min: 3)), isTrue);
    });

    test('isActive reflects any set bound or currency', () {
      expect(PriceFilter.empty.isActive, isFalse);
      expect(const PriceFilter(min: 1).isActive, isTrue);
      expect(const PriceFilter(currency: 'USD').isActive, isTrue);
    });
  });
}
