import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/note_service.dart';
import 'package:pantry/sync/sync_op.dart';

/// Result of executing a single op.
///
/// [entity] is the canonical server record (the response of the create/
/// update/restore/toggle call). Null for ops that don't return an entity
/// (delete, permanentDelete, emptyTrash, reorder).
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
      case SyncEntity.note:
        return _executeNote(op);
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
          rrule: op.body['rrule'] as String?,
          repeatFromCompletion: op.body['repeatFromCompletion'] as bool?,
          deleteOnDone: op.body['deleteOnDone'] as bool?,
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
          rrule: op.body['rrule'] as String?,
          repeatFromCompletion: op.body['repeatFromCompletion'] as bool?,
          deleteOnDone: op.body['deleteOnDone'] as bool?,
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
      case SyncOpKind.reorder:
        if (listId == null) return SyncResult.empty;
        final raw = (op.body['order'] as List).cast<Map>();
        final order = raw
            .map((e) => (id: e['id'] as int, sortOrder: e['sortOrder'] as int))
            .toList();
        await svc.reorderItems(houseId, listId, order);
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
        );
        return SyncResult(cat);
      case SyncOpKind.update:
        if (id == null) return SyncResult.empty;
        final cat = await svc.updateCategory(
          houseId,
          id,
          name: op.body['name'] as String?,
          icon: op.body['icon'] as String?,
          color: op.body['color'] as String?,
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
        return SyncResult.empty;
    }
  }
}

/// Helpers to extract the server id from a result, used by the manager to
/// bind temp ids after a create.
int? serverIdOf(Object? entity) {
  if (entity is ChecklistList) return entity.id;
  if (entity is ListItem) return entity.id;
  if (entity is Category) return entity.id;
  if (entity is Note) return entity.id;
  return null;
}
