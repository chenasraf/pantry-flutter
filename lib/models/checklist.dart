class ChecklistList {
  final int id;
  final int houseId;
  final String name;
  final String? description;
  final String icon;
  final String? color;
  final int sortOrder;
  final bool deleteOnDoneDefault;
  final int createdAt;
  final int updatedAt;

  const ChecklistList({
    required this.id,
    required this.houseId,
    required this.name,
    this.description,
    required this.icon,
    this.color,
    required this.sortOrder,
    this.deleteOnDoneDefault = false,
    required this.createdAt,
    required this.updatedAt,
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
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
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
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  ChecklistList copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    bool? deleteOnDoneDefault,
    int? updatedAt,
  }) => ChecklistList(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    deleteOnDoneDefault: deleteOnDoneDefault ?? this.deleteOnDoneDefault,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ListItem {
  final int id;
  final int listId;
  final String name;
  final String? description;
  final int? categoryId;
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
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  const ListItem({
    required this.id,
    required this.listId,
    required this.name,
    this.description,
    this.categoryId,
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
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'] as int,
    listId: json['listId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    categoryId: json['categoryId'] as int?,
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
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    deletedAt: json['deletedAt'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'listId': listId,
    'name': name,
    'description': description,
    'categoryId': categoryId,
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
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
  };

  ListItem copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    bool clearCategory = false,
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
    int? sortOrder,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) => ListItem(
    id: id ?? this.id,
    listId: listId,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
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
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
  );
}
