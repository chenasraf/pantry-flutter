import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_estimate.dart';

/// One store's slice of a shopping review: the checked items bought there, the
/// per-currency [estimate] of their prices, how many carried no price, and the
/// user-entered [billedTotal]/[billedCurrency] actuals (null until entered).
/// [storeId] is null for the storeless / unassigned bucket ("Any store").
class ShoppingReviewStore {
  final int? storeId;
  final List<ListItem> items;
  final ShoppingEstimate estimate;
  final int noPriceCount;
  final double? billedTotal;
  final String? billedCurrency;

  const ShoppingReviewStore({
    required this.storeId,
    required this.items,
    required this.estimate,
    required this.noPriceCount,
    this.billedTotal,
    this.billedCurrency,
  });

  /// The same slice reading [total] / [currency] instead of what the server
  /// said — how a figure still waiting in the sync queue is drawn over the
  /// snapshot it predates. Both are required because null is a value here: an
  /// emptied field queues a write that clears the total.
  ShoppingReviewStore withBilled({
    required double? total,
    required String? currency,
  }) => ShoppingReviewStore(
    storeId: storeId,
    items: items,
    estimate: estimate,
    noPriceCount: noPriceCount,
    billedTotal: total,
    billedCurrency: currency,
  );

  factory ShoppingReviewStore.fromJson(Map<String, dynamic> json) =>
      ShoppingReviewStore(
        storeId: json['storeId'] as int?,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        estimate: parseShoppingEstimate(json['estimate']),
        noPriceCount: json['noPriceCount'] as int,
        billedTotal: (json['billedTotal'] as num?)?.toDouble(),
        billedCurrency: json['billedCurrency'] as String?,
      );
}

/// The checked log of a trip, grouped by store and server-computed. Rendered
/// per-store on advance (just the active store), or in full on close/history.
class ShoppingReview {
  final List<ShoppingReviewStore> stores;
  final ShoppingEstimate grandTotal;
  final int uncheckedCount;

  const ShoppingReview({
    required this.stores,
    required this.grandTotal,
    required this.uncheckedCount,
  });

  factory ShoppingReview.fromJson(Map<String, dynamic> json) => ShoppingReview(
    stores: ((json['stores'] as List?) ?? const [])
        .map((e) => ShoppingReviewStore.fromJson(e as Map<String, dynamic>))
        .toList(),
    grandTotal: parseShoppingEstimate(json['grandTotal']),
    uncheckedCount: json['uncheckedCount'] as int,
  );
}

/// My check-log rows whose `checkedAt` falls within today (my timezone),
/// house-scoped. Surfaced in the dense view's "Done today" drawer. Distinct
/// from an item's own `doneAt` — strictly shopping-mode checks.
class ShoppingDoneToday {
  final List<ListItem> items;
  final ShoppingEstimate estimate;
  final int noPriceCount;
  final int count;

  const ShoppingDoneToday({
    required this.items,
    required this.estimate,
    required this.noPriceCount,
    required this.count,
  });

  factory ShoppingDoneToday.fromJson(Map<String, dynamic> json) =>
      ShoppingDoneToday(
        items: ((json['items'] as List?) ?? const [])
            .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        estimate: parseShoppingEstimate(json['estimate']),
        noPriceCount: json['noPriceCount'] as int,
        count: json['count'] as int,
      );
}
