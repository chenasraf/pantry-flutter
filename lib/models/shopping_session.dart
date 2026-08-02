/// One store leg of a shopping session, ordered by [position]. [billedTotal] /
/// [billedCurrency] are the user-entered actual paid at that store's till
/// (null until entered); they take precedence over the estimate in the grand
/// total. See [ShoppingSession].
class ShoppingSessionStore {
  final int storeId;
  final int position;
  final double? billedTotal;
  final String? billedCurrency;

  const ShoppingSessionStore({
    required this.storeId,
    required this.position,
    this.billedTotal,
    this.billedCurrency,
  });

  factory ShoppingSessionStore.fromJson(Map<String, dynamic> json) =>
      ShoppingSessionStore(
        storeId: json['storeId'] as int,
        position: json['position'] as int,
        billedTotal: (json['billedTotal'] as num?)?.toDouble(),
        billedCurrency: json['billedCurrency'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'position': position,
    'billedTotal': billedTotal,
    'billedCurrency': billedCurrency,
  };
}

/// The lean session DTO — scope + lifecycle only, never item arrays. Returned
/// by create / advance / close / privacy / current. Fetch the two item
/// collections separately: `…/items` (what to buy now) and `…/review` (what
/// was bought).
class ShoppingSession {
  final int id;
  final int houseId;
  final String userId;
  final List<int> listIds;

  /// Ordered by [ShoppingSessionStore.position]. Empty for a storeless trip.
  final List<ShoppingSessionStore> stores;

  /// The store the shopper is currently at — a `storeId` present in [stores],
  /// or null when no store is chosen (storeless trip, or not yet advanced).
  /// The narrowing key for `…/items` and the presence attribution key.
  final int? activeStoreId;

  final bool includeUnassigned;
  final bool isPrivate;

  /// Storeless-session grand-total fallback (actual paid), null until entered.
  final double? billedTotal;
  final String? billedCurrency;

  final int lastSeenAt;

  /// Server-derived: `closedAt == null && fresh`.
  final bool live;
  final int? closedAt;
  final int createdAt;
  final int updatedAt;

  const ShoppingSession({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.listIds,
    required this.stores,
    required this.activeStoreId,
    required this.includeUnassigned,
    required this.isPrivate,
    this.billedTotal,
    this.billedCurrency,
    required this.lastSeenAt,
    required this.live,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShoppingSession.fromJson(Map<String, dynamic> json) =>
      ShoppingSession(
        id: json['id'] as int,
        houseId: json['houseId'] as int,
        userId: json['userId'] as String,
        listIds: ((json['listIds'] as List?) ?? const [])
            .map((e) => e as int)
            .toList(),
        stores: ((json['stores'] as List?) ?? const [])
            .map(
              (e) => ShoppingSessionStore.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        activeStoreId: json['activeStoreId'] as int?,
        includeUnassigned: json['includeUnassigned'] as bool,
        isPrivate: json['isPrivate'] as bool,
        billedTotal: (json['billedTotal'] as num?)?.toDouble(),
        billedCurrency: json['billedCurrency'] as String?,
        lastSeenAt: json['lastSeenAt'] as int,
        live: json['live'] as bool,
        closedAt: json['closedAt'] as int?,
        createdAt: json['createdAt'] as int,
        updatedAt: json['updatedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'userId': userId,
    'listIds': listIds,
    'stores': stores.map((e) => e.toJson()).toList(),
    'activeStoreId': activeStoreId,
    'includeUnassigned': includeUnassigned,
    'isPrivate': isPrivate,
    'billedTotal': billedTotal,
    'billedCurrency': billedCurrency,
    'lastSeenAt': lastSeenAt,
    'live': live,
    'closedAt': closedAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// Store ids in position order. `activeStoreId`'s "next store" is computed
  /// from this sequence client-side.
  List<int> get orderedStoreIds {
    final sorted = [...stores]
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.map((s) => s.storeId).toList();
  }

  /// The store leg after [activeStoreId] in position order, or null when the
  /// active store is the last one (or there is no active store). Backs the
  /// "Next store" affordance.
  int? get nextStoreId {
    final ordered = orderedStoreIds;
    if (activeStoreId == null) return ordered.isEmpty ? null : ordered.first;
    final idx = ordered.indexOf(activeStoreId!);
    if (idx < 0 || idx + 1 >= ordered.length) return null;
    return ordered[idx + 1];
  }
}
