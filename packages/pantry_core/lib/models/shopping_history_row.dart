import 'package:pantry_core/models/shopping_estimate.dart';

/// A closed trip in the history list. [stores] are store names in visit order
/// ("Store A → Store B"); [grandTotal] is a per-currency realized amount
/// (billed where entered, else estimated). Scope (mine vs house) is applied
/// server-side per each session's `isPrivate`.
class ShoppingHistoryRow {
  final int id;
  final String userId;

  /// Everyone who shopped the trip: the shopper who started it, then the
  /// housemates who joined. A server that sends no member list leaves [userId]
  /// alone standing in.
  final List<String> memberIds;
  final int createdAt;
  final int? closedAt;

  /// Set when the trip was cancelled, which leaves it with no items and no
  /// total.
  final int? abortedAt;

  /// Set when a finished trip was undone: its items keep showing, but its
  /// total no longer counts.
  final int? undoneAt;
  final List<String> stores;
  final int itemCount;
  final List<CurrencyAmount> grandTotal;

  const ShoppingHistoryRow({
    required this.id,
    required this.userId,
    this.memberIds = const [],
    required this.createdAt,
    required this.closedAt,
    this.abortedAt,
    this.undoneAt,
    required this.stores,
    required this.itemCount,
    required this.grandTotal,
  });

  factory ShoppingHistoryRow.fromJson(Map<String, dynamic> json) =>
      ShoppingHistoryRow(
        id: json['id'] as int,
        userId: json['userId'] as String,
        memberIds:
            (json['memberIds'] as List?)?.cast<String>() ??
            <String>[json['userId'] as String],
        createdAt: json['createdAt'] as int,
        closedAt: json['closedAt'] as int?,
        abortedAt: json['abortedAt'] as int?,
        undoneAt: json['undoneAt'] as int?,
        stores: ((json['stores'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
        itemCount: json['itemCount'] as int,
        grandTotal: parseCurrencyAmounts(json['grandTotal']),
      );

  bool get isCancelled => abortedAt != null;
  bool get isUndone => undoneAt != null;

  /// Whether [uid] may undo this trip: anyone who shopped a finished trip that
  /// committed something, as long as it hasn't been undone already.
  bool canBeUndoneBy(String? uid) =>
      uid != null &&
      closedAt != null &&
      !isCancelled &&
      !isUndone &&
      itemCount > 0 &&
      memberIds.contains(uid);
}
