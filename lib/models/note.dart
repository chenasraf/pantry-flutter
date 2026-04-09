class Note {
  final int id;
  final int houseId;
  final String title;
  final String? content;
  final String? color;
  final String createdBy;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const Note({
    required this.id,
    required this.houseId,
    required this.title,
    this.content,
    this.color,
    required this.createdBy,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    title: json['title'] as String,
    content: json['content'] as String?,
    color: json['color'] as String?,
    createdBy: json['createdBy'] as String,
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'title': title,
    'content': content,
    'color': color,
    'createdBy': createdBy,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
