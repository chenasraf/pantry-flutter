class Member {
  final int id;
  final int houseId;
  final String userId;
  final String displayName;
  final String role;
  final int joinedAt;

  const Member({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    role: json['role'] as String,
    joinedAt: json['joinedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'userId': userId,
    'displayName': displayName,
    'role': role,
    'joinedAt': joinedAt,
  };
}
