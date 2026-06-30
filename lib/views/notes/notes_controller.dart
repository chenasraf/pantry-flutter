import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/note_service.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

class NotesController extends ChangeNotifier {
  final int houseId;

  /// Effective capabilities for this house. Kept fresh by the view; gating is
  /// UX only (the server enforces, a 403 surfaces a snackbar).
  HousePermissions permissions = HousePermissions.unrestricted;

  NotesController({required this.houseId}) {
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
  }

  bool _disposed = false;
  StreamSubscription<SyncOpApplied>? _appliedSub;

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  NoteService get _service => NoteService.instance;
  SyncManager get _sync => SyncManager.instance;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isTrashMode = false;
  bool get isTrashMode => _isTrashMode;

  List<Note> _trashed = [];
  List<Note> get trashed => _trashed;

  // -- Selection --

  bool _selectMode = false;
  bool get selectMode => _selectMode;

  final Set<int> _selected = {};
  Set<int> get selected => _selected;

  void toggleSelectMode() {
    _selectMode = !_selectMode;
    if (!_selectMode) _selected.clear();
    notifyListeners();
  }

  void toggleSelection(int noteId) {
    if (_selected.contains(noteId)) {
      _selected.remove(noteId);
    } else {
      _selected.add(noteId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    _selectMode = false;
    notifyListeners();
  }

  Future<List<int>> deleteSelected() async {
    final ids = Set<int>.from(_selected);
    for (final id in ids) {
      _enqueueDelete(id);
    }
    _notes.removeWhere((n) => ids.contains(n.id));
    _service.cacheNotes(houseId, _notes);
    _selected.clear();
    _selectMode = false;
    notifyListeners();
    return ids.toList();
  }

  // -- Drag reorder state --

  int? _draggingId;
  int? get draggingId => _draggingId;

  Future<void> load() async {
    _error = null;

    // Restore from cache
    _sortBy = _service.cachedSortBy(houseId);
    final cached = _service.getCachedNotes(houseId);
    if (cached != null && _notes.isEmpty) {
      _notes = cached;
      _isLoading = false;
      notifyListeners();
    }

    if (_notes.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Load sort pref (non-fatal)
      try {
        final prefs = await PhotoService.instance.getHousePrefs(houseId);
        _sortBy = prefs['noteSort'] as String? ?? 'custom';
        _service.setCachedSortBy(houseId, _sortBy);
      } catch (e) {
        debugPrint('[NotesController] Failed to load prefs: $e');
      }

      _notes = await _service.getNotes(houseId, sortBy: _sortBy);
      _service.cacheNotes(houseId, _notes);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotesController] Failed to load: $e');
      if (_notes.isEmpty) {
        _error = m.notesWall.failedToLoad;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => load();

  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    _service.setCachedSortBy(houseId, sort);
    notifyListeners();
    unawaited(_service.setNoteSort(houseId, sort).catchError((_) {}));
    try {
      _notes = await _service.getNotes(houseId, sortBy: _sortBy);
      _service.cacheNotes(houseId, _notes);
      notifyListeners();
    } catch (e) {
      debugPrint('[NotesController] Failed to reload: $e');
    }
  }

  // -- CRUD --

  int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<Note> addNote({
    required String title,
    String? content,
    String? color,
  }) async {
    final tempId = _sync.newTempId();
    final synthetic = Note(
      id: tempId,
      houseId: houseId,
      title: title,
      content: content,
      color: color,
      createdBy: AuthService.instance.credentials?.loginName ?? '',
      sortOrder: _notes.length,
      isPinned: false,
      createdAt: _now(),
      updatedAt: _now(),
    );
    final firstUnpinned = _notes.indexWhere((n) => !n.isPinned);
    _notes.insert(
      firstUnpinned == -1 ? _notes.length : firstUnpinned,
      synthetic,
    );
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.create,
        houseId: houseId,
        tempEntityId: tempId,
        body: {'title': title, 'content': ?content, 'color': ?color},
        createdAt: _now(),
      ),
    );
    return synthetic;
  }

  Future<Note> updateNote(
    Note note, {
    String? title,
    String? content,
    String? color,
    bool? isPinned,
  }) async {
    final updated = note.copyWith(
      title: title,
      content: content,
      color: color,
      isPinned: isPinned,
      updatedAt: _now(),
    );
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      if (isPinned != null) {
        _notes = _sortPinnedFirst(_notes);
      }
      _service.cacheNotes(houseId, _notes);
      notifyListeners();
    }
    _sync.enqueue(_buildUpdate(note, title, content, color, isPinned));
    return updated;
  }

  SyncOp _buildUpdate(
    Note note,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
  ) {
    final isTemp = note.id < 0;
    return SyncOp(
      uuid: SyncIds.newOpUuid(),
      entity: SyncEntity.note,
      op: SyncOpKind.update,
      houseId: houseId,
      entityId: isTemp ? null : note.id,
      tempEntityId: isTemp ? note.id : null,
      body: {
        'title': ?title,
        'content': ?content,
        'color': ?color,
        'isPinned': ?isPinned,
      },
      createdAt: _now(),
    );
  }

  Future<Note> togglePin(Note note) =>
      updateNote(note, isPinned: !note.isPinned);

  List<Note> _sortPinnedFirst(List<Note> notes) {
    final pinned = <Note>[];
    final unpinned = <Note>[];
    for (final n in notes) {
      (n.isPinned ? pinned : unpinned).add(n);
    }
    return [...pinned, ...unpinned];
  }

  Future<void> deleteNote(Note note) async {
    _notes.removeWhere((n) => n.id == note.id);
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
    _enqueueDelete(note.id);
  }

  void _enqueueDelete(int id) {
    final isTemp = id < 0;
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.delete,
        houseId: houseId,
        entityId: isTemp ? null : id,
        tempEntityId: isTemp ? id : null,
        createdAt: _now(),
      ),
    );
  }

  // -- Trash --

  Future<void> setTrashMode(bool enabled) async {
    if (_isTrashMode == enabled) return;
    _isTrashMode = enabled;
    if (enabled) {
      _trashed = [];
      _isLoading = true;
      notifyListeners();
      await _loadTrash();
    } else {
      _trashed = [];
      notifyListeners();
    }
  }

  Future<void> _loadTrash() async {
    try {
      final list = await _service.getDeletedNotes(houseId);
      if (!_isTrashMode) return;
      _trashed = list;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotesController] Failed to load trash: $e');
      if (!_isTrashMode) return;
      _error = m.notesWall.failedToLoadTrash;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrash() => _loadTrash();

  Future<void> restoreNote(Note note) async {
    _trashed.removeWhere((n) => n.id == note.id);
    if (!_isTrashMode) {
      _notes = _sortPinnedFirst([..._notes, note]);
      _service.cacheNotes(houseId, _notes);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.restore,
        houseId: houseId,
        entityId: note.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> permanentlyDeleteNote(Note note) async {
    _trashed.removeWhere((n) => n.id == note.id);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.permanentDelete,
        houseId: houseId,
        entityId: note.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> emptyTrash() async {
    if (_isTrashMode) {
      _trashed = [];
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.emptyTrash,
        houseId: houseId,
        createdAt: _now(),
      ),
    );
  }

  // -- Drag reorder --

  void startDrag(int noteId) {
    _draggingId = noteId;
    notifyListeners();
  }

  void hoverReorder(int targetId) {
    if (_draggingId == null || _draggingId == targetId) return;
    final fromIndex = _notes.indexWhere((n) => n.id == _draggingId);
    final toIndex = _notes.indexWhere((n) => n.id == targetId);
    if (fromIndex == -1 || toIndex == -1) return;
    if (_notes[fromIndex].isPinned != _notes[toIndex].isPinned) return;

    final item = _notes.removeAt(fromIndex);
    _notes.insert(toIndex, item);
    notifyListeners();
  }

  bool canDropOn(int targetId) {
    if (_draggingId == null || _draggingId == targetId) return false;
    final from = _notes.firstWhere(
      (n) => n.id == _draggingId,
      orElse: () => _notes.first,
    );
    final to = _notes.firstWhere(
      (n) => n.id == targetId,
      orElse: () => _notes.first,
    );
    return from.isPinned == to.isPinned;
  }

  void endDrag() {
    if (_draggingId == null) return;
    _draggingId = null;

    final order = <Map<String, int>>[];
    for (var i = 0; i < _notes.length; i++) {
      order.add({'id': _notes[i].id, 'sortOrder': i});
    }
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.note,
        op: SyncOpKind.reorder,
        houseId: houseId,
        body: {'order': order},
        createdAt: _now(),
      ),
    );
  }

  void cancelDrag() {
    _draggingId = null;
    notifyListeners();
  }

  // -- Sync callback --

  void _onSyncApplied(SyncOpApplied applied) {
    if (applied.op.entity != SyncEntity.note) return;
    final entity = applied.entity;
    if (entity is Note) {
      final tempId = applied.op.tempEntityId;
      if (tempId != null) {
        final i = _notes.indexWhere((n) => n.id == tempId);
        if (i != -1) {
          _notes[i] = entity;
          _service.cacheNotes(houseId, _notes);
          notifyListeners();
          return;
        }
      }
      final j = _notes.indexWhere((n) => n.id == entity.id);
      if (j != -1) {
        _notes[j] = entity;
        _service.cacheNotes(houseId, _notes);
        notifyListeners();
      }
    }
  }
}
