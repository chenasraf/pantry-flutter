/// A shopping trip currently under way, derived from live sessions +
/// heartbeat. [activeStoreId] attributes it to a store (null = live but no
/// store chosen). [userId] is the shopper who started it; resolve avatar/name
/// from it. The list is not self-filtered — the caller decides whether to
/// render itself.
///
/// One entry per *trip*, not per shopper: housemates sharing a trip appear
/// together in [memberIds] under the single entry of the shopper who started
/// it.
class ShoppingPresenceEntry {
  final String userId;

  /// The trip itself, so a housemate can join it straight from a presence
  /// read. Null on a server without `shopping-join-session`, which addresses
  /// presence by person alone.
  final int? sessionId;

  final int? activeStoreId;
  final int lastSeenAt;

  /// Everyone shopping this trip, [userId] first.
  final List<String> memberIds;

  const ShoppingPresenceEntry({
    required this.userId,
    this.sessionId,
    required this.activeStoreId,
    required this.lastSeenAt,
    this.memberIds = const [],
  });

  factory ShoppingPresenceEntry.fromJson(Map<String, dynamic> json) =>
      ShoppingPresenceEntry(
        userId: json['userId'] as String,
        sessionId: json['sessionId'] as int?,
        activeStoreId: json['activeStoreId'] as int?,
        lastSeenAt: json['lastSeenAt'] as int,
        memberIds:
            (json['memberIds'] as List?)?.cast<String>() ??
            <String>[json['userId'] as String],
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sessionId': sessionId,
    'activeStoreId': activeStoreId,
    'lastSeenAt': lastSeenAt,
    'memberIds': memberIds,
  };

  /// Whether [uid] is already shopping this trip — as its starter or as a
  /// housemate who joined it.
  bool includes(String? uid) => uid != null && memberIds.contains(uid);
}
