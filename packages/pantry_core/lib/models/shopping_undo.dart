import 'package:pantry_core/models/shopping_session.dart';

enum ShoppingUndoSkipReason {
  /// Unchecked, checked again, reopened, archived or trashed since the trip.
  changed,

  /// Deleted for good since the trip.
  gone,
}

/// An item an undo left alone because it moved on after the trip.
class ShoppingUndoSkip {
  final int itemId;

  /// From the trip's own record of the item; null on trips too old to have
  /// kept one.
  final String? itemName;
  final ShoppingUndoSkipReason reason;

  const ShoppingUndoSkip({
    required this.itemId,
    required this.itemName,
    required this.reason,
  });

  factory ShoppingUndoSkip.fromJson(Map<String, dynamic> json) =>
      ShoppingUndoSkip(
        itemId: json['itemId'] as int,
        itemName: json['itemName'] as String?,
        reason: json['reason'] == 'gone'
            ? ShoppingUndoSkipReason.gone
            : ShoppingUndoSkipReason.changed,
      );
}

/// What undoing a finished trip did: the items it put back, and the ones it
/// left as they were.
class ShoppingUndoResult {
  final ShoppingSession session;
  final List<int> reverted;
  final List<ShoppingUndoSkip> skipped;

  const ShoppingUndoResult({
    required this.session,
    required this.reverted,
    required this.skipped,
  });

  factory ShoppingUndoResult.fromJson(Map<String, dynamic> json) =>
      ShoppingUndoResult(
        session: ShoppingSession.fromJson(
          json['session'] as Map<String, dynamic>,
        ),
        reverted: ((json['reverted'] as List?) ?? const []).cast<int>(),
        skipped: ((json['skipped'] as List?) ?? const [])
            .map((e) => ShoppingUndoSkip.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
