/// Sentinel for [Label.copyWith]'s `listId`, where `null` is a meaningful
/// value ("global") and must be distinguishable from "leave unchanged".
const Object _unset = Object();

/// A user-defined tag with an icon + color. Unlike a category (an item has
/// **one**), an item can carry **many** labels. Scoped like a category: bound
/// to one list, or **global** when [listId] is `null`. Gated behind the
/// `labels` capability. See also [Category] for the scope semantics.
class Label {
  final int id;
  final int houseId;

  /// The list this label is scoped to, or `null` when it's **global** (offered
  /// on every list). Gated behind the `label-lists` capability; always `null`
  /// on servers without it.
  final int? listId;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const Label({
    required this.id,
    required this.houseId,
    this.listId,
    required this.name,
    required this.icon,
    required this.color,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Label.fromJson(Map<String, dynamic> json) => Label(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    listId: json['listId'] as int?,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    // Defaulted for resilience: labels cached before this field existed (or by
    // a pre-migration server) carry no `sortOrder`.
    sortOrder: json['sortOrder'] as int? ?? 0,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'listId': listId,
    'name': name,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// Pass `listId: null` to make the label global, an int to scope it, or omit
  /// it to leave the current scope unchanged.
  Label copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    Object? listId = _unset,
    int? updatedAt,
  }) => Label(
    id: id ?? this.id,
    houseId: houseId,
    listId: identical(listId, _unset) ? this.listId : listId as int?,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
