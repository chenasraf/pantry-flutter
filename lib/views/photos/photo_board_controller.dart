import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry/services/image_cache_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/pending_photo_share_service.dart';
import 'package:pantry_core/services/pending_upload_store.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

class UploadTask {
  final String fileName;
  final String mimeType;
  final int? folderId;

  /// The image, while it is in flight. Released once the upload is handed to
  /// the sync queue, which may hold it for days — a trip's worth of
  /// full-resolution captures resident at once is the difference between a
  /// waiting upload and a dead app.
  Uint8List? thumbnailBytes;

  /// The queue's copy of the image, once there is one. The tile draws from it
  /// instead of from memory, and a retry reads it back.
  File? pendingFile;

  /// The queued op that owes this upload, once it has been handed over. A
  /// queued task waits on connectivity rather than on a request in flight, so
  /// it draws as pending and the sync queue — not a tap — retries it.
  String? opUuid;

  double progress;
  bool done;
  String? error;
  Photo? result;

  UploadTask({
    required this.fileName,
    this.thumbnailBytes,
    this.mimeType = 'image/jpeg',
    this.folderId,
    this.opUuid,
    this.pendingFile,
  }) : progress = 0.0,
       done = false;

  bool get isQueued => opUuid != null;

  void reset() {
    progress = 0.0;
    done = false;
    error = null;
    result = null;
    opUuid = null;
  }
}

class PhotoBoardController extends ChangeNotifier {
  final int houseId;

  /// Effective capabilities for this house. Kept fresh by the view; gating is
  /// UX only (the server enforces, a 403 surfaces a toast).
  HousePermissions permissions = HousePermissions.unrestricted;

  PhotoBoardController({required this.houseId}) {
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
    _skippedSub = SyncManager.instance.onSkipped.listen(_onSyncSkipped);
    unawaited(_adoptQueuedUploads());
    PendingPhotoShareService.instance.addListener(_consumePendingShares);
    // Consume any shares that arrived while this controller didn't exist.
    _consumePendingShares();
  }

  bool _disposed = false;
  StreamSubscription<SyncOpApplied>? _appliedSub;
  StreamSubscription<SyncOpSkipped>? _skippedSub;

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
    _skippedSub?.cancel();
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

  bool _isTrashMode = false;
  bool get isTrashMode => _isTrashMode;

  List<Photo> _trashed = [];
  List<Photo> get trashed => _trashed;

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

  Future<List<int>> deleteSelected() async {
    final ids = Set<int>.from(_selected);
    final deleted = <int>[];
    for (final id in ids) {
      try {
        await _service.deletePhoto(houseId, id);
        _photos.removeWhere((p) => p.id == id);
        deleted.add(id);
      } catch (e) {
        debugPrint('[PhotoBoardController] Failed to delete photo $id: $e');
      }
    }
    _selected.clear();
    _selectMode = false;
    _service.cachePhotos(houseId, _photos);
    notifyListeners();
    return deleted;
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
      return photos.where((p) => p.folderId == _currentFolderId).toList();
    }
    return photos.where((p) => p.folderId == null).toList();
  }

  List<PhotoFolder> get visibleFolders {
    if (_currentFolderId != null) return [];
    return _folders;
  }

  int folderPhotoCount(int folderId) =>
      _photos.where((p) => p.folderId == folderId).length;

  /// The first 3 photos of a folder, for the tile's preview stack. Ordered the
  /// way [visiblePhotos] orders the folder once opened — `_photos` is held in
  /// the board's sort order — so the stack shows the photos the folder leads
  /// with under any sort, not the newest ones under all of them.
  List<Photo> folderPreviewPhotos(int folderId) =>
      photos.where((p) => p.folderId == folderId).take(3).toList();

  Future<void> load() async {
    _error = null;

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
        _service.setCachedSortBy(houseId, _sortBy);
        _service.setCachedFoldersFirst(houseId, _foldersFirst);
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
      unawaited(ImageCacheService.instance.prefetchPhotos(houseId, _photos));

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
    _sortBy = _service.cachedSortBy(houseId);
    _foldersFirst = _service.cachedFoldersFirst(houseId);

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
    _service.setCachedSortBy(houseId, sort);
    notifyListeners();
    unawaited(
      _service.setHousePrefs(houseId, photoSort: sort).catchError((_) {}),
    );
    await _reloadPhotos();
  }

  Future<void> setFoldersFirst(bool value) async {
    if (value == _foldersFirst) return;
    _foldersFirst = value;
    _service.setCachedFoldersFirst(houseId, value);
    notifyListeners();
    unawaited(
      _service
          .setHousePrefs(houseId, photoFoldersFirst: value)
          .catchError((_) {}),
    );
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
      unawaited(ImageCacheService.instance.prefetchPhotos(houseId, _photos));
      notifyListeners();
    } catch (e) {
      debugPrint('[PhotoBoardController] Failed to reload: $e');
    }
  }

  // -- Upload --

  Future<void> uploadPhotos(List<XFile> files, {int? folderId}) async {
    final target = folderId ?? _currentFolderId;
    // Create all tasks up front with thumbnail bytes
    final tasks = <UploadTask>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final task = UploadTask(
        fileName: file.name,
        thumbnailBytes: bytes,
        mimeType: file.mimeType ?? 'image/jpeg',
        folderId: target,
      );
      _uploads.add(task);
      tasks.add(task);
    }
    notifyListeners();

    for (final task in tasks) {
      await _runUpload(task);
    }

    final queued = tasks.where((t) => t.isQueued).length;
    if (queued > 0) {
      showAppToast(message: m.photoBoard.queuedOffline(queued));
    }

    _cleanUpDoneUploads();
  }

  Future<void> _runUpload(UploadTask task) async {
    final bytes = task.thumbnailBytes;
    if (bytes == null) {
      task.error = 'missing bytes';
      task.done = true;
      notifyListeners();
      return;
    }
    if (!SyncManager.instance.isOnline) {
      await _queueUpload(task, bytes);
      return;
    }
    try {
      task.progress = 0.3;
      notifyListeners();

      final photo = await _service.uploadPhoto(
        houseId,
        bytes: bytes,
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
    } on OfflineException {
      // The link died mid-upload. The picture is already taken and the capture
      // it came from is a cache file the OS will reclaim, so hand the bytes to
      // the queue rather than asking for a shot that can't be taken again.
      await _queueUpload(task, bytes);
    } catch (e) {
      debugPrint('[PhotoBoardController] Upload failed: $e');
      task.error = e.toString();
      task.done = true;
      notifyListeners();
    }
  }

  /// Park [bytes] on disk and queue the upload, so it drains the moment the
  /// server is reachable again — this session or a later one.
  Future<void> _queueUpload(UploadTask task, Uint8List bytes) async {
    final uuid = SyncIds.newOpUuid();
    try {
      await PendingUploadStore.instance.save(uuid, bytes);
    } catch (e) {
      debugPrint('[PhotoBoardController] Failed to stash photo bytes: $e');
      task.error = e.toString();
      task.done = true;
      notifyListeners();
      return;
    }
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: uuid,
        entity: SyncEntity.photo,
        op: SyncOpKind.create,
        houseId: houseId,
        tempEntityId: SyncManager.instance.newTempId(),
        body: {
          'fileName': task.fileName,
          'mimeType': task.mimeType,
          if (task.folderId != null) 'folderId': task.folderId,
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    task.opUuid = uuid;
    task.pendingFile = await PendingUploadStore.instance.fileFor(uuid);
    task.thumbnailBytes = null;
    task.progress = 0.0;
    task.done = false;
    task.error = null;
    notifyListeners();
  }

  /// Re-adopt uploads the queue is still holding — from an earlier session, or
  /// from a board that was closed while they waited. Without this a photo taken
  /// offline vanishes from the grid on relaunch even though its bytes are safe
  /// on disk and still owed to the server.
  Future<void> _adoptQueuedUploads() async {
    for (final op in SyncManager.instance.pendingPhotoUploads(houseId)) {
      if (_disposed) return;
      if (_uploads.any((t) => t.opUuid == op.uuid)) continue;
      final file = await PendingUploadStore.instance.fileFor(op.uuid);
      if (_disposed) return;
      _uploads.add(
        UploadTask(
          fileName: op.body['fileName'] as String? ?? '',
          mimeType: op.body['mimeType'] as String? ?? 'image/jpeg',
          folderId: op.body['folderId'] as int?,
          opUuid: op.uuid,
          pendingFile: file,
        ),
      );
      notifyListeners();
    }
  }

  void _onSyncApplied(SyncOpApplied e) {
    if (e.op.entity != SyncEntity.photo || e.op.houseId != houseId) return;
    _uploads.removeWhere((t) => t.opUuid == e.op.uuid);
    final photo = e.entity;
    if (photo is Photo && !_photos.any((p) => p.id == photo.id)) {
      _photos.insert(0, photo);
      _service.cachePhotos(houseId, _photos);
    }
    notifyListeners();
  }

  void _onSyncSkipped(SyncOpSkipped e) {
    if (e.op.entity != SyncEntity.photo || e.op.houseId != houseId) return;
    final task = _uploads.cast<UploadTask?>().firstWhere(
      (t) => t!.opUuid == e.op.uuid,
      orElse: () => null,
    );
    if (task == null) return;
    // The queue has given up, but the bytes outlive the op: the tile stays on
    // the board as a failed upload the user can retry, rather than the photo
    // disappearing without a word — which is the whole complaint.
    task.opUuid = null;
    task.error = e.reason;
    task.done = true;
    notifyListeners();
  }

  Future<void> retryUpload(UploadTask task) async {
    final stale = task.pendingFile;
    if (task.thumbnailBytes == null && stale != null) {
      try {
        if (await stale.exists()) {
          task.thumbnailBytes = await stale.readAsBytes();
        }
        // A retry re-queues under a fresh op if it has to, so the abandoned
        // op's blob is nobody's once its bytes are back in hand.
        await stale.delete();
      } catch (e) {
        debugPrint('[PhotoBoardController] Failed to reclaim queued bytes: $e');
      }
      task.pendingFile = null;
    }
    task.reset();
    notifyListeners();
    await _runUpload(task);
    if (task.isQueued) {
      showAppToast(message: m.photoBoard.queuedOffline(1));
    }
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

  // -- Delete / Trash --

  Future<void> deletePhoto(Photo photo) async {
    await _service.deletePhoto(houseId, photo.id);
    _photos.removeWhere((p) => p.id == photo.id);
    _service.cachePhotos(houseId, _photos);
    notifyListeners();
  }

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
      final list = await _service.getDeletedPhotos(houseId);
      if (!_isTrashMode) return;
      _trashed = list;
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[PhotoBoardController] Failed to load trash: $e');
      if (!_isTrashMode) return;
      _error = m.photoBoard.failedToLoadTrash;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrash() => _loadTrash();

  Future<void> restorePhoto(Photo photo) async {
    final restored = await _service.restorePhoto(houseId, photo.id);
    _trashed.removeWhere((p) => p.id == photo.id);
    if (!_isTrashMode) {
      _photos.insert(0, restored);
      _service.cachePhotos(houseId, _photos);
    }
    notifyListeners();
  }

  Future<void> permanentlyDeletePhoto(Photo photo) async {
    await _service.permanentlyDeletePhoto(houseId, photo.id);
    _trashed.removeWhere((p) => p.id == photo.id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    await _service.emptyPhotosTrash(houseId);
    if (_isTrashMode) {
      _trashed = [];
      notifyListeners();
    }
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

  /// Whether a drag can say anything. `sort_order` is only what the board is
  /// read by under the custom sort; under any other the server answers by date
  /// or caption, so a drag would be undone by the next load.
  bool get canReorder => _sortBy == 'custom';

  /// Whether the photo the user is holding has actually landed somewhere else.
  /// A lift that ends where it started owes the server nothing.
  bool _dragMoved = false;

  void startDrag(int photoId) {
    if (!canReorder) return;
    _draggingId = photoId;
    _dragMoved = false;
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

  /// Finalize drag — hand the new order to the queue.
  ///
  /// Queued rather than sent direct: the drag is the only record of what the
  /// user arranged, and a board that keeps showing an order the server never
  /// heard about is the same as having lost it.
  void endDrag() {
    if (_draggingId == null) return;
    _draggingId = null;
    if (!_dragMoved) {
      notifyListeners();
      return;
    }
    _dragMoved = false;

    _service.cachePhotos(houseId, _photos);
    notifyListeners();
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.photo,
        op: SyncOpKind.reorder,
        houseId: houseId,
        body: {
          'order': [
            for (var i = 0; i < _photos.length; i++)
              {'id': _photos[i].id, 'sortOrder': i},
          ],
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void cancelDrag() {
    _draggingId = null;
    _dragMoved = false;
    notifyListeners();
  }

  /// Re-slot the dragged photo and renumber the whole house.
  ///
  /// `sort_order` is one space across the house, not one per folder: numbering
  /// a folder's photos 0..n on their own hands them slots the photos outside it
  /// already hold, and the two orders then depend on which row the server reads
  /// first. Only the dragged photo moves; every other photo keeps its place.
  void _applyVisibleOrder(List<Photo> visible, int fromIndex, int toIndex) {
    final dragged = visible.removeAt(fromIndex);
    visible.insert(toIndex, dragged);

    final predecessor = toIndex > 0 ? visible[toIndex - 1] : null;
    final successor = toIndex < visible.length - 1
        ? visible[toIndex + 1]
        : null;

    final rest = [
      for (final p in _photos)
        if (p.id != dragged.id) p,
    ];
    final int insertAt;
    if (predecessor != null) {
      insertAt = rest.indexWhere((p) => p.id == predecessor.id) + 1;
    } else if (successor != null) {
      insertAt = rest.indexWhere((p) => p.id == successor.id);
    } else {
      // Alone in its folder — nothing to sit beside, so nothing moves.
      return;
    }
    rest.insert(insertAt, dragged);
    _dragMoved = true;

    _photos = [
      for (var i = 0; i < rest.length; i++) rest[i].copyWith(sortOrder: i),
    ];
  }
}
