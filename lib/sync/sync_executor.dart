import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/note_service.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/services/store_service.dart';
import 'package:pantry/sync/sync_op.dart';

/// Result of executing a single op.
///
/// [entity] is the canonical server record (the response of the create/
/// update/restore/toggle call). Null for ops that don't return an entity
/// (delete, permanentDelete, emptyTrash, reorder). For a [SyncOpKind.batch]
/// op it holds the [PantryBatchResult] envelope so the controller can
/// reconcile the affected items.
class SyncResult {
  final Object? entity;
  const SyncResult(this.entity);
  static const empty = SyncResult(null);
}

/// Maps a [SyncOp] to the appropriate service call. The only place that
/// knows the REST shapes for sync.
class SyncExecutor {
  const SyncExecutor();

  Future<SyncResult> execute(SyncOp op) async {
    switch (op.entity) {
      case SyncEntity.checklistList:
        return _executeChecklistList(op);
      case SyncEntity.checklistItem:
        return _executeChecklistItem(op);
      case SyncEntity.category:
        return _executeCategory(op);
      case SyncEntity.store:
        return _executeStore(op);
      case SyncEntity.note:
        return _executeNote(op);
      case SyncEntity.shoppingCheck:
        return _executeShoppingCheck(op);
      case SyncEntity.shoppingSkip:
        return _executeShoppingSkip(op);
    }
  }

  /// A Shopping Mode check-log write: `create` checks the item off, `delete`
  /// reverses it. `parentId` is the session id, `entityId` the item id. Both
  /// endpoints return only `{success:true}`, so there's no entity to bind.
  Future<SyncResult> _executeShoppingCheck(SyncOp op) async {
    final svc = ShoppingService.instance;
    final sessionId = op.parentId;
    final itemId = op.entityId;
    if (sessionId == null || itemId == null) return SyncResult.empty;
    switch (op.op) {
      case SyncOpKind.create:
        await svc.checkItem(op.houseId, sessionId, itemId);
        return SyncResult.empty;
      case SyncOpKind.delete:
        await svc.uncheckItem(op.houseId, sessionId, itemId);
        return SyncResult.empty;
      default:
        return SyncResult.empty;
    }
  }

  /// A Shopping Mode "remove from this trip" write: `create` skips the item off
  /// the trip, `delete` unskips it. `parentId` is the session id, `entityId`
  /// the item id. Both endpoints return only `{success:true}`, so there's no
  /// entity to bind.
  Future<SyncResult> _executeShoppingSkip(SyncOp op) async {
    final svc = ShoppingService.instance;
    final sessionId = op.parentId;
    final itemId = op.entityId;
    if (sessionId == null || itemId == null) return SyncResult.empty;
    switch (op.op) {
      case SyncOpKind.create:
        await svc.skipItem(op.houseId, sessionId, itemId);
        return SyncResult.empty;
      case SyncOpKind.delete:
        await svc.unskipItem(op.houseId, sessionId, itemId);
        return SyncResult.empty;
      default:
        return SyncResult.empty;
    }
  }

  Future<SyncResult> _executeChecklistList(SyncOp op) async {
    final svc = ChecklistService.instance;
    final houseId = op.houseId;
    final id = op.entityId;
    switch (op.op) {
      case SyncOpKind.create:
        final list = await svc.createList(
          houseId,
          name: op.body['name'] as String,
          description: op.body['description'] as String?,
          icon: op.body['icon'] as String?,
          color: op.body['color'] as String?,
        );
        return SyncResult(list);
      case SyncOpKind.update:
        if (id == null) return SyncResult.empty;
        final list = await svc.updateList(
          houseId,
          id,
          name: op.body['name'] as String?,
          description: op.body['description'] as String?,
          icon: op.body['icon'] as String?,
          color: op.body['color'] as String?,
          sortOrder: op.body['sortOrder'] as int?,
          deleteOnDoneDefault: op.body['deleteOnDoneDefault'] as bool?,
        );
        return SyncResult(list);
      case SyncOpKind.delete:
        if (id == null) return SyncResult.empty;
        await svc.deleteList(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.restore:
        if (id == null) return SyncResult.empty;
        final list = await svc.restoreList(houseId, id);
        return SyncResult(list);
      case SyncOpKind.permanentDelete:
        if (id == null) return SyncResult.empty;
        await svc.permanentlyDeleteList(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.emptyTrash:
        await svc.emptyListsTrash(houseId);
        return SyncResult.empty;
      case SyncOpKind.reorder:
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderLists(houseId, order);
        return SyncResult.empty;
      case SyncOpKind.toggle:
      case SyncOpKind.archive:
      case SyncOpKind.unarchive:
      case SyncOpKind.batch:
        return SyncResult.empty;
    }
  }

  Future<SyncResult> _executeChecklistItem(SyncOp op) async {
    final svc = ChecklistService.instance;
    final houseId = op.houseId;
    final listId = op.parentId;
    final id = op.entityId;
    switch (op.op) {
      case SyncOpKind.create:
        if (listId == null) return SyncResult.empty;
        final item = await svc.createItem(
          houseId,
          listId,
          name: op.body['name'] as String,
          description: op.body['description'] as String?,
          quantity: op.body['quantity'] as String?,
          categoryId: op.body['categoryId'] as int?,
          storeIds: (op.body['storeIds'] as List?)?.cast<int>(),
          rrule: op.body['rrule'] as String?,
          repeatFromCompletion: op.body['repeatFromCompletion'] as bool?,
          deleteOnDone: op.body['deleteOnDone'] as bool?,
          barcode: op.body['barcode'] as String?,
          prices: _pricesFromBody(op.body['prices']),
        );
        return SyncResult(item);
      case SyncOpKind.update:
        if (listId == null || id == null) return SyncResult.empty;
        final item = await svc.updateItem(
          houseId,
          listId,
          id,
          name: op.body['name'] as String?,
          description: op.body['description'] as String?,
          quantity: op.body['quantity'] as String?,
          categoryId: op.body['categoryId'] as int?,
          clearCategory: op.body['clearCategory'] as bool? ?? false,
          storeIds: (op.body['storeIds'] as List?)?.cast<int>(),
          rrule: op.body['rrule'] as String?,
          repeatFromCompletion: op.body['repeatFromCompletion'] as bool?,
          deleteOnDone: op.body['deleteOnDone'] as bool?,
          barcode: op.body['barcode'] as String?,
          prices: _pricesFromBody(op.body['prices']),
        );
        return SyncResult(item);
      case SyncOpKind.delete:
        if (listId == null || id == null) return SyncResult.empty;
        await svc.deleteItem(houseId, listId, id);
        return SyncResult.empty;
      case SyncOpKind.toggle:
        if (listId == null || id == null) return SyncResult.empty;
        final item = await svc.toggleItem(houseId, listId, id);
        return SyncResult(item);
      case SyncOpKind.restore:
        if (listId == null || id == null) return SyncResult.empty;
        final item = await svc.restoreItem(houseId, listId, id);
        return SyncResult(item);
      case SyncOpKind.permanentDelete:
        if (listId == null || id == null) return SyncResult.empty;
        await svc.permanentlyDeleteItem(houseId, listId, id);
        return SyncResult.empty;
      case SyncOpKind.emptyTrash:
        if (listId == null) return SyncResult.empty;
        await svc.emptyTrash(houseId, listId);
        return SyncResult.empty;
      case SyncOpKind.archive:
        if (listId == null || id == null) return SyncResult.empty;
        final item = await svc.archiveItem(houseId, listId, id);
        return SyncResult(item);
      case SyncOpKind.unarchive:
        if (listId == null || id == null) return SyncResult.empty;
        final item = await svc.unarchiveItem(houseId, listId, id);
        return SyncResult(item);
      case SyncOpKind.reorder:
        if (listId == null) return SyncResult.empty;
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderItems(houseId, listId, order);
        return SyncResult.empty;
      case SyncOpKind.batch:
        return _executeItemBatch(svc, houseId, op);
    }
  }

  /// House-scoped group action. `body['batchAction']` selects the operation;
  /// `body['itemIds']` are the (already id-remapped) target items.
  Future<SyncResult> _executeItemBatch(
    ChecklistService svc,
    int houseId,
    SyncOp op,
  ) async {
    final action = op.body['batchAction'] as String?;
    final itemIds = (op.body['itemIds'] as List?)?.cast<int>() ?? const [];
    if (itemIds.isEmpty) return SyncResult.empty;
    switch (action) {
      case 'move':
        return SyncResult(
          await svc.batchMoveItems(
            houseId,
            itemIds: itemIds,
            targetListId: op.body['targetListId'] as int,
          ),
        );
      case 'copy':
        return SyncResult(
          await svc.batchCopyItems(
            houseId,
            itemIds: itemIds,
            targetListId: op.body['targetListId'] as int,
          ),
        );
      case 'delete':
        return SyncResult(
          await svc.batchDeleteItems(
            houseId,
            itemIds: itemIds,
            permanent: op.body['permanent'] as bool? ?? false,
          ),
        );
      case 'category':
        return SyncResult(
          await svc.batchSetCategory(
            houseId,
            itemIds: itemIds,
            categoryId: op.body['categoryId'] as int?,
          ),
        );
      case 'stores':
        return SyncResult(
          await svc.batchSetStores(
            houseId,
            itemIds: itemIds,
            storeIds: (op.body['storeIds'] as List?)?.cast<int>() ?? const [],
          ),
        );
      case 'archive':
        return SyncResult(
          await svc.batchArchiveItems(
            houseId,
            itemIds: itemIds,
            archive: op.body['archive'] as bool? ?? true,
          ),
        );
      case 'uncheck':
        return SyncResult(
          await svc.batchUncheckItems(houseId, itemIds: itemIds),
        );
      default:
        return SyncResult.empty;
    }
  }

  Future<SyncResult> _executeCategory(SyncOp op) async {
    final svc = CategoryService.instance;
    final houseId = op.houseId;
    final id = op.entityId;
    switch (op.op) {
      case SyncOpKind.create:
        final cat = await svc.createCategory(
          houseId,
          name: op.body['name'] as String,
          icon: op.body['icon'] as String,
          color: op.body['color'] as String,
          listId: op.body['listId'] as int?,
        );
        return SyncResult(cat);
      case SyncOpKind.update:
        if (id == null) return SyncResult.empty;
        // Presence is significant: `listId` absent leaves the scope alone; a
        // key present with a value (including null → global) re-scopes it.
        final cat = await svc.updateCategory(
          houseId,
          id,
          name: op.body['name'] as String?,
          icon: op.body['icon'] as String?,
          color: op.body['color'] as String?,
          listId: op.body.containsKey('listId')
              ? op.body['listId']
              : categoryListIdUnset,
        );
        return SyncResult(cat);
      case SyncOpKind.delete:
        if (id == null) return SyncResult.empty;
        await svc.deleteCategory(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.reorder:
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderCategories(houseId, order);
        return SyncResult.empty;
      case SyncOpKind.toggle:
      case SyncOpKind.restore:
      case SyncOpKind.permanentDelete:
      case SyncOpKind.emptyTrash:
      case SyncOpKind.archive:
      case SyncOpKind.unarchive:
      case SyncOpKind.batch:
        return SyncResult.empty;
    }
  }

  Future<SyncResult> _executeStore(SyncOp op) async {
    final svc = StoreService.instance;
    final houseId = op.houseId;
    final id = op.entityId;
    switch (op.op) {
      case SyncOpKind.create:
        final store = await svc.createStore(
          houseId,
          name: op.body['name'] as String,
          icon: op.body['icon'] as String,
          color: op.body['color'] as String,
          brand: op.body['brand'] as String?,
          location: op.body['location'] as String?,
          openingHours: (op.body['openingHours'] as List?)
              ?.map(
                (e) => OpeningHoursInterval.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
          contact: op.body['contact'] as String?,
          responsible: op.body['responsible'] as String?,
          notes: op.body['notes'] as String?,
        );
        return SyncResult(store);
      case SyncOpKind.update:
        if (id == null) return SyncResult.empty;
        final store = await svc.updateStore(
          houseId,
          id,
          name: op.body['name'] as String?,
          icon: op.body['icon'] as String?,
          color: op.body['color'] as String?,
          brand: op.body['brand'] as String?,
          location: op.body['location'] as String?,
          openingHours: (op.body['openingHours'] as List?)
              ?.map(
                (e) => OpeningHoursInterval.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
          contact: op.body['contact'] as String?,
          responsible: op.body['responsible'] as String?,
          notes: op.body['notes'] as String?,
        );
        return SyncResult(store);
      case SyncOpKind.delete:
        if (id == null) return SyncResult.empty;
        await svc.deleteStore(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.reorder:
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderStores(houseId, order);
        return SyncResult.empty;
      case SyncOpKind.toggle:
      case SyncOpKind.restore:
      case SyncOpKind.permanentDelete:
      case SyncOpKind.emptyTrash:
      case SyncOpKind.archive:
      case SyncOpKind.unarchive:
      case SyncOpKind.batch:
        return SyncResult.empty;
    }
  }

  Future<SyncResult> _executeNote(SyncOp op) async {
    final svc = NoteService.instance;
    final houseId = op.houseId;
    final id = op.entityId;
    switch (op.op) {
      case SyncOpKind.create:
        final note = await svc.createNote(
          houseId,
          title: op.body['title'] as String,
          content: op.body['content'] as String?,
          color: op.body['color'] as String?,
        );
        return SyncResult(note);
      case SyncOpKind.update:
        if (id == null) return SyncResult.empty;
        final note = await svc.updateNote(
          houseId,
          id,
          title: op.body['title'] as String?,
          content: op.body['content'] as String?,
          color: op.body['color'] as String?,
          isPinned: op.body['isPinned'] as bool?,
        );
        return SyncResult(note);
      case SyncOpKind.delete:
        if (id == null) return SyncResult.empty;
        await svc.deleteNote(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.restore:
        if (id == null) return SyncResult.empty;
        final note = await svc.restoreNote(houseId, id);
        return SyncResult(note);
      case SyncOpKind.permanentDelete:
        if (id == null) return SyncResult.empty;
        await svc.permanentlyDeleteNote(houseId, id);
        return SyncResult.empty;
      case SyncOpKind.emptyTrash:
        await svc.emptyNotesTrash(houseId);
        return SyncResult.empty;
      case SyncOpKind.reorder:
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderNotes(houseId, order);
        return SyncResult.empty;
      case SyncOpKind.toggle:
      case SyncOpKind.archive:
      case SyncOpKind.unarchive:
      case SyncOpKind.batch:
        return SyncResult.empty;
    }
  }
}

/// Decode a queued `prices` payload back into [ItemPrice]s. Null (the key was
/// omitted) leaves prices unchanged, so it stays null; a list — even empty —
/// is passed through so an empty array can clear all prices on update.
List<ItemPrice>? _pricesFromBody(Object? raw) {
  if (raw == null) return null;
  return (raw as List)
      .map((e) => ItemPrice.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Helpers to extract the server id from a result, used by the manager to
/// bind temp ids after a create.
int? serverIdOf(Object? entity) {
  if (entity is ChecklistList) return entity.id;
  if (entity is ListItem) return entity.id;
  if (entity is Category) return entity.id;
  if (entity is Store) return entity.id;
  if (entity is Note) return entity.id;
  return null;
}
