import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// The phone's half of the mirror: it fetches what the watch is showing and
/// pushes it across the link.
///
/// It runs only while the phone's process is alive. There is no listener
/// service and no headless isolate, because a cache store rewrites its whole
/// file per mutation and serialises writes within one isolate only — two
/// isolates on one cache file clobber each other silently, in exactly the
/// files the offline goal rests on. When the phone is dead the watch polls for
/// itself, which it can do over the same link the mirror would have used.
class WearMirrorHost {
  WearMirrorHost._();

  static final WearMirrorHost instance = WearMirrorHost._();

  final _link = WearLinkService.instance;
  final _mirror = WearMirrorService.instance;

  StreamSubscription<WearLinkMessage>? _messages;
  StreamSubscription<SyncOpApplied>? _applied;

  /// What each watch says it is showing. Per node, since a phone can be paired
  /// with more than one.
  final _scopes = <String, MirrorScopeReport>{};

  /// Paths waiting to be sent, and to whom. A batch across thirty items marks
  /// one path thirty times and sends one snapshot.
  final _pending = <String, Set<MirrorScope>>{};
  Timer? _coalesce;

  /// Long enough that a batch operation lands as one snapshot, short enough
  /// that a single check-off still feels pushed rather than polled.
  static const _coalesceWindow = Duration(milliseconds: 800);

  /// A debounce alone can be starved: a queue draining thirty ops over a
  /// minute would reset the window on every one and never send anything. Past
  /// this, the next mark sends instead of waiting.
  static const _coalesceCeiling = Duration(seconds: 4);

  DateTime? _markedAt;

  Future<void> init() async {
    if (_messages != null) return;
    if (!await _link.isAvailable()) return;
    _messages = _link.messages.listen(_onMessage);
    // A drained write is the phone's own change to a mirrored scope, which is
    // the trigger that keeps a watch in a pocket current without asking.
    _applied = SyncManager.instance.onApplied.listen(
      (event) => nudge(houseId: event.op.houseId),
    );
  }

  Future<void> dispose() async {
    await _messages?.cancel();
    await _applied?.cancel();
    _messages = null;
    _applied = null;
    forget();
  }

  /// Forget every watch's scope without dropping the link, so a sign-out stops
  /// this phone fetching for a watch whose credentials just died. The
  /// subscription stays: a watch still paired reports again on its next wake.
  void forget() {
    _coalesce?.cancel();
    _coalesce = null;
    _markedAt = null;
    _pending.clear();
    _scopes.clear();
  }

  /// Re-push what a watch is showing, after the phone learned something new.
  /// Restricted to [houseId] when the caller knows which house changed, since
  /// mirroring a house no watch is looking at spends the link for nothing.
  void nudge({int? houseId}) {
    for (final entry in _scopes.entries) {
      final report = entry.value;
      if (houseId != null && report.houseId != houseId) continue;
      _mark(entry.key, report);
    }
    _schedule();
  }

  void _onMessage(WearLinkMessage message) {
    final nodeId = message.nodeId;
    if (nodeId == null) return;
    switch (message.path) {
      case WearMirrorService.scopeReportPath:
      case WearMirrorService.mirrorRequestPath:
        final report = MirrorScopeReport.fromJson(message.data);
        // A request may arrive carrying nothing useful — a watch with no house
        // yet. The last good report is a better answer than none.
        final scope = report.isEmpty ? _scopes[nodeId] : report;
        if (scope == null || scope.isEmpty) return;
        _scopes[nodeId] = scope;
        _mark(nodeId, scope);
        _schedule();
    }
  }

  /// Every path one scope needs. Reference sets ride along because a row the
  /// watch draws names its category and its store, and a snapshot of items
  /// whose categories are unknown is a list of unlabelled rows.
  void _mark(String nodeId, MirrorScopeReport report) {
    final house = report.houseId;
    if (house == null) return;
    final scopes = <MirrorScope>{
      (entity: MirrorEntity.lists, key: house),
      (entity: MirrorEntity.categories, key: house),
      (entity: MirrorEntity.stores, key: house),
      (entity: MirrorEntity.labels, key: house),
      (entity: MirrorEntity.notes, key: house),
      if (hasFeature(kCustomFieldsFeature))
        (entity: MirrorEntity.fields, key: house),
      if (report.sessionId != null)
        (entity: MirrorEntity.sessionItems, key: report.sessionId!),
      if (report.listId != null && report.listId != kAllListsId)
        (entity: MirrorEntity.items, key: report.listId!),
    };
    _pending.putIfAbsent(nodeId, () => {}).addAll(scopes);
  }

  void _schedule() {
    if (_pending.isEmpty) return;
    final since = _markedAt;
    if (since != null && DateTime.now().difference(since) >= _coalesceCeiling) {
      unawaited(_flush());
      return;
    }
    _markedAt ??= DateTime.now();
    _coalesce?.cancel();
    _coalesce = Timer(_coalesceWindow, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    _coalesce?.cancel();
    _coalesce = null;
    _markedAt = null;
    final work = Map.of(_pending);
    _pending.clear();
    for (final entry in work.entries) {
      final report = _scopes[entry.key];
      if (report == null) continue;
      for (final scope in entry.value) {
        await _send(entry.key, report, scope);
      }
    }
  }

  Future<void> _send(
    String nodeId,
    MirrorScopeReport report,
    MirrorScope scope,
  ) async {
    final rows = await _rowsFor(report, scope);
    if (rows == null) return;
    await _link.stream(
      _mirror.pathFor(scope.entity, scope.key),
      _mirror.snapshot(rows, capturedAt: DateTime.now()),
      nodeId: nodeId,
    );
  }

  /// Fetch on the watch's behalf — including for a list the phone is not
  /// showing, which is the point: items are cached per list, so a phone that
  /// never opened the watch's list holds nothing to send. It spends the good
  /// radio to spare the small battery, and warms its own cache doing it.
  ///
  /// Null on a failed leg: a snapshot that could not be fetched is one the
  /// watch fetches for itself, so nothing is sent rather than something empty.
  /// What is queued for one watch, before any of it has been fetched.
  @visibleForTesting
  Set<MirrorScope> debugPendingFor(String nodeId) =>
      _pending[nodeId] ?? const {};

  /// Send what is queued now, without waiting out the coalescing window.
  @visibleForTesting
  Future<void> debugFlush() => _flush();

  Future<List<Map<String, dynamic>>?> _rowsFor(
    MirrorScopeReport report,
    MirrorScope scope,
  ) async {
    final house = report.houseId;
    if (house == null) return null;
    try {
      switch (scope.entity) {
        case MirrorEntity.lists:
          final lists = await ChecklistService.instance.getLists(house);
          return [for (final l in lists) l.toJson()];
        case MirrorEntity.items:
          final items = await ChecklistService.instance.getItems(
            house,
            scope.key,
          );
          return [for (final i in items) i.toJson()];
        case MirrorEntity.sessionItems:
          final items = await ShoppingService.instance.getItems(
            house,
            scope.key,
          );
          return [for (final i in items) i.toJson()];
        case MirrorEntity.categories:
          final categories = await CategoryService.instance.getCategories(
            house,
          );
          return [for (final c in categories) c.toJson()];
        case MirrorEntity.labels:
          final labels = await LabelService.instance.getLabels(house);
          return [for (final l in labels) l.toJson()];
        case MirrorEntity.stores:
          final stores = await StoreService.instance.getStores(house);
          return [for (final s in stores) s.toJson()];
        case MirrorEntity.fields:
          final fields = await CustomFieldService.instance.getFields(house);
          return [for (final f in fields) f.toJson()];
        case MirrorEntity.notes:
          // Whole, bodies included: `getNotes` returns them inline and
          // `cacheNotes` stores the list under one key, so a partial list is
          // indistinguishable on the watch from a house with fewer notes.
          final notes = await NoteService.instance.getNotes(house);
          NoteService.instance.cacheNotes(house, notes);
          return [for (final n in notes) n.toJson()];
      }
    } catch (_) {
      return null;
    }
  }
}
