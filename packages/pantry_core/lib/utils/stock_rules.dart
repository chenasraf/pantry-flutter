import '../models/checklist.dart';
import '../models/stock.dart';

// The server's StockRules.php and the web's src/utils/stock.ts hold the same
// rules. All three are pinned by the server's tests/stock-vectors.json (copied
// to test/fixtures), so a change to one is a change to all three.

final _firstNumber = RegExp(r'\d+(?:\.\d+)?');

/// The stock fields the rules read off an item.
class StockFields {
  const StockFields({
    this.stockMode,
    this.stockLevel,
    this.quantity,
    this.target,
    this.reorderPoint,
    this.expiresAt,
    this.shelfLifeDays,
  });

  /// Null counts, as a missing mode does on the server.
  final StockMode? stockMode;
  final StockLevel? stockLevel;
  final String? quantity;
  final String? target;
  final String? reorderPoint;

  /// Midnight, in epoch seconds, of the last day the item is good.
  final int? expiresAt;
  final int? shelfLifeDays;

  bool get isLevel => stockMode == StockMode.level;
}

typedef StockResult = ({StockStatus status, String? shortfall});

typedef StockConversion = ({
  StockMode stockMode,
  StockLevel? stockLevel,
  String? quantity,
  String? target,
});

/// The first number in [text]; units and any other words are ignored, and
/// there is no sign ("-3" is 3).
double? firstNumber(String? text) {
  if (text == null) return null;
  final match = _firstNumber.firstMatch(text);
  return match == null ? null : double.parse(match.group(0)!);
}

/// Rounded to six places, so subtracting decimals never shows float noise
/// ("1.2" − "1.1" is "0.1").
String formatNumber(num value) {
  final rounded = (value * 1e6).round() / 1e6;
  if (rounded == rounded.truncateToDouble()) return rounded.toInt().toString();
  var text = rounded.toStringAsFixed(6);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
}

/// [text] with its first number swapped for [value]; text without a number is
/// returned as it is.
String withNumber(String text, num value) {
  final match = _firstNumber.firstMatch(text);
  if (match == null) return text;
  return text.replaceRange(match.start, match.end, formatNumber(value));
}

String? _blankToNull(String? text) {
  final trimmed = (text ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

StockResult evaluateStock(StockFields item) {
  if (item.isLevel) {
    final level = item.stockLevel;
    if (level != StockLevel.low && level != StockLevel.out) {
      return (status: StockStatus.ok, shortfall: null);
    }
    return (
      status: level == StockLevel.out ? StockStatus.out : StockStatus.low,
      shortfall: _blankToNull(item.quantity),
    );
  }
  final onHandText = (item.quantity ?? '').trim();
  final onHand = onHandText.isEmpty ? 0.0 : firstNumber(onHandText);
  final target = firstNumber(item.target);
  if (onHand == null || target == null) {
    return (status: StockStatus.uncounted, shortfall: null);
  }
  final reorder = firstNumber(item.reorderPoint);
  final low = reorder != null ? onHand <= reorder : onHand < target;
  if (!low) return (status: StockStatus.ok, shortfall: null);
  final missing = target - onHand;
  return (
    status: onHand == 0 ? StockStatus.out : StockStatus.low,
    shortfall: missing > 0
        ? withNumber((item.target ?? '').trim(), missing)
        : null,
  );
}

/// A count item's on hand when it is added: full (the target) unless an amount
/// was given.
String? startingOnHand(String? quantity, String? target) {
  if ((quantity ?? '').trim().isNotEmpty || firstNumber(target) == null) {
    return quantity;
  }
  return target!.trim();
}

/// What replaces an item from empty: a count item's target, a level item's
/// restock amount.
String? fullAmount(StockFields item) =>
    _blankToNull(item.isLevel ? item.quantity : item.target);

/// The values a switch of stock mode rewrites (ADR 0012 §6). Level to count
/// returns a null on hand when the member has to fill it in.
StockConversion convertStock(StockFields item, StockMode toMode) {
  final fromMode = item.isLevel ? StockMode.level : StockMode.count;
  if (toMode == fromMode) {
    return (
      stockMode: fromMode,
      stockLevel: item.stockLevel,
      quantity: item.quantity,
      target: item.target,
    );
  }
  if (toMode == StockMode.level) {
    final result = evaluateStock(item);
    final level = switch (result.status) {
      StockStatus.low => StockLevel.low,
      StockStatus.out => StockLevel.out,
      _ => StockLevel.full,
    };
    return (
      stockMode: StockMode.level,
      stockLevel: level,
      quantity: level != StockLevel.full && result.shortfall != null
          ? result.shortfall
          : _blankToNull(item.target),
      target: item.target,
    );
  }
  final target = _blankToNull(item.quantity) ?? _blankToNull(item.target);
  final targetText = target ?? '';
  final targetHasNumber = firstNumber(targetText) != null;
  final reorder = firstNumber(item.reorderPoint);
  final onHand = switch (item.stockLevel ?? StockLevel.full) {
    StockLevel.out => targetHasNumber ? withNumber(targetText, 0) : '0',
    StockLevel.low =>
      reorder == null
          ? null
          : targetHasNumber
          ? withNumber(targetText, reorder)
          : formatNumber(reorder),
    StockLevel.full => target,
  };
  return (
    stockMode: StockMode.count,
    stockLevel: item.stockLevel,
    quantity: onHand,
    target: target,
  );
}

const int defaultExpiryLeadDays = 2;

/// Midnight of today in epoch seconds, the way date fields resolve "today".
int todayEpoch([DateTime? now]) {
  final day = now ?? DateTime.now();
  return DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 1000;
}

/// The midnight [days] days after the midnight [day].
int addDays(int day, int days) {
  final date = DateTime.fromMillisecondsSinceEpoch(day * 1000);
  return DateTime(
        date.year,
        date.month,
        date.day + days,
      ).millisecondsSinceEpoch ~/
      1000;
}

/// Whole days between two midnights; rounded, so a daylight-saving shift still
/// lands on its day.
int daysUntil(int date, int today) => ((date - today) / 86400).round();

/// Nothing on hand: a count item at 0 (or blank), a level item that is Out.
bool isStockEmpty(StockFields item) {
  if (item.isLevel) return item.stockLevel == StockLevel.out;
  final onHand = (item.quantity ?? '').trim();
  return onHand.isEmpty || firstNumber(onHand) == 0;
}

ExpiryStatus evaluateExpiry(StockFields item, int leadDays, int today) {
  final expiresAt = item.expiresAt;
  if (expiresAt == null || isStockEmpty(item)) return ExpiryStatus.none;
  final daysLeft = daysUntil(expiresAt, today);
  if (daysLeft < 0) return ExpiryStatus.expired;
  final shelfLife = item.shelfLifeDays;
  if (daysLeft <= (leadDays < 0 ? 0 : leadDays) &&
      (shelfLife == null || daysLeft < shelfLife)) {
    return ExpiryStatus.expiring;
  }
  return ExpiryStatus.ok;
}

/// The expiry date of stock bought today: today + its shelf life, or none
/// without one.
int? renewedExpiry(int? shelfLifeDays, int today) =>
    shelfLifeDays != null ? addDays(today, shelfLifeDays) : null;

bool needsRestock(StockStatus? stock, ExpiryStatus? expiry) =>
    (stock?.isShort ?? false) || (expiry?.isDue ?? false);

/// Fraction of the gauge to fill, or null when the item has no gauge.
double? gaugeFill(StockFields item, StockStatus status) {
  if (item.isLevel) {
    return switch (item.stockLevel) {
      StockLevel.out => 0,
      StockLevel.low => 1 / 3,
      _ => 1,
    };
  }
  if (status == StockStatus.uncounted) return null;
  final onHand = firstNumber(item.quantity) ?? 0;
  final target = firstNumber(item.target) ?? 0;
  if (target <= 0) return 1;
  return onHand / target > 1 ? 1 : onHand / target;
}

/// Where the reorder point sits on a count item's gauge.
double? gaugeTick(StockFields item) {
  if (item.isLevel) return null;
  final reorder = firstNumber(item.reorderPoint);
  final target = firstNumber(item.target);
  if (reorder == null || target == null || target <= 0) return null;
  return reorder / target > 1 ? 1 : reorder / target;
}

extension ListItemStock on ListItem {
  StockFields get stockFields => StockFields(
    stockMode: stockMode,
    stockLevel: stockLevel,
    quantity: quantity,
    target: target,
    reorderPoint: reorderPoint,
    expiresAt: expiresAt,
    shelfLifeDays: shelfLifeDays,
  );

  bool get needsStockRestock => needsRestock(stockStatus, expiryStatus);

  /// This item with its status fields recomputed from its stored values, as
  /// the server would answer them.
  ListItem withLocalStock({required int leadDays, int? today}) {
    final fields = stockFields;
    final stock = evaluateStock(fields);
    return copyWith(
      stockStatus: stock.status,
      shortfall: stock.shortfall,
      clearShortfall: stock.shortfall == null,
      expiryStatus: evaluateExpiry(fields, leadDays, today ?? todayEpoch()),
    );
  }
}
