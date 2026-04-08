class House {
  final int id;
  final String name;
  final String? description;
  final String ownerUid;
  final String role;
  final int createdAt;
  final int updatedAt;

  const House({
    required this.id,
    required this.name,
    this.description,
    required this.ownerUid,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory House.fromJson(Map<String, dynamic> json) => House(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    ownerUid: json['ownerUid'] as String,
    role: json['role'] as String,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );
}
