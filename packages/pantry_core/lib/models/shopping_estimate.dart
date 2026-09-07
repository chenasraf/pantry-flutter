import 'package:pantry_core/utils/currencies.dart';

/// A single per-currency estimate range within a [ShoppingEstimate]. `min`
/// equals `max` when the underlying items all carry a `set` price; otherwise
/// it spans the summed range of the `range`-priced items. Amounts are in the
/// currency's own units (no conversion happens across currencies).
class CurrencyRange {
  final String currency;
  final double min;
  final double max;

  const CurrencyRange({
    required this.currency,
    required this.min,
    required this.max,
  });

  factory CurrencyRange.fromJson(Map<String, dynamic> json) => CurrencyRange(
    currency: json['currency'] as String,
    min: (json['min'] as num).toDouble(),
    max: (json['max'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'min': min,
    'max': max,
  };

  /// Renders this range as a chip/label, e.g. `$12.50` when `min == max` or
  /// `≈$12.50–$18` otherwise. Trailing zeros are trimmed per the currency's
  /// decimals, matching [formatPrice].
  String get label {
    final c = resolveCurrency(currency);
    String amount(double v) {
      final rounded = double.parse(v.toStringAsFixed(c.decimals));
      final body = rounded == rounded.truncateToDouble()
          ? rounded.toInt().toString()
          : rounded.toString();
      return c.symbolBefore ? '${c.symbol}$body' : '$body${c.symbol}';
    }

    if (min == max) return amount(min);
    return '≈${amount(min)}–${amount(max)}';
  }
}

/// A per-currency array of ranges. Used everywhere a total is estimated from
/// item prices — session/store review, done-today and (as a distinct amount
/// shape) history. See [CurrencyRange].
typedef ShoppingEstimate = List<CurrencyRange>;

/// Parse a raw `ShoppingEstimate` payload (a JSON array) into typed ranges.
ShoppingEstimate parseShoppingEstimate(dynamic raw) =>
    ((raw as List?) ?? const [])
        .map((e) => CurrencyRange.fromJson(e as Map<String, dynamic>))
        .toList();

/// Render a whole estimate as one label, each currency on `sep` (e.g. `$12 · 40₪`).
/// Returns null when the estimate is empty (nothing priced).
String? formatShoppingEstimate(
  ShoppingEstimate estimate, {
  String sep = ' · ',
}) {
  if (estimate.isEmpty) return null;
  return estimate.map((r) => r.label).join(sep);
}

/// Render a list of realized amounts (history grand totals) as one label.
/// Returns null when empty.
String? formatCurrencyAmounts(
  List<CurrencyAmount> amounts, {
  String sep = ' · ',
}) {
  if (amounts.isEmpty) return null;
  return amounts.map((a) => a.label).join(sep);
}

/// A single realized per-currency amount, as returned by history rows'
/// `grandTotal` (a summed billed/estimated figure, not a range).
class CurrencyAmount {
  final String currency;
  final double amount;

  const CurrencyAmount({required this.currency, required this.amount});

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) => CurrencyAmount(
    currency: json['currency'] as String,
    amount: (json['amount'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'currency': currency, 'amount': amount};

  /// Renders this amount as a label, e.g. `$12.50`, trimming trailing zeros.
  String get label {
    final c = resolveCurrency(currency);
    final rounded = double.parse(amount.toStringAsFixed(c.decimals));
    final body = rounded == rounded.truncateToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    return c.symbolBefore ? '${c.symbol}$body' : '$body${c.symbol}';
  }
}

List<CurrencyAmount> parseCurrencyAmounts(dynamic raw) =>
    ((raw as List?) ?? const [])
        .map((e) => CurrencyAmount.fromJson(e as Map<String, dynamic>))
        .toList();
