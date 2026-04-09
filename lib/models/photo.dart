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
  };
}

class PhotoFolder {
  final int id;
  final int houseId;
  final String name;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;

  const PhotoFolder({
    required this.id,
    required this.houseId,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PhotoFolder.fromJson(Map<String, dynamic> json) => PhotoFolder(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    name: json['name'] as String,
    sortOrder: json['sortOrder'] as int,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'name': name,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
