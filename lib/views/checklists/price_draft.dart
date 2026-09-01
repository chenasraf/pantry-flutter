import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/price.dart';

/// Format a stored amount for seeding an input field: trim trailing zeros so a
/// round number shows as "1" (not "1.00") and "9.99" stays "9.99".
String _seedAmount(double amount) {
  if (amount == amount.truncateToDouble()) return amount.toInt().toString();
  return amount.toString();
}

double? _parseAmount(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Mutable draft backing the [PriceInput] widget. The Set/Range selection is
/// kept as local UI state ([isRange]) rather than derived from the amounts, so
/// switching to Range with an empty field doesn't snap back to Set.
class PriceDraft {
  bool isRange;
  String minText;
  String maxText;
  String currency;

  PriceDraft({
    this.isRange = false,
    this.minText = '',
    this.maxText = '',
    this.currency = defaultCurrency,
  });

  /// Seed from a single [ItemPrice] entry (or null for an empty row), falling
  /// back to [fallbackCurrency] (the house's last-used currency) when the entry
  /// carries no currency.
  factory PriceDraft.fromItemPrice(
    ItemPrice? price, {
    required String fallbackCurrency,
  }) {
    final type = price?.priceType;
    final hasPrice =
        (type == 'set' || type == 'range') && price?.priceMin != null;
    return PriceDraft(
      isRange: type == 'range',
      minText: hasPrice ? _seedAmount(price!.priceMin!) : '',
      maxText: type == 'range' && price?.priceMax != null
          ? _seedAmount(price!.priceMax!)
          : '',
      currency: price?.priceCurrency ?? fallbackCurrency,
    );
  }

  double? get _min => _parseAmount(minText);
  double? get _max => _parseAmount(maxText);

  /// Whether the draft carries a usable price (a parseable min amount).
  bool get hasPrice => _min != null;

  /// priceType this draft represents, or null when there's no price.
  String? get priceType => hasPrice ? (isRange ? 'range' : 'set') : null;

  double? get priceMin => hasPrice ? _min : null;
  double? get priceMax => hasPrice && isRange ? _max : null;
  String? get priceCurrency => hasPrice ? currency : null;

  /// Compose this draft into an [ItemPrice] for [storeId], or null when the
  /// draft carries no usable amount.
  ItemPrice? toItemPrice(int? storeId) {
    if (!hasPrice) return null;
    return ItemPrice(
      storeId: storeId,
      priceType: priceType,
      priceMin: priceMin,
      priceMax: priceMax,
      priceCurrency: priceCurrency,
    );
  }
}

/// One per-store price row within a [PricesDraft]. [key] is a stable identity so
/// the row's [PriceInput] keeps its text controllers as rows are added/removed.
class StorePriceRow {
  static int _nextKey = 0;

  final int key;
  int storeId;
  final PriceDraft draft;

  StorePriceRow({required this.storeId, required this.draft})
    : key = _nextKey++;
}

/// Mutable draft for an item's full set of prices: a store-less (default) price
/// plus zero or more per-store rows. Mirrors the web app's `ItemPricesEditor`
/// model. Compose into the wire shape with [toItemPrices].
class PricesDraft {
  final PriceDraft storeless;
  final List<StorePriceRow> rows;
  final String defaultCurrency;

  PricesDraft({
    required this.storeless,
    required this.rows,
    required this.defaultCurrency,
  });

  factory PricesDraft.empty(String currency) => PricesDraft(
    storeless: PriceDraft(currency: currency),
    rows: [],
    defaultCurrency: currency,
  );

  /// Seed from an existing item, falling back to [fallbackCurrency] where an
  /// entry carries no currency.
  factory PricesDraft.fromItem(
    ListItem item, {
    required String fallbackCurrency,
  }) {
    final rows = [
      for (final p in item.prices)
        if (p.storeId != null)
          StorePriceRow(
            storeId: p.storeId!,
            draft: PriceDraft.fromItemPrice(
              p,
              fallbackCurrency: fallbackCurrency,
            ),
          ),
    ];
    return PricesDraft(
      storeless: PriceDraft.fromItemPrice(
        storelessPrice(item.prices),
        fallbackCurrency: fallbackCurrency,
      ),
      rows: rows,
      defaultCurrency: fallbackCurrency,
    );
  }

  /// Whether any price (store-less or per-store) carries a usable amount.
  bool get hasAnyPrice =>
      storeless.hasPrice || rows.any((r) => r.draft.hasPrice);

  /// Currency worth remembering for the next new item: the store-less price's
  /// currency when set, else the first priced row's, else null.
  String? get rememberCurrency {
    if (storeless.hasPrice) return storeless.currency;
    for (final r in rows) {
      if (r.draft.hasPrice) return r.draft.currency;
    }
    return null;
  }

  /// Compose into the wire list, dropping rows without a usable amount. Safe to
  /// send as the `prices` param on create/update (empty clears all prices).
  List<ItemPrice> toItemPrices() {
    final out = <ItemPrice>[];
    final s = storeless.toItemPrice(null);
    if (s != null) out.add(s);
    for (final r in rows) {
      final p = r.draft.toItemPrice(r.storeId);
      if (p != null) out.add(p);
    }
    return out;
  }
}
