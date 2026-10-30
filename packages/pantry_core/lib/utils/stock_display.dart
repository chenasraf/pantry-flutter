import '../i18n.dart';
import '../models/checklist.dart';
import '../models/stock.dart';
import 'date_format.dart';
import 'stock_rules.dart';

// How an inventory item's stock reads, shared by every surface that draws one:
// the phone's rows, dialog and detail view, and the watch's.

enum StockTone { success, warning, error, muted }

StockTone stockToneOf(ListItem item) {
  final stock = item.stockStatus ?? StockStatus.ok;
  final expiry = item.expiryStatus ?? ExpiryStatus.none;
  if (stock == StockStatus.out || expiry == ExpiryStatus.expired) {
    return StockTone.error;
  }
  if (stock == StockStatus.low || expiry == ExpiryStatus.expiring) {
    return StockTone.warning;
  }
  return stock == StockStatus.uncounted ? StockTone.muted : StockTone.success;
}

String stockLevelName(StockLevel level) => switch (level) {
  StockLevel.full => m.stock.full,
  StockLevel.low => m.stock.low,
  StockLevel.out => m.stock.out,
};

/// On hand as the stepper reads it: a blank on hand is 0, in the target's
/// wording when the target has a number.
String effectiveOnHand(ListItem item) {
  final onHand = (item.quantity ?? '').trim();
  if (onHand.isNotEmpty) return onHand;
  final target = (item.target ?? '').trim();
  return firstNumber(target) != null ? withNumber(target, 0) : '0';
}

/// The on-hand text with its first number swapped for [value], for a typed or
/// held amount.
String onHandWith(ListItem item, num value) =>
    withNumber(effectiveOnHand(item), value);

enum StockChipKind { stock, expiry, uncounted }

typedef StockChipSpec = ({String label, StockTone? tone, StockChipKind kind});

/// The status chips of an inventory row, most urgent first. A null tone is a
/// neutral chip.
List<StockChipSpec> stockStatusChips(ListItem item, {int? today}) {
  final stock = item.stockStatus ?? StockStatus.ok;
  final expiry = item.expiryStatus ?? ExpiryStatus.none;
  final fields = item.stockFields;
  final out = <StockChipSpec>[];
  if (stock.isShort) {
    final low = stock == StockStatus.low;
    final shortfall = item.shortfall;
    // While expiry asks for the shopping row, it names the amount.
    final label = expiry.isDue || shortfall == null
        ? (low ? m.stock.low : m.stock.out)
        : (low ? m.stock.lowBuy(shortfall) : m.stock.outBuy(shortfall));
    out.add((
      label: label,
      tone: low ? StockTone.warning : StockTone.error,
      kind: StockChipKind.stock,
    ));
  }
  final expiresAt = item.expiresAt;
  if (expiresAt != null && expiry != ExpiryStatus.none) {
    final amount = fullAmount(fields);
    final date = formatShortDate(expiresAt);
    switch (expiry) {
      case ExpiryStatus.expired:
        out.add((
          label: amount == null
              ? m.stock.expiredOn(date)
              : m.stock.expiredOnBuy(date, amount),
          tone: StockTone.error,
          kind: StockChipKind.expiry,
        ));
      case ExpiryStatus.expiring:
        final days = daysUntil(expiresAt, today ?? todayEpoch());
        final label = switch (days) {
          <= 0 =>
            amount == null
                ? m.stock.expiresToday
                : m.stock.expiresTodayBuy(amount),
          1 =>
            amount == null
                ? m.stock.expiresTomorrow
                : m.stock.expiresTomorrowBuy(amount),
          _ =>
            amount == null
                ? m.stock.expiresInDays(days)
                : m.stock.expiresInDaysBuy(days, amount),
        };
        out.add((
          label: label,
          tone: StockTone.warning,
          kind: StockChipKind.expiry,
        ));
      case ExpiryStatus.ok:
        out.add((
          label: m.stock.goodUntil(date),
          tone: null,
          kind: StockChipKind.expiry,
        ));
      case ExpiryStatus.none:
        break;
    }
  }
  if (stock == StockStatus.uncounted) {
    out.add((
      label: m.stock.notCounted,
      tone: null,
      kind: StockChipKind.uncounted,
    ));
  }
  return out;
}

/// The one status chip a row with room for a single one shows: red before
/// amber, and expiry before stock at the same tone. "Good until" is not a
/// status, so it never wins.
StockChipSpec? mostUrgentStockChip(ListItem item, {int? today}) {
  final chips = stockStatusChips(item, today: today);
  StockChipSpec? pick(StockTone tone) {
    StockChipSpec? found;
    for (final chip in chips) {
      if (chip.tone != tone) continue;
      if (chip.kind == StockChipKind.expiry) return chip;
      found ??= chip;
    }
    return found;
  }

  return pick(StockTone.error) ??
      pick(StockTone.warning) ??
      chips.where((c) => c.kind == StockChipKind.uncounted).firstOrNull;
}

/// The row's status spelled out, for the status icon's tooltip and screen
/// readers.
String stockStatusDescription(ListItem item) {
  final chips = stockStatusChips(item);
  return chips.isEmpty ? m.stock.inStock : chips.map((c) => c.label).join(', ');
}

/// "4 / 12 eggs": on hand's number over the target's text.
String stockAmountLabel(ListItem item) {
  final onHand = effectiveOnHand(item);
  final number = firstNumber(onHand);
  final target = (item.target ?? '').trim();
  final shown = number != null ? formatNumber(number) : onHand;
  return target.isEmpty ? shown : m.stock.amount(shown, target);
}

typedef StockStatusLine = ({String text, StockTone? tone});

/// One sentence on where the item's stock stands, the most urgent reason
/// first.
StockStatusLine stockStatusLine(StockFields fields, int leadDays) {
  final c = m.stock.card;
  final stock = evaluateStock(fields);
  final expiry = evaluateExpiry(fields, leadDays, todayEpoch());
  final amount = fullAmount(fields);
  if (expiry == ExpiryStatus.expired) {
    return (
      text: amount == null ? c.statusExpired : c.statusExpiredBuy(amount),
      tone: StockTone.error,
    );
  }
  if (stock.status == StockStatus.out) {
    final s = stock.shortfall;
    return (
      text: s == null ? c.statusOut : c.statusOutBuy(s),
      tone: StockTone.error,
    );
  }
  if (expiry == ExpiryStatus.expiring) {
    return (
      text: amount == null ? c.statusExpiring : c.statusExpiringBuy(amount),
      tone: StockTone.warning,
    );
  }
  if (stock.status == StockStatus.low) {
    final s = stock.shortfall;
    return (
      text: s == null ? c.statusLow : c.statusLowBuy(s),
      tone: StockTone.warning,
    );
  }
  if (stock.status == StockStatus.uncounted) {
    return (
      text: firstNumber(fields.target) == null
          ? c.statusUncountedTarget
          : c.statusUncountedOnHand,
      tone: null,
    );
  }
  return (text: c.statusInStock, tone: null);
}

/// "Good until Oct 31. Each restock renews it to 7 days from that day.", or
/// null when the item has neither a date nor a shelf life.
String? expirySummary(ListItem item) {
  final expiresAt = item.expiresAt;
  final shelfLife = item.shelfLifeDays;
  if (expiresAt != null) {
    final date = formatShortDate(expiresAt);
    final head = daysUntil(expiresAt, todayEpoch()) < 0
        ? m.stock.expiry.expiredSummary(date)
        : m.stock.expiry.goodUntilSummary(date);
    return shelfLife == null
        ? head
        : '$head ${m.stock.expiry.renews(shelfLife)}';
  }
  if (shelfLife != null) return m.stock.expiry.chipKeeps(shelfLife);
  return null;
}

/// How an inventory item reaches a shopping list.
enum StockLinkStatus {
  linked,

  /// Several same-name checklist items match and none is linked.
  needsPick,

  /// Unlinked, and finds or adds one by name when it needs restock.
  autoOn,

  /// Unlinked, and never reaches a shopping list on its own.
  autoOff,
}

StockLinkStatus stockLinkStatusOf(ListItem item) {
  if (item.stockLink != null) return StockLinkStatus.linked;
  if (item.linkCandidates.isNotEmpty) return StockLinkStatus.needsPick;
  return (item.autoLink ?? true)
      ? StockLinkStatus.autoOn
      : StockLinkStatus.autoOff;
}

String stockLinkTooltip(ListItem item) {
  final l = m.stock.links;
  return switch (stockLinkStatusOf(item)) {
    StockLinkStatus.linked => l.tooltipLinked(
      item.stockLink!.name,
      item.stockLink!.listName,
    ),
    StockLinkStatus.needsPick => l.tooltipNeedsPick(item.linkCandidates.length),
    StockLinkStatus.autoOn => l.tooltipAutoOn,
    StockLinkStatus.autoOff => l.tooltipAutoOff,
  };
}
