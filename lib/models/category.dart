class Category {
  final int id;
  final int houseId;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const Category({
    required this.id,
    required this.houseId,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
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
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    int? updatedAt,
  }) => Category(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
