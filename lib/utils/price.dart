import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/currencies.dart';

/// True when the raw price fields carry a usable price (a type and a min
/// amount). Mirrors the web app's `hasPrice`.
bool hasPriceValue(String? priceType, double? priceMin) {
  return (priceType == 'set' || priceType == 'range') && priceMin != null;
}

/// Format an amount using the currency's decimals but trimming trailing zeros,
/// so 1 → "1", 1.5 → "1.5", 9.99 → "9.99" (never "1.00").
String _formatAmount(double amount, int decimals) {
  final rounded = double.parse(amount.toStringAsFixed(decimals));
  if (rounded == rounded.truncateToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded.toString();
}

/// Render a price chip label from raw price fields, e.g. "$1", "$1-10", "1₪",
/// "1-10₪". Returns null when there is no price to show. Mirrors the web app's
/// `formatPrice` in `src/utils/price.ts`.
String? formatPrice({
  required String? priceType,
  required double? priceMin,
  required double? priceMax,
  required String? priceCurrency,
}) {
  if (!hasPriceValue(priceType, priceMin) || priceMin == null) return null;
  final currency = resolveCurrency(priceCurrency);
  final min = _formatAmount(priceMin, currency.decimals);
  final String body;
  if (priceType == 'range' && priceMax != null) {
    final max = _formatAmount(priceMax, currency.decimals);
    body = '$min-$max';
  } else {
    body = min;
  }
  return currency.symbolBefore
      ? '${currency.symbol}$body'
      : '$body${currency.symbol}';
}

/// The item's store-less (default) price, or null when it has none. Mirrors
/// the web app's `storelessPrice`.
ItemPrice? storelessPrice(List<ItemPrice> prices) {
  for (final p in prices) {
    if (p.storeId == null) return p;
  }
  return null;
}

/// The price to show for a given store context: the store's own price when set,
/// otherwise the store-less price. Passing null (non-store views) resolves the
/// store-less price directly. Returns null when neither exists. Mirrors the web
/// app's `resolveItemPrice`.
ItemPrice? resolveItemPrice(List<ItemPrice> prices, int? storeId) {
  if (storeId != null) {
    for (final p in prices) {
      if (p.storeId == storeId) return p;
    }
  }
  return storelessPrice(prices);
}

extension ItemPriceX on ItemPrice {
  /// Whether this entry carries a usable price.
  bool get hasValue => hasPriceValue(priceType, priceMin);

  /// Formatted price label for this entry, or null when it has no price.
  String? get formatted => formatPrice(
    priceType: priceType,
    priceMin: priceMin,
    priceMax: priceMax,
    priceCurrency: priceCurrency,
  );
}

extension ListItemPrice on ListItem {
  /// Whether this item's store-less (default) price is usable.
  bool get hasPrice => storelessPrice(prices)?.hasValue ?? false;

  /// Store-less (default) price label, or null when there is none.
  String? get formattedPrice => storelessPrice(prices)?.formatted;

  /// Whether the item has a usable price in [storeId]'s context (the store's
  /// own price, else the store-less fallback).
  bool hasPriceFor(int? storeId) =>
      resolveItemPrice(prices, storeId)?.hasValue ?? false;

  /// Price label resolved for [storeId] (store price, else store-less), or null
  /// when neither exists.
  String? formattedPriceFor(int? storeId) =>
      resolveItemPrice(prices, storeId)?.formatted;
}

/// An active price-range filter. [currency] `null` means "any currency" —
/// amounts compare verbatim across all currencies (no conversion). Mirrors the
/// web app's `PriceFilterValue`.
class PriceFilter {
  final double? min;
  final double? max;
  final String? currency;

  const PriceFilter({this.min, this.max, this.currency});

  static const empty = PriceFilter();

  bool get isActive => min != null || max != null || currency != null;

  PriceFilter copyWith({
    double? min,
    double? max,
    String? currency,
    bool clearMin = false,
    bool clearMax = false,
    bool clearCurrency = false,
  }) => PriceFilter(
    min: clearMin ? null : (min ?? this.min),
    max: clearMax ? null : (max ?? this.max),
    currency: clearCurrency ? null : (currency ?? this.currency),
  );
}

/// Whether [item] passes [filter]. An item passes when **any** of its prices
/// overlaps `[min, max]`; a `set` price is treated as a zero-width range. When a
/// currency is chosen, only prices in that currency are considered. Items with
/// no price never match an active filter. Mirrors the web app's
/// `matchesPriceFilter`.
bool matchesPriceFilter(ListItem item, PriceFilter filter) {
  for (final price in item.prices) {
    if (_priceEntryMatches(price, filter)) return true;
  }
  return false;
}

bool _priceEntryMatches(ItemPrice price, PriceFilter filter) {
  if (!price.hasValue) return false;
  if (filter.currency != null &&
      (price.priceCurrency ?? '').toUpperCase() != filter.currency) {
    return false;
  }
  final lo = price.priceMin!;
  final hi = price.priceType == 'range' && price.priceMax != null
      ? price.priceMax!
      : lo;
  if (filter.min != null && hi < filter.min!) return false;
  if (filter.max != null && lo > filter.max!) return false;
  return true;
}
