import 'package:flutter/foundation.dart' hide Category;
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';

/// One kind of mirrored payload, and the key that scopes it — a house for the
/// reference sets, a list for items, a session for a trip's items.
///
/// Photos and item thumbnails are absent deliberately: bytes never ride the
/// link, and mirroring a photo's metadata without its bytes buys nothing.
enum MirrorEntity {
  lists('lists'),
  items('items'),
  sessionItems('session-items'),
  categories('categories'),
  labels('labels'),
  stores('stores'),
  fields('fields'),
  notes('notes');

  const MirrorEntity(this.wire);

  /// Stable across releases: it is half of a path two app versions may have to
  /// agree on across the link.
  final String wire;

  static MirrorEntity? fromWire(String wire) {
    for (final entity in values) {
      if (entity.wire == wire) return entity;
    }
    return null;
  }
}

/// Where one mirrored payload belongs.
typedef MirrorScope = ({MirrorEntity entity, int key});

/// What the watch is showing, as the phone hears it.
///
/// Scope authority flips once: the phone seeds it at pairing, and the watch
/// reports it from then on. Mirroring the phone's own scope instead would be
/// wrong precisely when the two legitimately differ, and accelerating the
/// wrong list is worse than not accelerating.
class MirrorScopeReport {
  /// Absent until the watch has a house — before that there is nothing to
  /// mirror, which is why the phone sends nothing rather than guessing.
  final int? houseId;
  final int? listId;

  /// The trip being walked, which takes the watch over wherever it is.
  final int? sessionId;

  const MirrorScopeReport({this.houseId, this.listId, this.sessionId});

  factory MirrorScopeReport.fromJson(Map<String, dynamic> json) =>
      MirrorScopeReport(
        houseId: json['houseId'] as int?,
        listId: json['listId'] as int?,
        sessionId: json['sessionId'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'houseId': houseId,
    'listId': listId,
    'sessionId': sessionId,
  };

  bool get isEmpty => houseId == null;

  @override
  bool operator ==(Object other) =>
      other is MirrorScopeReport &&
      other.houseId == houseId &&
      other.listId == listId &&
      other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(houseId, listId, sessionId);
}

/// The phone→watch mirror's shared half: the paths a snapshot travels under,
/// and the cache setter each one lands on.
///
/// A snapshot is the complete payload for one scope, model-shaped — the same
/// rows the receiving device's own fetch would have written, so landing one is
/// indistinguishable from having fetched it. That is what makes them
/// idempotent, order-free and safe to replay after an interrupted transfer.
///
/// The mirror is an accelerator and never a correctness precondition: a watch
/// that receives the seed and no snapshot after it is fully correct, only
/// slower and hungrier on battery.
class WearMirrorService extends ChangeNotifier {
  WearMirrorService._();

  static final WearMirrorService instance = WearMirrorService._();

  /// When each path last landed. Its own store rather than a field, because a
  /// watch process dies constantly and an in-memory answer would read as "no
  /// snapshot ever arrived" on every launch.
  final cache = CacheStore('mirror_cache.json');

  static const _prefix = '/mirror';
  static const _capturedAtPrefix = 'capturedAt';
  static const _newestKey = 'newestCapturedAt';

  /// The watch telling the phone what to mirror. Small control traffic, so it
  /// rides [WearLinkService.send] rather than a channel.
  static const scopeReportPath = '/watch/scope';

  /// The watch asking for the snapshots its scope needs, sent on wake. Being
  /// asked twice costs one duplicate snapshot, which lands idempotently.
  static const mirrorRequestPath = '/watch/mirror-request';

  /// The wire key for the payload rows. Short because a snapshot is the
  /// largest thing that crosses the link.
  static const rowsKey = 'rows';
  static const capturedAtKey = 'capturedAt';

  String pathFor(MirrorEntity entity, int key) =>
      '$_prefix/${entity.wire}/$key';

  /// The scope [path] addresses, or null when it is not a mirror path at all —
  /// the link is one transport shared by every feature layered on it, so
  /// credential and control traffic arrives here too.
  MirrorScope? scopeOf(String path) {
    if (!path.startsWith('$_prefix/')) return null;
    final parts = path.substring(_prefix.length + 1).split('/');
    if (parts.length != 2) return null;
    final entity = MirrorEntity.fromWire(parts[0]);
    final key = int.tryParse(parts[1]);
    if (entity == null || key == null) return null;
    return (entity: entity, key: key);
  }

  /// Wrap already-serialized rows as a snapshot. The caller holds the models
  /// and knows their type; what belongs here is the envelope both ends agree
  /// on.
  Map<String, dynamic> snapshot(
    List<Map<String, dynamic>> rows, {
    required DateTime capturedAt,
  }) => {capturedAtKey: capturedAt.millisecondsSinceEpoch, rowsKey: rows};

  /// Land a snapshot through the same cache setter the receiving device's own
  /// fetch writes, so the mirror introduces no second store and no precedence
  /// rule at any read site. Returns false for a payload this build cannot
  /// place, which a newer sender's unknown entity is.
  bool land(String path, Map<String, dynamic> payload) {
    final scope = scopeOf(path);
    if (scope == null) return false;
    final raw = payload[rowsKey];
    if (raw is! List) return false;
    final rows = <Map<String, dynamic>>[
      for (final row in raw)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
    if (rows.length != raw.length) return false;

    switch (scope.entity) {
      case MirrorEntity.lists:
        ChecklistService.instance.cacheLists(
          scope.key,
          rows.map(ChecklistList.fromJson).toList(),
        );
      case MirrorEntity.items:
        ChecklistService.instance.cacheItems(
          scope.key,
          rows.map(ListItem.fromJson).toList(),
        );
      case MirrorEntity.sessionItems:
        ShoppingService.instance.cacheItems(
          scope.key,
          rows.map(ListItem.fromJson).toList(),
        );
      case MirrorEntity.categories:
        CategoryService.instance.cacheCategories(
          scope.key,
          rows.map(Category.fromJson).toList(),
        );
      case MirrorEntity.labels:
        LabelService.instance.cacheLabels(
          scope.key,
          rows.map(Label.fromJson).toList(),
        );
      case MirrorEntity.stores:
        StoreService.instance.cacheStores(
          scope.key,
          rows.map(Store.fromJson).toList(),
        );
      case MirrorEntity.fields:
        CustomFieldService.instance.cacheFields(
          scope.key,
          rows.map(FieldDefinition.fromJson).toList(),
        );
      case MirrorEntity.notes:
        NoteService.instance.cacheNotes(
          scope.key,
          rows.map(Note.fromJson).toList(),
        );
    }

    _recordCapture(path, payload[capturedAtKey]);
    notifyListeners();
    return true;
  }

  /// When the snapshot at [path] was taken on the sending device — the sync
  /// detail the account page reads. A missing value means nothing has ever
  /// landed there, not that it landed long ago.
  DateTime? capturedAt(MirrorEntity entity, int key) {
    final stamp = cache.get<int>('$_capturedAtPrefix:${pathFor(entity, key)}');
    return stamp == null ? null : DateTime.fromMillisecondsSinceEpoch(stamp);
  }

  /// The most recent arrival of any kind: what "last mirrored" means to a
  /// wearer, who has no reason to think in scopes.
  DateTime? get lastCapturedAt {
    final stamp = cache.get<int>(_newestKey);
    return stamp == null ? null : DateTime.fromMillisecondsSinceEpoch(stamp);
  }

  /// Snapshots arrive out of order across scopes — a fetch on the phone's
  /// behalf can be older than one it already held — so the newest is tracked
  /// as it lands rather than derived by scanning afterwards.
  void _recordCapture(String path, Object? stamp) {
    if (stamp is! int) return;
    cache.set('$_capturedAtPrefix:$path', stamp);
    final newest = cache.get<int>(_newestKey);
    if (newest == null || stamp > newest) cache.set(_newestKey, stamp);
  }

  /// Forget every arrival record. Sign-out clears the caches these timestamps
  /// describe, so leaving them would date a snapshot that no longer exists.
  Future<void> clear() => cache.clear();
}
