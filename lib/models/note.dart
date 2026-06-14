class Note {
  final int id;
  final int houseId;
  final String title;
  final String? content;
  final String? color;
  final String createdBy;
  final int sortOrder;
  final bool isPinned;
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
    this.isPinned = false,
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
    isPinned: json['isPinned'] as bool? ?? false,
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
    'isPinned': isPinned,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
