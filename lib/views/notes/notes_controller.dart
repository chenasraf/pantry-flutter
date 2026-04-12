import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/services/note_service.dart';
import 'package:pantry/services/photo_service.dart';

class NotesController extends ChangeNotifier {
  final int houseId;

  NotesController({required this.houseId});

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  NoteService get _service => NoteService.instance;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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

  Future<void> deleteSelected() async {
    final ids = Set<int>.from(_selected);
    for (final id in ids) {
      try {
        await _service.deleteNote(houseId, id);
        _notes.removeWhere((n) => n.id == id);
      } catch (e) {
        debugPrint('[NotesController] Failed to delete note $id: $e');
      }
    }
    _selected.clear();
    _selectMode = false;
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
  }

  // -- Drag reorder state --

  int? _draggingId;
  int? get draggingId => _draggingId;

  Future<void> load() async {
    _error = null;

    // Restore from cache
    _sortBy = _service.cachedSortBy;
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
        _service.cachedSortBy = _sortBy;
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
    _service.cachedSortBy = sort;
    notifyListeners();
    _service.setNoteSort(houseId, sort);
    try {
      _notes = await _service.getNotes(houseId, sortBy: _sortBy);
      _service.cacheNotes(houseId, _notes);
      notifyListeners();
    } catch (e) {
      debugPrint('[NotesController] Failed to reload: $e');
    }
  }

  // -- CRUD --

  Future<Note> addNote({
    required String title,
    String? content,
    String? color,
  }) async {
    final note = await _service.createNote(
      houseId,
      title: title,
      content: content,
      color: color,
    );
    _notes.insert(0, note);
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
    return note;
  }

  Future<Note> updateNote(
    Note note, {
    String? title,
    String? content,
    String? color,
  }) async {
    final updated = await _service.updateNote(
      houseId,
      note.id,
      title: title,
      content: content,
      color: color,
    );
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updated;
      _service.cacheNotes(houseId, _notes);
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteNote(Note note) async {
    await _service.deleteNote(houseId, note.id);
    _notes.removeWhere((n) => n.id == note.id);
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
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

    final item = _notes.removeAt(fromIndex);
    _notes.insert(toIndex, item);
    notifyListeners();
  }

  void endDrag() {
    if (_draggingId == null) return;
    _draggingId = null;

    final order = <({int id, int sortOrder})>[];
    for (var i = 0; i < _notes.length; i++) {
      order.add((id: _notes[i].id, sortOrder: i));
    }
    _service.cacheNotes(houseId, _notes);
    notifyListeners();
    _service.reorderNotes(houseId, order);
  }

  void cancelDrag() {
    _draggingId = null;
    notifyListeners();
  }
}
