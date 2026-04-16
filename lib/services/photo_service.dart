import 'package:pantry/models/photo.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  final cache = CacheStore('photo_cache.json');

  static const _photosKey = 'photos';
  static const _foldersKey = 'folders';
  static const _houseIdKey = 'houseId';
  static const _sortByKey = 'sortBy';
  static const _foldersFirstKey = 'foldersFirst';

  // -- Cache accessors --

  List<Photo>? getCachedPhotos(int houseId) {
    if (cache.get<int>(_houseIdKey) != houseId) return null;
    return cache.getList(_photosKey, Photo.fromJson);
  }

  void cachePhotos(int houseId, List<Photo> photos) {
    cache.set(_houseIdKey, houseId);
    cache.setList(_photosKey, photos, (p) => p.toJson());
  }

  List<PhotoFolder>? getCachedFolders(int houseId) {
    if (cache.get<int>(_houseIdKey) != houseId) return null;
    return cache.getList(_foldersKey, PhotoFolder.fromJson);
  }

  void cacheFolders(int houseId, List<PhotoFolder> folders) {
    cache.set(_houseIdKey, houseId);
    cache.setList(_foldersKey, folders, (f) => f.toJson());
  }

  String get cachedSortBy => cache.get<String>(_sortByKey) ?? 'custom';
  set cachedSortBy(String value) => cache.set(_sortByKey, value);

  bool get cachedFoldersFirst => cache.get<bool>(_foldersFirstKey) ?? true;
  set cachedFoldersFirst(bool value) => cache.set(_foldersFirstKey, value);

  // -- Photos --

  Future<List<Photo>> getPhotos(
    int houseId, {
    String sortBy = 'custom',
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<Photo>>(
      '/houses/$houseId/photos',
      query: {'sortBy': sortBy, 'limit': '$limit', 'offset': '$offset'},
      fromJson: (data) =>
          data.map((e) => Photo.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Photo> uploadPhoto(
    int houseId, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    int? folderId,
    String? caption,
  }) async {
    final fields = <String, String>{};
    if (folderId != null) fields['folderId'] = '$folderId';
    if (caption != null && caption.isNotEmpty) fields['caption'] = caption;

    return ApiClient.instance.uploadMultipart<Map<String, dynamic>, Photo>(
      '/houses/$houseId/photos',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      fieldName: 'image',
      fields: fields.isNotEmpty ? fields : null,
      fromJson: (data) => Photo.fromJson(data),
    );
  }

  Future<Photo> updatePhoto(
    int houseId,
    int photoId, {
    String? caption,
    int? folderId,
    bool moveToRoot = false,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, Photo>(
      '/houses/$houseId/photos/$photoId',
      body: {
        'caption': ?caption,
        if (moveToRoot) 'folderId': 0,
        if (!moveToRoot && folderId != null) 'folderId': folderId,
      },
      fromJson: (data) => Photo.fromJson(data),
    );
  }

  Future<void> deletePhoto(int houseId, int photoId) async {
    await ApiClient.instance.delete('/houses/$houseId/photos/$photoId');
  }

  Future<void> reorderPhotos(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/photos/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  Uri photoPreviewUri(int houseId, int photoId, {int size = 300}) {
    return ApiClient.instance.buildUri(
      '/houses/$houseId/photos/$photoId/preview',
      {'size': '$size'},
    );
  }

  // -- Folders --

  Future<List<PhotoFolder>> getFolders(
    int houseId, {
    String sortBy = 'custom',
  }) async {
    return ApiClient.instance.get<List, List<PhotoFolder>>(
      '/houses/$houseId/photos/folders',
      query: {'sortBy': sortBy},
      fromJson: (data) => data
          .map((e) => PhotoFolder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<PhotoFolder> createFolder(int houseId, {required String name}) async {
    return ApiClient.instance.post<Map<String, dynamic>, PhotoFolder>(
      '/houses/$houseId/photos/folders',
      body: {'name': name},
      fromJson: (data) => PhotoFolder.fromJson(data),
    );
  }

  Future<PhotoFolder> updateFolder(
    int houseId,
    int folderId, {
    String? name,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, PhotoFolder>(
      '/houses/$houseId/photos/folders/$folderId',
      body: {'name': ?name},
      fromJson: (data) => PhotoFolder.fromJson(data),
    );
  }

  Future<void> deleteFolder(
    int houseId,
    int folderId, {
    bool deleteContents = false,
  }) async {
    // deleteContents as query param
    final path = deleteContents
        ? '/houses/$houseId/photos/folders/$folderId?deleteContents=true'
        : '/houses/$houseId/photos/folders/$folderId';
    await ApiClient.instance.delete(path);
  }

  Future<void> reorderFolders(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/photos/folders/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  // -- House Prefs --

  Future<Map<String, dynamic>> getHousePrefs(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, Map<String, dynamic>>(
      '/houses/$houseId/prefs',
      fromJson: (data) => data,
    );
  }

  Future<void> setHousePrefs(
    int houseId, {
    String? photoSort,
    bool? photoFoldersFirst,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'photoSort': ?photoSort, 'photoFoldersFirst': ?photoFoldersFirst},
      fromJson: (_) {},
    );
  }
}
