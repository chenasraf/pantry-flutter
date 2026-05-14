import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/services/pending_photo_share_service.dart';
import 'package:pantry/services/photo_service.dart';

class UploadTask {
  final String fileName;
  final Uint8List? thumbnailBytes;
  final String mimeType;
  final int? folderId;
  double progress;
  bool done;
  String? error;
  Photo? result;

  UploadTask({
    required this.fileName,
    this.thumbnailBytes,
    this.mimeType = 'image/jpeg',
    this.folderId,
  }) : progress = 0.0,
       done = false;

  void reset() {
    progress = 0.0;
    done = false;
    error = null;
    result = null;
  }
}

class PhotoBoardController extends ChangeNotifier {
  final int houseId;

  PhotoBoardController({required this.houseId}) {
    PendingPhotoShareService.instance.addListener(_consumePendingShares);
    // Consume any shares that arrived while this controller didn't exist.
    _consumePendingShares();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    PendingPhotoShareService.instance.removeListener(_consumePendingShares);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  PhotoService get _service => PhotoService.instance;

  List<Photo> _photos = [];
  List<Photo> get photos => _photos;

  List<PhotoFolder> _folders = [];
  List<PhotoFolder> get folders => _folders;

  /// Current folder we are viewing (null = root).
  int? _currentFolderId;
  int? get currentFolderId => _currentFolderId;

  PhotoFolder? get currentFolder => _currentFolderId != null
      ? _folders.cast<PhotoFolder?>().firstWhere(
          (f) => f!.id == _currentFolderId,
          orElse: () => null,
        )
      : null;

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  bool _foldersFirst = true;
  bool get foldersFirst => _foldersFirst;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<UploadTask> _uploads = [];
  List<UploadTask> get uploads => _uploads;

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

  void toggleSelection(int photoId) {
    if (_selected.contains(photoId)) {
      _selected.remove(photoId);
    } else {
      _selected.add(photoId);
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
        await _service.deletePhoto(houseId, id);
        _photos.removeWhere((p) => p.id == id);
      } catch (e) {
        debugPrint('[PhotoBoardController] Failed to delete photo $id: $e');
      }
    }
    _selected.clear();
    _selectMode = false;
    _service.cachePhotos(houseId, _photos);
    notifyListeners();
  }

  Future<void> moveSelectedToFolder(int? folderId) async {
    final ids = Set<int>.from(_selected);
    for (final id in ids) {
      try {
        await _service.updatePhoto(
          houseId,
          id,
          folderId: folderId,
          moveToRoot: folderId == null,
        );
      } catch (e) {
        debugPrint('[PhotoBoardController] Failed to move photo $id: $e');
      }
    }
    _selected.clear();
    _selectMode = false;
    await _reloadPhotos();
  }

  /// Items visible in the current view (folders at root + photos in current folder).
  List<Photo> get visiblePhotos {
    if (_currentFolderId != null) {
      return _photos.where((p) => p.folderId == _currentFolderId).toList();
    }
    return _photos.where((p) => p.folderId == null).toList();
  }

  List<PhotoFolder> get visibleFolders {
    if (_currentFolderId != null) return [];
    return _folders;
  }

  /// Count of photos inside a folder.
  int folderPhotoCount(int folderId) =>
      _photos.where((p) => p.folderId == folderId).length;

  /// Most recent 3 photos in a folder for preview thumbnails.
  List<Photo> folderPreviewPhotos(int folderId) {
    final inFolder = _photos.where((p) => p.folderId == folderId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return inFolder.take(3).toList();
  }

  Future<void> load() async {
    _error = null;

    // Restore from cache immediately
    _restoreFromCache();

    if (_photos.isEmpty && _folders.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Load prefs first (non-fatal) to know sort order
      try {
        final prefs = await _service.getHousePrefs(houseId);
        _sortBy = prefs['photoSort'] as String? ?? 'custom';
        _foldersFirst = prefs['photoFoldersFirst'] as bool? ?? true;
        _service.cachedSortBy = _sortBy;
        _service.cachedFoldersFirst = _foldersFirst;
      } catch (e) {
        debugPrint('[PhotoBoardController] Failed to load prefs: $e');
      }

      final results = await Future.wait([
        _service.getPhotos(houseId, sortBy: _sortBy),
        _service.getFolders(houseId, sortBy: _sortBy),
      ]);

      _photos = results[0] as List<Photo>;
      _folders = results[1] as List<PhotoFolder>;
      _service.cachePhotos(houseId, _photos);
      _service.cacheFolders(houseId, _folders);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PhotoBoardController] Failed to load: $e');
      if (_photos.isEmpty && _folders.isEmpty) {
        _error = m.photoBoard.failedToLoad;
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void _restoreFromCache() {
    _sortBy = _service.cachedSortBy;
    _foldersFirst = _service.cachedFoldersFirst;

    final cachedPhotos = _service.getCachedPhotos(houseId);
    if (cachedPhotos != null && _photos.isEmpty) {
      _photos = cachedPhotos;
    }

    final cachedFolders = _service.getCachedFolders(houseId);
    if (cachedFolders != null && _folders.isEmpty) {
      _folders = cachedFolders;
    }

    if (_photos.isNotEmpty || _folders.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void enterFolder(int folderId) {
    _currentFolderId = folderId;
    notifyListeners();
  }

  void exitFolder() {
    _currentFolderId = null;
    notifyListeners();
  }

  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    notifyListeners();
    _service.setHousePrefs(houseId, photoSort: sort);
    await _reloadPhotos();
  }

  Future<void> setFoldersFirst(bool value) async {
    if (value == _foldersFirst) return;
    _foldersFirst = value;
    notifyListeners();
    _service.setHousePrefs(houseId, photoFoldersFirst: value);
  }

  Future<void> _reloadPhotos() async {
    try {
      final results = await Future.wait([
        _service.getPhotos(houseId, sortBy: _sortBy),
        _service.getFolders(houseId, sortBy: _sortBy),
      ]);
      _photos = results[0] as List<Photo>;
      _folders = results[1] as List<PhotoFolder>;
      _service.cachePhotos(houseId, _photos);
      _service.cacheFolders(houseId, _folders);
      notifyListeners();
    } catch (e) {
      debugPrint('[PhotoBoardController] Failed to reload: $e');
    }
  }

  // -- Upload --

  Future<void> uploadPhotos(List<XFile> files, {int? folderId}) async {
    final target = folderId ?? _currentFolderId;
    // Create all tasks up front with thumbnail bytes
    final tasks = <(UploadTask, XFile)>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final task = UploadTask(
        fileName: file.name,
        thumbnailBytes: bytes,
        mimeType: file.mimeType ?? 'image/jpeg',
        folderId: target,
      );
      _uploads.add(task);
      tasks.add((task, file));
    }
    notifyListeners();

    for (final (task, _) in tasks) {
      await _runUpload(task);
    }

    _cleanUpDoneUploads();
  }

  Future<void> _runUpload(UploadTask task) async {
    try {
      task.progress = 0.3;
      notifyListeners();

      final photo = await _service.uploadPhoto(
        houseId,
        bytes: task.thumbnailBytes!,
        fileName: task.fileName,
        mimeType: task.mimeType,
        folderId: task.folderId,
      );
      _photos.insert(0, photo);
      _service.cachePhotos(houseId, _photos);
      task.result = photo;
      task.progress = 1.0;
      task.done = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[PhotoBoardController] Upload failed: $e');
      task.error = e.toString();
      task.done = true;
      notifyListeners();
    }
  }

  Future<void> retryUpload(UploadTask task) async {
    task.reset();
    notifyListeners();
    await _runUpload(task);
    _cleanUpDoneUploads();
  }

  void _consumePendingShares() {
    final shares = PendingPhotoShareService.instance.takeForHouse(houseId);
    if (shares.isEmpty) return;
    for (final share in shares) {
      final files = share.paths.map((p) => XFile(p)).toList();
      uploadPhotos(files, folderId: share.folderId);
    }
  }

  void dismissUpload(UploadTask task) {
    _uploads.remove(task);
    notifyListeners();
  }

  void _cleanUpDoneUploads() {
    Future.delayed(const Duration(seconds: 2), () {
      _uploads.removeWhere((t) => t.done && t.error == null);
      notifyListeners();
    });
  }

  // -- Delete --

  Future<void> deletePhoto(Photo photo) async {
    await _service.deletePhoto(houseId, photo.id);
    _photos.removeWhere((p) => p.id == photo.id);
    _service.cachePhotos(houseId, _photos);
    notifyListeners();
  }

  // -- Move to folder --

  Future<void> movePhotoToFolder(int photoId, int? folderId) async {
    await _service.updatePhoto(
      houseId,
      photoId,
      folderId: folderId,
      moveToRoot: folderId == null,
    );
    final index = _photos.indexWhere((p) => p.id == photoId);
    if (index != -1) {
      // Reload the photo from server to get updated state
      await _reloadPhotos();
    }
  }

  // -- Caption --

  Future<void> updateCaption(Photo photo, String caption) async {
    final updated = await _service.updatePhoto(
      houseId,
      photo.id,
      caption: caption,
    );
    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index] = updated;
      _service.cachePhotos(houseId, _photos);
      notifyListeners();
    }
  }

  // -- Folders --

  Future<PhotoFolder> createFolder(String name) async {
    final folder = await _service.createFolder(houseId, name: name);
    _folders.add(folder);
    _service.cacheFolders(houseId, _folders);
    notifyListeners();
    return folder;
  }

  Future<void> renameFolder(PhotoFolder folder, String name) async {
    final updated = await _service.updateFolder(houseId, folder.id, name: name);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = updated;
      _service.cacheFolders(houseId, _folders);
      notifyListeners();
    }
  }

  Future<void> deleteFolder(
    PhotoFolder folder, {
    bool deleteContents = false,
  }) async {
    await _service.deleteFolder(
      houseId,
      folder.id,
      deleteContents: deleteContents,
    );
    _folders.removeWhere((f) => f.id == folder.id);
    _service.cacheFolders(houseId, _folders);
    if (!deleteContents) {
      // Photos moved to root — reload
      await _reloadPhotos();
    } else {
      _photos.removeWhere((p) => p.folderId == folder.id);
      _service.cachePhotos(houseId, _photos);
      notifyListeners();
    }
  }

  // -- Reorder --

  int? _draggingId;
  int? get draggingId => _draggingId;

  void startDrag(int photoId) {
    _draggingId = photoId;
    notifyListeners();
  }

  /// Called during drag when hovering over [targetId].
  /// Moves the dragged photo to that position, shifting others visually.
  void hoverReorder(int targetId) {
    if (_draggingId == null || _draggingId == targetId) return;

    final visible = visiblePhotos;
    final fromIndex = visible.indexWhere((p) => p.id == _draggingId);
    final toIndex = visible.indexWhere((p) => p.id == targetId);
    if (fromIndex == -1 || toIndex == -1) return;

    _applyVisibleOrder(visible, fromIndex, toIndex);
    notifyListeners();
  }

  /// Finalize drag — persist the current order to server.
  void endDrag() {
    if (_draggingId == null) return;
    _draggingId = null;

    final visible = visiblePhotos;
    final order = <({int id, int sortOrder})>[];
    for (var i = 0; i < visible.length; i++) {
      order.add((id: visible[i].id, sortOrder: i));
    }

    _service.cachePhotos(houseId, _photos);
    notifyListeners();
    _service.reorderPhotos(houseId, order);
  }

  void cancelDrag() {
    _draggingId = null;
    notifyListeners();
  }

  void _applyVisibleOrder(List<Photo> visible, int fromIndex, int toIndex) {
    final item = visible.removeAt(fromIndex);
    visible.insert(toIndex, item);

    final updatedOrder = <int, int>{};
    for (var i = 0; i < visible.length; i++) {
      updatedOrder[visible[i].id] = i;
    }

    _photos = _photos.map((p) {
      final newSort = updatedOrder[p.id];
      if (newSort != null) {
        return Photo(
          id: p.id,
          houseId: p.houseId,
          folderId: p.folderId,
          fileId: p.fileId,
          caption: p.caption,
          uploadedBy: p.uploadedBy,
          sortOrder: newSort,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
        );
      }
      return p;
    }).toList();
    _photos.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
