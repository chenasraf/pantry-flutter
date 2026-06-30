import 'package:pantry/services/server_version_service.dart';

/// Effective per-house capabilities as computed and merged server-side (the OR
/// of all the user's roles in the house). All 18 keys are always present on a
/// roles-aware server; older servers omit the block entirely.
///
/// Missing keys default to `true` so the app behaves exactly as it did before
/// roles existed when talking to an un-upgraded server. The model never
/// computes permissions — it only reads what the server sends.
class HousePermissions {
  final bool canViewLists;
  final bool canCreateLists;
  final bool canEditLists;
  final bool canDeleteLists;
  final bool canAddItems;
  final bool canDeleteItems;
  final bool canCopyItems;
  final bool canMoveItems;
  final bool canCheckItems;
  final bool canViewPhotos;
  final bool canUploadPhotos;
  final bool canUpdatePhotos;
  final bool canDeletePhotos;
  final bool canMovePhotos;
  final bool canViewNotes;
  final bool canCreateNotes;
  final bool canUpdateNotes;
  final bool canDeleteNotes;

  const HousePermissions({
    this.canViewLists = true,
    this.canCreateLists = true,
    this.canEditLists = true,
    this.canDeleteLists = true,
    this.canAddItems = true,
    this.canDeleteItems = true,
    this.canCopyItems = true,
    this.canMoveItems = true,
    this.canCheckItems = true,
    this.canViewPhotos = true,
    this.canUploadPhotos = true,
    this.canUpdatePhotos = true,
    this.canDeletePhotos = true,
    this.canMovePhotos = true,
    this.canViewNotes = true,
    this.canCreateNotes = true,
    this.canUpdateNotes = true,
    this.canDeleteNotes = true,
  });

  /// Every capability granted — used as the default for pre-roles servers and
  /// whenever the server hasn't confirmed roles support.
  static const HousePermissions unrestricted = HousePermissions();

  /// Each missing key defaults to `true` (see class doc).
  factory HousePermissions.fromJson(Map<String, dynamic> json) {
    bool read(String key) => json[key] as bool? ?? true;
    return HousePermissions(
      canViewLists: read('canViewLists'),
      canCreateLists: read('canCreateLists'),
      canEditLists: read('canEditLists'),
      canDeleteLists: read('canDeleteLists'),
      canAddItems: read('canAddItems'),
      canDeleteItems: read('canDeleteItems'),
      canCopyItems: read('canCopyItems'),
      canMoveItems: read('canMoveItems'),
      canCheckItems: read('canCheckItems'),
      canViewPhotos: read('canViewPhotos'),
      canUploadPhotos: read('canUploadPhotos'),
      canUpdatePhotos: read('canUpdatePhotos'),
      canDeletePhotos: read('canDeletePhotos'),
      canMovePhotos: read('canMovePhotos'),
      canViewNotes: read('canViewNotes'),
      canCreateNotes: read('canCreateNotes'),
      canUpdateNotes: read('canUpdateNotes'),
      canDeleteNotes: read('canDeleteNotes'),
    );
  }

  Map<String, dynamic> toJson() => {
    'canViewLists': canViewLists,
    'canCreateLists': canCreateLists,
    'canEditLists': canEditLists,
    'canDeleteLists': canDeleteLists,
    'canAddItems': canAddItems,
    'canDeleteItems': canDeleteItems,
    'canCopyItems': canCopyItems,
    'canMoveItems': canMoveItems,
    'canCheckItems': canCheckItems,
    'canViewPhotos': canViewPhotos,
    'canUploadPhotos': canUploadPhotos,
    'canUpdatePhotos': canUpdatePhotos,
    'canDeletePhotos': canDeletePhotos,
    'canMovePhotos': canMovePhotos,
    'canViewNotes': canViewNotes,
    'canCreateNotes': canCreateNotes,
    'canUpdateNotes': canUpdateNotes,
    'canDeleteNotes': canDeleteNotes,
  };
}

class House {
  final int id;
  final String name;
  final String? description;
  final String ownerUid;
  final String role;
  final bool isAdmin;
  final HousePermissions permissions;
  final int createdAt;
  final int updatedAt;

  const House({
    required this.id,
    required this.name,
    this.description,
    required this.ownerUid,
    required this.role,
    this.isAdmin = false,
    this.permissions = HousePermissions.unrestricted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory House.fromJson(Map<String, dynamic> json) => House(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    ownerUid: json['ownerUid'] as String,
    role: json['role'] as String,
    isAdmin: json['isAdmin'] as bool? ?? false,
    permissions: json['permissions'] == null
        ? HousePermissions.unrestricted
        : HousePermissions.fromJson(
            json['permissions'] as Map<String, dynamic>,
          ),
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerUid': ownerUid,
    'role': role,
    'isAdmin': isAdmin,
    'permissions': permissions.toJson(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

extension HouseEffectivePermissions on House {
  /// The capabilities the UI should gate on. When the server hasn't confirmed
  /// roles support (`capabilities.pantry.features` lacks `"roles"`), gating is
  /// off entirely and every action is allowed — preserving today's behavior
  /// against un-upgraded servers regardless of what the `permissions` block
  /// happens to contain.
  HousePermissions get effectivePermissions =>
      hasFeature('roles') ? permissions : HousePermissions.unrestricted;
}
