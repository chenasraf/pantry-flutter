class ChecklistList {
  final int id;
  final int houseId;
  final String name;
  final String? description;
  final String icon;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const ChecklistList({
    required this.id,
    required this.houseId,
    required this.name,
    this.description,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChecklistList.fromJson(Map<String, dynamic> json) => ChecklistList(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    icon: json['icon'] as String,
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'description': description,
    'icon': icon,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
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
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

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
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
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
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
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
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  ListItem copyWith({bool? done, int? doneAt, String? doneBy}) => ListItem(
    id: id,
    listId: listId,
    name: name,
    description: description,
    categoryId: categoryId,
    quantity: quantity,
    done: done ?? this.done,
    doneAt: doneAt ?? this.doneAt,
    doneBy: doneBy ?? this.doneBy,
    rrule: rrule,
    repeatFromCompletion: repeatFromCompletion,
    deleteOnDone: deleteOnDone,
    nextDueAt: nextDueAt,
    imageFileId: imageFileId,
    imageUploadedBy: imageUploadedBy,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
