import 'package:pantry/services/server_version_service.dart';

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

  /// Whether the current user may edit this note. Populated by roles-aware
  /// servers that advertise the `share-users` capability (via a role cap or an
  /// editor share); `null` on older servers, where gating falls back to the
  /// house-level `canUpdateNotes`. See [NoteSharing.canEditWith].
  final bool? canEdit;

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
    this.canEdit,
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
    canEdit: json['canEdit'] as bool?,
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
    'canEdit': canEdit,
  };

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? color,
    int? sortOrder,
    bool? isPinned,
    int? updatedAt,
  }) => Note(
    id: id ?? this.id,
    houseId: houseId,
    title: title ?? this.title,
    content: content ?? this.content,
    color: color ?? this.color,
    createdBy: createdBy,
    sortOrder: sortOrder ?? this.sortOrder,
    isPinned: isPinned ?? this.isPinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    canEdit: canEdit,
  );
}

extension NoteSharing on Note {
  /// Whether the current user may edit this note. When the server advertises
  /// the `share-users` capability the per-note [Note.canEdit] governs (falling
  /// back to [houseCanUpdate] when the server didn't send it); on older servers
  /// the per-note field is ignored entirely and gating is purely house-level.
  bool canEditWith(bool houseCanUpdate) =>
      hasFeature('share-users') ? (canEdit ?? houseCanUpdate) : houseCanUpdate;
}
