class Store {
  final int id;
  final int houseId;
  final String name;
  final String icon;
  final String color;
  final int createdAt;
  final int updatedAt;

  const Store({
    required this.id,
    required this.houseId,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'icon': icon,
    'color': color,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  Store copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    int? updatedAt,
  }) => Store(
    id: id ?? this.id,
    houseId: houseId,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
