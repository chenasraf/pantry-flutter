enum SyncEntity { checklistList, checklistItem, category, store, note }

enum SyncOpKind {
  create,
  update,
  delete,
  toggle,
  reorder,
  restore,
  permanentDelete,
  emptyTrash,
  archive,
  unarchive,

  /// House-scoped group action over many items (move / copy / delete /
  /// set-category). Unlike every other kind this targets a *list* of items
  /// carried in `body['itemIds']` rather than a single [SyncOp.entityId]; the
  /// specific action is `body['batchAction']`.
  batch,
}

class SyncOp {
  final String uuid;
  final SyncEntity entity;
  final SyncOpKind op;
  final int houseId;
  final int? entityId;
  final int? tempEntityId;
  final int? parentId;
  final Map<String, dynamic> body;
  final int createdAt;
  final int attemptCount;
  final String? lastError;

  const SyncOp({
    required this.uuid,
    required this.entity,
    required this.op,
    required this.houseId,
    this.entityId,
    this.tempEntityId,
    this.parentId,
    this.body = const {},
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  SyncOp copyWith({
    int? entityId,
    int? tempEntityId,
    int? parentId,
    Map<String, dynamic>? body,
    int? attemptCount,
    String? lastError,
  }) => SyncOp(
    uuid: uuid,
    entity: entity,
    op: op,
    houseId: houseId,
    entityId: entityId ?? this.entityId,
    tempEntityId: tempEntityId ?? this.tempEntityId,
    parentId: parentId ?? this.parentId,
    body: body ?? this.body,
    createdAt: createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError ?? this.lastError,
  );

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'entity': entity.name,
    'op': op.name,
    'houseId': houseId,
    if (entityId != null) 'entityId': entityId,
    if (tempEntityId != null) 'tempEntityId': tempEntityId,
    if (parentId != null) 'parentId': parentId,
    'body': body,
    'createdAt': createdAt,
    'attemptCount': attemptCount,
    if (lastError != null) 'lastError': lastError,
  };

  static SyncOp fromJson(Map<String, dynamic> json) => SyncOp(
    uuid: json['uuid'] as String,
    entity: SyncEntity.values.byName(json['entity'] as String),
    op: SyncOpKind.values.byName(json['op'] as String),
    houseId: json['houseId'] as int,
    entityId: json['entityId'] as int?,
    tempEntityId: json['tempEntityId'] as int?,
    parentId: json['parentId'] as int?,
    body: (json['body'] as Map?)?.cast<String, dynamic>() ?? const {},
    createdAt: json['createdAt'] as int,
    attemptCount: json['attemptCount'] as int? ?? 0,
    lastError: json['lastError'] as String?,
  );

  /// Returns the id used to address this op's entity at dispatch time —
  /// the real server id if known, otherwise the temp negative id used for
  /// optimistic UI. Always non-null for ops that target a specific record.
  int? get effectiveEntityId => entityId ?? tempEntityId;
}
