import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../scope/wear_scope.dart';

/// One square in the board's grid: a folder, or a photo.
@immutable
class PhotoCell {
  final PhotoFolder? folder;
  final Photo? photo;

  const PhotoCell.folder(PhotoFolder this.folder) : photo = null;
  const PhotoCell.photo(Photo this.photo) : folder = null;
}

/// Everything the photos page draws.
///
/// The page is read-only, so there is no queue and no overlay: uploading,
/// captioning, reordering and folder management all stay on the phone. What is
/// left is a read, and it follows the watch's own rules — cache-first and
/// never blocking, so a board out of range shows the shape it last knew rather
/// than a spinner, and a loading state ends on a request's *outcome* rather
/// than its success.
///
/// Nothing arrives here from the phone. The mirror carries neither photo bytes
/// nor photo metadata, so unlike the checklists page this one has no snapshot
/// to listen for and fetches for itself.
class PhotosController extends ChangeNotifier {
  PhotosController();

  /// A controller holding a fixed answer, for pumping the real widget tree
  /// without a server. Nothing here polls or fetches: [setActive] is what does
  /// that, and a seeded controller is never activated.
  @visibleForTesting
  PhotosController.seeded({
    required int houseId,
    List<PhotoFolder> folders = const [],
    List<Photo> photos = const [],
    bool foldersFirst = true,
  }) {
    _houseId = houseId;
    _folders = folders;
    _photos = photos;
    _foldersFirst = foldersFirst;
    _loading = false;
  }

  final _service = PhotoService.instance;
  final _scope = WearScope.instance;

  int? _houseId;
  int? get houseId => _houseId;

  /// True when there is nothing to scope to — no house the wearer can see.
  bool get hasNoScope => _houseId == null;

  List<Photo> _photos = const [];
  List<PhotoFolder> _folders = const [];

  String _sortBy = 'custom';
  bool _foldersFirst = true;

  bool _loading = true;
  bool get isLoading => _loading;

  bool _active = false;
  bool _disposed = false;
  Timer? _poll;

  // -- What the board draws --------------------------------------------------

  /// The root of the house: folders and the photos that sit outside every one
  /// of them, in one grid, so a row may hold one of each.
  ///
  /// The order is the phone's — `photoFoldersFirst` decides which end the
  /// folders go, and the server has already sorted both by the house's
  /// `photoSort`.
  List<PhotoCell> get boardCells => [
    if (_foldersFirst) ...[for (final f in _folders) PhotoCell.folder(f)],
    for (final p in _photos)
      if (p.folderId == null) PhotoCell.photo(p),
    if (!_foldersFirst) ...[for (final f in _folders) PhotoCell.folder(f)],
  ];

  /// A folder is the same view over a smaller set, and holds no folders of its
  /// own.
  List<PhotoCell> cellsInFolder(int folderId) => [
    for (final p in _photos)
      if (p.folderId == folderId) PhotoCell.photo(p),
  ];

  int photoCount(int folderId) =>
      _photos.where((p) => p.folderId == folderId).length;

  /// The three photos a folder tile fans out, newest first — the phone's own
  /// preview.
  List<Photo> previewPhotos(int folderId) {
    final inFolder = _photos.where((p) => p.folderId == folderId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return inFolder.take(3).toList();
  }

  // -- Reading ---------------------------------------------------------------

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// Only the page on screen reads. A Dart timer keeps firing while the watch
  /// sleeps, so a board left in a pocket would poll all night.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (!active) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    unawaited(_loadFromCache().then((_) => refresh()));
    _schedulePoll();
  }

  Future<void> start() async {
    _scope.addListener(_onScopeChanged);
    await _loadFromCache();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _scope.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() {
    unawaited(_loadFromCache().then((_) => refresh()));
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!_active) return;
    final seconds = PrefsService.instance.wearPollSeconds;
    if (seconds <= 0) return;
    _poll = Timer.periodic(
      Duration(seconds: seconds),
      (_) => unawaited(refresh()),
    );
  }

  /// Everything the watch can answer without the network, so the board draws
  /// its shape immediately with whatever the last session left behind — the
  /// captions and the folders, if not always the pixels.
  Future<void> _loadFromCache() async {
    final houses = HouseService.instance.getCached() ?? const [];
    _houseId = await _scope.resolveHouse(houses) ?? _scope.houseId;
    final house = _houseId;
    if (house == null) {
      _loading = false;
      _emit();
      return;
    }
    _sortBy = _service.cachedSortBy(house);
    _foldersFirst = _service.cachedFoldersFirst(house);
    _photos = _service.getCachedPhotos(house) ?? _photos;
    _folders = _service.getCachedFolders(house) ?? _folders;
    _loading = false;
    _emit();
  }

  /// One pass over the board. Nothing here throws: a failed leg leaves the
  /// cached answer in place and the next poll tries again.
  Future<void> refresh() async {
    final house = _houseId;
    if (house == null) return;
    await _refreshPrefs(house);
    try {
      final results = await Future.wait([
        _service.getPhotos(house, sortBy: _sortBy),
        _service.getFolders(house, sortBy: _sortBy),
      ]);
      _photos = results[0] as List<Photo>;
      _folders = results[1] as List<PhotoFolder>;
      _service.cachePhotos(house, _photos);
      _service.cacheFolders(house, _folders);
    } catch (_) {
      // The shape the watch last knew is a better board than an empty one, and
      // whatever bytes it kept are still on disk under it.
    }
    _loading = false;
    _emit();
  }

  /// Sort order and folder placement are house prefs, so they arrive the way
  /// the checklist's grouping does and mean the same thing on every device. A
  /// failed read leaves the cached answer in place.
  Future<void> _refreshPrefs(int house) async {
    try {
      final prefs = await _service.getHousePrefs(house);
      _sortBy = prefs['photoSort'] as String? ?? 'custom';
      _foldersFirst = prefs['photoFoldersFirst'] as bool? ?? true;
      _service.setCachedSortBy(house, _sortBy);
      _service.setCachedFoldersFirst(house, _foldersFirst);
    } catch (_) {}
  }
}
