import 'package:pantry_core/services/server_version_service.dart';

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

  /// The file this note mirrors, by Nextcloud file id, or `null` when the note
  /// is bound to no file. This is the field that says whether a note is
  /// synced — the other three describe a binding it already has.
  final int? syncFileId;

  /// The account whose storage holds [syncFileId]. Neither the note's author
  /// nor necessarily the viewer.
  final String? syncOwnerUid;

  /// Where the bound file sits under [syncOwnerUid]'s files root, e.g.
  /// `/Templates/Weekly shop.md`.
  ///
  /// The server resolves this from [syncFileId] on every response rather than
  /// storing it, so the path follows the file when someone moves it in Files.
  /// The same lookup returns nothing when the file is out of reach — in the
  /// trash, or purged — leaving a note with a [syncFileId] and no path. That
  /// is a binding waiting for its file back, not a broken one.
  final String? syncPath;

  /// When the note and its file last agreed, in unix seconds.
  final int? syncAt;

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
    this.syncFileId,
    this.syncOwnerUid,
    this.syncPath,
    this.syncAt,
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
    syncFileId: json['syncFileId'] as int?,
    syncOwnerUid: json['syncOwnerUid'] as String?,
    syncPath: json['syncPath'] as String?,
    syncAt: json['syncAt'] as int?,
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
    'syncFileId': syncFileId,
    'syncOwnerUid': syncOwnerUid,
    'syncPath': syncPath,
    'syncAt': syncAt,
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
    syncFileId: syncFileId,
    syncOwnerUid: syncOwnerUid,
    syncPath: syncPath,
    syncAt: syncAt,
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

extension NoteFileSync on Note {
  /// Whether this note mirrors a file. Gating the capability here rather than
  /// at each call site makes an older server's nulls and a newer server's
  /// unsynced note read identically.
  bool get isSynced => hasFeature('note-file-sync') && syncFileId != null;

  /// The bound file's path as it is shown, leading slash dropped, or `null`
  /// when the file is out of reach. See [Note.syncPath].
  String? get syncDisplayPath {
    final path = syncPath;
    if (path == null || path.isEmpty) return null;
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
