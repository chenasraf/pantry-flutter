/// Where a linked checklist item stands.
enum StockLinkState {
  open,
  checked,
  archived,
  trashed;

  static StockLinkState parse(Object? raw) => switch (raw) {
    'checked' => checked,
    'archived' => archived,
    'trashed' => trashed,
    _ => open,
  };
}

/// A checklist item an inventory item is linked to, or could be.
class StockLinkRow {
  final int itemId;
  final String name;
  final String? quantity;
  final int listId;
  final String listName;
  final String? listColor;
  final StockLinkState state;

  const StockLinkRow({
    required this.itemId,
    required this.name,
    this.quantity,
    required this.listId,
    required this.listName,
    this.listColor,
    this.state = StockLinkState.open,
  });

  factory StockLinkRow.fromJson(Map<String, dynamic> json) => StockLinkRow(
    itemId: json['itemId'] as int,
    name: json['name'] as String? ?? '',
    quantity: json['quantity'] as String?,
    listId: json['listId'] as int,
    listName: json['listName'] as String? ?? '',
    listColor: json['listColor'] as String?,
    state: StockLinkState.parse(json['state']),
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'quantity': quantity,
    'listId': listId,
    'listName': listName,
    'listColor': listColor,
    'state': state.name,
  };

  static List<StockLinkRow> listFrom(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map) StockLinkRow.fromJson(e.cast<String, dynamic>()),
  ];
}

/// An inventory item a checklist item restocks.
class StockLinkSource {
  final int itemId;
  final String name;
  final int listId;
  final String listName;

  const StockLinkSource({
    required this.itemId,
    required this.name,
    required this.listId,
    required this.listName,
  });

  factory StockLinkSource.fromJson(Map<String, dynamic> json) =>
      StockLinkSource(
        itemId: json['itemId'] as int,
        name: json['name'] as String? ?? '',
        listId: json['listId'] as int,
        listName: json['listName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'name': name,
    'listId': listId,
    'listName': listName,
  };

  static List<StockLinkSource> listFrom(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map) StockLinkSource.fromJson(e.cast<String, dynamic>()),
  ];
}

/// What a tick of a linked checklist item put back into one inventory item.
class RestockEntry {
  final int itemId;
  final int listId;
  final String itemName;
  final String listName;

  /// The amount a count item gained, or was set to when [replaced].
  final String? added;

  /// Set on a level item, which the tick took to Full.
  final String? previousLevel;

  /// Expiring or expired stock thrown out rather than added to.
  final bool replaced;

  const RestockEntry({
    required this.itemId,
    required this.listId,
    required this.itemName,
    required this.listName,
    this.added,
    this.previousLevel,
    this.replaced = false,
  });

  /// Neither an amount nor a level: only the date was renewed, which no text
  /// mentions.
  bool get onlyRenewedDate => added == null && previousLevel == null;

  factory RestockEntry.fromJson(Map<String, dynamic> json) => RestockEntry(
    itemId: json['itemId'] as int,
    listId: json['listId'] as int,
    itemName: json['itemName'] as String? ?? '',
    listName: json['listName'] as String? ?? '',
    added: json['added'] as String?,
    previousLevel: json['previousLevel'] as String?,
    replaced: json['replaced'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'listId': listId,
    'itemName': itemName,
    'listName': listName,
    'added': added,
    'previousLevel': previousLevel,
    'replaced': replaced,
  };

  static List<RestockEntry> listFrom(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map) RestockEntry.fromJson(e.cast<String, dynamic>()),
  ];
}

enum RestockSyncKind {
  added,
  revived,
  changed,
  pinned,
  recovered;

  static RestockSyncKind? tryParse(Object? raw) => switch (raw) {
    'added' => added,
    'revived' => revived,
    'changed' => changed,
    'pinned' => pinned,
    'recovered' => recovered,
    _ => null,
  };
}

/// What the server's restock sync did to a checklist item, as a consequence
/// of the write whose response carries it.
class RestockSyncEvent {
  final RestockSyncKind kind;

  /// The inventory item whose state caused it.
  final int itemId;
  final int rowId;
  final String rowName;
  final String? quantity;
  final int listId;
  final String listName;

  const RestockSyncEvent({
    required this.kind,
    required this.itemId,
    required this.rowId,
    required this.rowName,
    this.quantity,
    required this.listId,
    required this.listName,
  });

  static List<RestockSyncEvent> listFrom(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map)
          if (RestockSyncKind.tryParse(e['event']) case final kind?)
            RestockSyncEvent(
              kind: kind,
              itemId: e['itemId'] as int,
              rowId: e['rowId'] as int,
              rowName: e['rowName'] as String? ?? '',
              quantity: e['quantity'] as String?,
              listId: e['listId'] as int,
              listName: e['listName'] as String? ?? '',
            ),
  ];
}

/// What a Shopping Mode check or uncheck did to stock.
class ShoppingCheckResult {
  /// The row's restock record after the write; null once unchecked.
  final List<RestockEntry>? restock;
  final List<RestockEntry> restocked;
  final List<RestockEntry> restockUndone;
  final List<RestockSyncEvent> restockSync;

  const ShoppingCheckResult({
    this.restock,
    this.restocked = const [],
    this.restockUndone = const [],
    this.restockSync = const [],
  });

  static const empty = ShoppingCheckResult();

  factory ShoppingCheckResult.fromJson(Map<String, dynamic> json) =>
      ShoppingCheckResult(
        restock: json['restock'] == null
            ? null
            : RestockEntry.listFrom(json['restock']),
        restocked: RestockEntry.listFrom(json['restocked']),
        restockUndone: RestockEntry.listFrom(json['restockUndone']),
        restockSync: RestockSyncEvent.listFrom(json['restockSync']),
      );
}
