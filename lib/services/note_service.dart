import 'package:pantry/models/note.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  final cache = CacheStore('note_cache.json');

  static const _notesKey = 'notes';
  static const _houseIdKey = 'houseId';
  static const _sortByKey = 'sortBy';

  // -- Cache --

  List<Note>? getCachedNotes(int houseId) {
    if (cache.get<int>(_houseIdKey) != houseId) return null;
    return cache.getList(_notesKey, Note.fromJson);
  }

  void cacheNotes(int houseId, List<Note> notes) {
    cache.set(_houseIdKey, houseId);
    cache.setList(_notesKey, notes, (n) => n.toJson());
  }

  String get cachedSortBy => cache.get<String>(_sortByKey) ?? 'custom';
  set cachedSortBy(String value) => cache.set(_sortByKey, value);

  // -- API --

  Future<List<Note>> getNotes(
    int houseId, {
    String sortBy = 'custom',
    int limit = 100,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<Note>>(
      '/houses/$houseId/notes',
      query: {'sortBy': sortBy, 'limit': '$limit', 'offset': '$offset'},
      fromJson: (data) =>
          data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Note> createNote(
    int houseId, {
    required String title,
    String? content,
    String? color,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, Note>(
      '/houses/$houseId/notes',
      body: {'title': title, 'content': ?content, 'color': ?color},
      fromJson: (data) => Note.fromJson(data),
    );
  }

  Future<Note> updateNote(
    int houseId,
    int noteId, {
    String? title,
    String? content,
    String? color,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, Note>(
      '/houses/$houseId/notes/$noteId',
      body: {'title': ?title, 'content': ?content, 'color': ?color},
      fromJson: (data) => Note.fromJson(data),
    );
  }

  Future<void> deleteNote(int houseId, int noteId) async {
    await ApiClient.instance.delete('/houses/$houseId/notes/$noteId');
  }

  Future<void> reorderNotes(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/notes/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  // -- House Prefs (reuses PhotoService.getHousePrefs pattern) --

  Future<void> setNoteSort(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'noteSort': sort},
      fromJson: (_) {},
    );
  }
}
