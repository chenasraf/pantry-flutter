import 'package:pantry/services/server_version_service.dart';

class Photo {
  final int id;
  final int houseId;
  final int? folderId;
  final int fileId;
  final String? caption;
  final String uploadedBy;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  /// Whether the current user may edit this photo (role cap, or an editor share
  /// on the photo or its folder). `null` on servers without the `share-users`
  /// capability, where gating falls back to house-level `canUpdatePhotos`.
  final bool? canEdit;

  const Photo({
    required this.id,
    required this.houseId,
    this.folderId,
    required this.fileId,
    this.caption,
    required this.uploadedBy,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.canEdit,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    folderId: json['folderId'] as int?,
    fileId: json['fileId'] as int,
    caption: json['caption'] as String?,
    uploadedBy: json['uploadedBy'] as String,
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    canEdit: json['canEdit'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'folderId': folderId,
    'fileId': fileId,
    'caption': caption,
    'uploadedBy': uploadedBy,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'canEdit': canEdit,
  };
}

extension PhotoSharing on Photo {
  /// Whether the current user may edit this photo (caption). Honors the
  /// per-photo [Photo.canEdit] when the server advertises `share-users`;
  /// otherwise falls back to the house-level [houseCanUpdate].
  bool canEditWith(bool houseCanUpdate) =>
      hasFeature('share-users') ? (canEdit ?? houseCanUpdate) : houseCanUpdate;
}

class PhotoFolder {
  final int id;
  final int houseId;
  final String name;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  /// Whether the current user may edit/rename this folder. `null` on servers
  /// without the `share-users` capability, where gating falls back to
  /// house-level `canMovePhotos`.
  final bool? canEdit;

  const PhotoFolder({
    required this.id,
    required this.houseId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.canEdit,
  });

  factory PhotoFolder.fromJson(Map<String, dynamic> json) => PhotoFolder(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    canEdit: json['canEdit'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'canEdit': canEdit,
  };
}

extension PhotoFolderSharing on PhotoFolder {
  /// Whether the current user may edit/rename this folder. Honors the
  /// per-folder [PhotoFolder.canEdit] when the server advertises `share-users`;
  /// otherwise falls back to the house-level [houseCanMove].
  bool canEditWith(bool houseCanMove) =>
      hasFeature('share-users') ? (canEdit ?? houseCanMove) : houseCanMove;
}
