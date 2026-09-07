/// Sentinel for [Category.copyWith]'s `listId`, where `null` is a meaningful
/// value ("global") and must be distinguishable from "leave unchanged".
const Object _unset = Object();

class Category {
  final int id;
  final int houseId;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;

  /// The list this category is scoped to, or `null` when it's **global**
  /// (offered on every list). Gated behind the `category-lists` capability;
  /// always `null` on servers without it.
  final int? listId;
  final int createdAt;
  final int updatedAt;

  const Category({
    required this.id,
    required this.houseId,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
    this.listId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    sortOrder: json['sortOrder'] as int,
    listId: json['listId'] as int?,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
    'listId': listId,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// Pass `listId: null` to make the category global, an int to scope it, or
  /// omit it to leave the current scope unchanged.
  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    Object? listId = _unset,
    int? updatedAt,
  }) => Category(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    listId: identical(listId, _unset) ? this.listId : listId as int?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
