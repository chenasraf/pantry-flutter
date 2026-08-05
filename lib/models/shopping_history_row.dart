import 'package:pantry/models/shopping_estimate.dart';

/// A closed trip in the history list. [stores] are store names in visit order
/// ("Store A → Store B"); [grandTotal] is a per-currency realized amount
/// (billed where entered, else estimated). Scope (mine vs house) is applied
/// server-side per each session's `isPrivate`.
class ShoppingHistoryRow {
  final int id;
  final String userId;
  final int createdAt;
  final int? closedAt;
  final List<String> stores;
  final int itemCount;
  final List<CurrencyAmount> grandTotal;

  const ShoppingHistoryRow({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.closedAt,
    required this.stores,
    required this.itemCount,
    required this.grandTotal,
  });

  factory ShoppingHistoryRow.fromJson(Map<String, dynamic> json) =>
      ShoppingHistoryRow(
        id: json['id'] as int,
        userId: json['userId'] as String,
        createdAt: json['createdAt'] as int,
        closedAt: json['closedAt'] as int?,
        stores: ((json['stores'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        itemCount: json['itemCount'] as int,
        grandTotal: parseCurrencyAmounts(json['grandTotal']),
      );
}
