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

extension ListItemPrice on ListItem {
  /// Whether this item carries a usable price.
  bool get hasPrice => hasPriceValue(priceType, priceMin);

  /// Formatted price label for this item, or null when it has no price.
  String? get formattedPrice => formatPrice(
    priceType: priceType,
    priceMin: priceMin,
    priceMax: priceMax,
    priceCurrency: priceCurrency,
  );
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

/// Whether [item] passes [filter]. An item passes when its price overlaps
/// `[min, max]`; a `set` price is treated as a zero-width range. When a
/// currency is chosen, only items in that currency match. Items with no price
/// never match an active filter. Mirrors the web app's `matchesPriceFilter`.
bool matchesPriceFilter(ListItem item, PriceFilter filter) {
  if (!item.hasPrice) return false;
  if (filter.currency != null &&
      (item.priceCurrency ?? '').toUpperCase() != filter.currency) {
    return false;
  }
  final lo = item.priceMin!;
  final hi = item.priceType == 'range' && item.priceMax != null
      ? item.priceMax!
      : lo;
  if (filter.min != null && hi < filter.min!) return false;
  if (filter.max != null && lo > filter.max!) return false;
  return true;
}
