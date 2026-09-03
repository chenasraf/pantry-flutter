import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/services/server_version_service.dart';

class ChecklistList {
  final int id;
  final int houseId;
  final String name;
  final String? description;
  final String icon;
  final String? color;
  final int sortOrder;
  final bool deleteOnDoneDefault;
  final bool hideProgressHero;
  final int createdAt;
  final int updatedAt;

  /// Epoch-ms the list was trashed / archived, or `null` when it's active.
  /// The trash/archive views are served by dedicated endpoints, so these aren't
  /// required for logic; they mirror the server shape (and the item model) and
  /// are handy for badging a list's lifecycle state. A list is in at most one of
  /// the three states (active / trash / archive).
  final int? deletedAt;
  final int? archivedAt;

  /// Whether the current user may edit this list's settings (name/icon/color).
  /// `null` on servers without the `share-users` capability, where gating falls
  /// back to house-level `canEditLists`. See [ChecklistSharing].
  final bool? canEdit;

  /// Whether the user reaches this list *only* via a share (rather than through
  /// house membership). Combined with [canEdit] this decides whether the whole
  /// list is read-only: a `sharedOnly` list without edit access disables every
  /// item write. `null` on servers without the `share-users` capability.
  final bool? sharedOnly;

  const ChecklistList({
    required this.id,
    required this.houseId,
    required this.name,
    this.description,
    required this.icon,
    this.color,
    required this.sortOrder,
    this.deleteOnDoneDefault = false,
    this.hideProgressHero = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.archivedAt,
    this.canEdit,
    this.sharedOnly,
  });

  factory ChecklistList.fromJson(Map<String, dynamic> json) => ChecklistList(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    icon: json['icon'] as String,
    color: json['color'] as String?,
    sortOrder: json['sortOrder'] as int,
    deleteOnDoneDefault: json['deleteOnDoneDefault'] as bool? ?? false,
    hideProgressHero: json['hideProgressHero'] as bool? ?? false,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    deletedAt: json['deletedAt'] as int?,
    archivedAt: json['archivedAt'] as int?,
    canEdit: json['canEdit'] as bool?,
    sharedOnly: json['sharedOnly'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'description': description,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
    'deleteOnDoneDefault': deleteOnDoneDefault,
    'hideProgressHero': hideProgressHero,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
    'archivedAt': archivedAt,
    'canEdit': canEdit,
    'sharedOnly': sharedOnly,
  };

  ChecklistList copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    bool? deleteOnDoneDefault,
    bool? hideProgressHero,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
    int? archivedAt,
    bool clearArchivedAt = false,
  }) => ChecklistList(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    deleteOnDoneDefault: deleteOnDoneDefault ?? this.deleteOnDoneDefault,
    hideProgressHero: hideProgressHero ?? this.hideProgressHero,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    canEdit: canEdit,
    sharedOnly: sharedOnly,
  );
}

extension ChecklistSharing on ChecklistList {
  /// Whether item-level writes (add / check-off / edit / move / copy / delete
  /// item, reorder) are permitted on this list based on its share level. A
  /// view-only shared list (`sharedOnly && !canEdit`) is fully read-only;
  /// everything else keeps the normal granular capabilities. Only consulted
  /// when the server advertises `share-users`; otherwise always writable.
  bool get isWritable {
    if (!hasFeature('share-users')) return true;
    return !((sharedOnly ?? false) && !(canEdit ?? true));
  }

  /// Whether this list's own settings (name/icon/color) may be edited. Honors
  /// the per-list [ChecklistList.canEdit] when the server advertises
  /// `share-users`; otherwise falls back to the house-level [houseCanEdit].
  bool canEditSettingsWith(bool houseCanEdit) =>
      hasFeature('share-users') ? (canEdit ?? houseCanEdit) : houseCanEdit;
}

/// A single price entry for an item. [storeId] `null` is the store-less
/// (default) price — at most one per item; a non-null [storeId] scopes the
/// price to that store, at most one per store. [priceType] is `'set'` (single
/// amount in [priceMin]), `'range'` ([priceMin]–[priceMax]), or null for no
/// price. [priceCurrency] is an ISO 4217 code. Gated behind the `item-price`
/// capability.
class ItemPrice {
  final int? storeId;
  final String? priceType;
  final double? priceMin;
  final double? priceMax;
  final String? priceCurrency;

  const ItemPrice({
    this.storeId,
    this.priceType,
    this.priceMin,
    this.priceMax,
    this.priceCurrency,
  });

  factory ItemPrice.fromJson(Map<String, dynamic> json) => ItemPrice(
    storeId: json['storeId'] as int?,
    priceType: json['priceType'] as String?,
    priceMin: (json['priceMin'] as num?)?.toDouble(),
    priceMax: (json['priceMax'] as num?)?.toDouble(),
    priceCurrency: json['priceCurrency'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'storeId': storeId,
    'priceType': priceType,
    'priceMin': priceMin,
    'priceMax': priceMax,
    'priceCurrency': priceCurrency,
  };
}

class ListItem {
  final int id;
  final int listId;
  final String name;
  final String? description;
  final int? categoryId;
  final List<int> storeIds;
  final List<int> labelIds;
  final String? quantity;
  final bool done;
  final int? doneAt;
  final String? doneBy;
  final String? rrule;
  final bool repeatFromCompletion;
  final bool deleteOnDone;
  final int? nextDueAt;
  final int? imageFileId;
  final String? imageUploadedBy;
  final String? addedBy;
  final String? barcode;

  /// Prices for this item, one per store plus an optional store-less default.
  /// Empty when the item carries no price. See [ItemPrice] and the resolution
  /// helpers in `utils/price.dart`. Gated behind the `item-price` capability.
  final List<ItemPrice> prices;

  /// Per-item custom-field values, one per filled field. Empty when the item
  /// carries none. Gated behind the `custom-fields` capability; mirrors
  /// [prices] in how it rides the item's create/update payload.
  final List<FieldValue> customFields;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final int? archivedAt;

  const ListItem({
    required this.id,
    required this.listId,
    required this.name,
    this.description,
    this.categoryId,
    this.storeIds = const [],
    this.labelIds = const [],
    this.quantity,
    required this.done,
    this.doneAt,
    this.doneBy,
    this.rrule,
    required this.repeatFromCompletion,
    required this.deleteOnDone,
    this.nextDueAt,
    this.imageFileId,
    this.imageUploadedBy,
    this.addedBy,
    this.barcode,
    this.prices = const [],
    this.customFields = const [],
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.archivedAt,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'] as int,
    listId: json['listId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    categoryId: json['categoryId'] as int?,
    storeIds: ((json['storeIds'] as List?) ?? const [])
        .map((e) => e as int)
        .toList(),
    labelIds: ((json['labelIds'] as List?) ?? const [])
        .map((e) => e as int)
        .toList(),
    quantity: json['quantity'] as String?,
    done: json['done'] as bool,
    doneAt: json['doneAt'] as int?,
    doneBy: json['doneBy'] as String?,
    rrule: json['rrule'] as String?,
    repeatFromCompletion: json['repeatFromCompletion'] as bool,
    deleteOnDone: json['deleteOnDone'] as bool? ?? false,
    nextDueAt: json['nextDueAt'] as int?,
    imageFileId: json['imageFileId'] as int?,
    imageUploadedBy: json['imageUploadedBy'] as String?,
    addedBy: json['addedBy'] as String?,
    barcode: json['barcode'] as String?,
    prices: _pricesFromJson(json),
    customFields: _customFieldsFromJson(json),
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    deletedAt: json['deletedAt'] as int?,
    archivedAt: json['archivedAt'] as int?,
  );

  /// Read prices from either shape: the new `prices` array (servers advertising
  /// `item-price-per-store`, and our own cache) or the legacy flat
  /// `priceType/priceMin/priceMax/priceCurrency` fields (older servers), which
  /// collapse to a single store-less [ItemPrice].
  static List<ItemPrice> _pricesFromJson(Map<String, dynamic> json) {
    final raw = json['prices'];
    if (raw is List) {
      return raw
          .map((e) => ItemPrice.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final type = json['priceType'] as String?;
    final min = (json['priceMin'] as num?)?.toDouble();
    if ((type == 'set' || type == 'range') && min != null) {
      return [
        ItemPrice(
          priceType: type,
          priceMin: min,
          priceMax: (json['priceMax'] as num?)?.toDouble(),
          priceCurrency: json['priceCurrency'] as String?,
        ),
      ];
    }
    return const [];
  }

  /// Read custom-field values from the `customFields` array (present on servers
  /// advertising `custom-fields`, and our own cache); absent elsewhere.
  static List<FieldValue> _customFieldsFromJson(Map<String, dynamic> json) {
    final raw = json['customFields'];
    if (raw is List) {
      return raw
          .map((e) => FieldValue.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listId': listId,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'storeIds': storeIds,
    'labelIds': labelIds,
    'quantity': quantity,
    'done': done,
    'doneAt': doneAt,
    'doneBy': doneBy,
    'rrule': rrule,
    'repeatFromCompletion': repeatFromCompletion,
    'deleteOnDone': deleteOnDone,
    'nextDueAt': nextDueAt,
    'imageFileId': imageFileId,
    'imageUploadedBy': imageUploadedBy,
    'addedBy': addedBy,
    'barcode': barcode,
    'prices': prices.map((p) => p.toJson()).toList(),
    'customFields': customFields.map((v) => v.toJson()).toList(),
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
    'archivedAt': archivedAt,
  };

  ListItem copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    bool clearCategory = false,
    List<int>? storeIds,
    List<int>? labelIds,
    String? quantity,
    bool? done,
    int? doneAt,
    String? doneBy,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    int? nextDueAt,
    int? imageFileId,
    bool clearImage = false,
    String? imageUploadedBy,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
    int? sortOrder,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
    int? archivedAt,
    bool clearArchivedAt = false,
  }) => ListItem(
    id: id ?? this.id,
    listId: listId,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    storeIds: storeIds ?? this.storeIds,
    labelIds: labelIds ?? this.labelIds,
    quantity: quantity ?? this.quantity,
    done: done ?? this.done,
    doneAt: doneAt ?? this.doneAt,
    doneBy: doneBy ?? this.doneBy,
    rrule: rrule ?? this.rrule,
    repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
    deleteOnDone: deleteOnDone ?? this.deleteOnDone,
    nextDueAt: nextDueAt ?? this.nextDueAt,
    imageFileId: clearImage ? null : (imageFileId ?? this.imageFileId),
    imageUploadedBy: clearImage
        ? null
        : (imageUploadedBy ?? this.imageUploadedBy),
    addedBy: addedBy,
    barcode: barcode ?? this.barcode,
    prices: prices ?? this.prices,
    customFields: customFields ?? this.customFields,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
  );
}

/// Envelope returned by the house-scoped batch item endpoints (move / copy /
/// delete / category). [items] are the affected items to reconcile against
/// local state (empty for delete); [skipped] are ids the server refused for
/// access reasons — not errors, the rest of the batch still succeeded.
class PantryBatchResult {
  final bool success;
  final List<ListItem> items;
  final List<int> skipped;

  const PantryBatchResult({
    required this.success,
    required this.items,
    required this.skipped,
  });

  factory PantryBatchResult.fromJson(Map<String, dynamic> json) =>
      PantryBatchResult(
        success: json['success'] as bool? ?? true,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        skipped: ((json['skipped'] as List?) ?? const [])
            .map((e) => e as int)
            .toList(),
      );
}
