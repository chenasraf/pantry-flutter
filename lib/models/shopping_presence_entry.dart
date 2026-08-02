/// A housemate currently out shopping, derived from live sessions + heartbeat.
/// [activeStoreId] attributes them to a store (null = live but no store
/// chosen). Resolve avatar/name from [userId]. The list is not self-filtered —
/// the caller decides whether to render itself.
class ShoppingPresenceEntry {
  final String userId;
  final int? activeStoreId;
  final int lastSeenAt;

  const ShoppingPresenceEntry({
    required this.userId,
    required this.activeStoreId,
    required this.lastSeenAt,
  });

  factory ShoppingPresenceEntry.fromJson(Map<String, dynamic> json) =>
      ShoppingPresenceEntry(
        userId: json['userId'] as String,
        activeStoreId: json['activeStoreId'] as int?,
        lastSeenAt: json['lastSeenAt'] as int,
      );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'activeStoreId': activeStoreId,
    'lastSeenAt': lastSeenAt,
  };
}
