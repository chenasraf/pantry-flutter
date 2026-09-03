import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// Disk cache for Nextcloud preview images, shared by the display path
/// ([AvifAwareNetworkImage]) and the background prefetcher so proactively
/// downloaded images are the exact files the UI later reads.
///
/// flutter_cache_manager's default store caps at 200 objects and evicts by
/// least-recent use; a household's photos plus per-item thumbnails overrun that
/// quickly and images disappear offline. This store raises the object cap and
/// stale window so prefetched images survive until they're genuinely stale.
class _PantryImageCacheManager extends CacheManager with ImageCacheManager {
  _PantryImageCacheManager()
    : super(
        Config(
          'pantryImageCache',
          stalePeriod: const Duration(days: 180),
          maxNrOfCacheObjects: 3000,
        ),
      );
}

class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService instance = ImageCacheService._();

  /// Backing store for both the display widgets and the prefetcher.
  final ImageCacheManager manager = _PantryImageCacheManager();

  /// Preview sizes fetched per checklist-item image: the list-row thumbnail and
  /// the full image shared by the detail cover and the fullscreen viewer.
  static const _itemSizes = [96, 2048];

  /// Preview sizes fetched per photo: the grid thumbnail and the detail view.
  static const _photoSizes = [300, 1024];

  /// Concurrent downloads during a prefetch pass, bounding load on the
  /// connection and the server's preview generator.
  static const _maxConcurrent = 4;

  bool _sweeping = false;

  Map<String, String> get _headers =>
      AuthService.instance.credentials?.basicAuthHeaders ?? const {};

  /// Prefetch preview images (thumbnail + full) for [items]. Fire-and-forget:
  /// runs only while online and never throws.
  Future<void> prefetchItems(int houseId, Iterable<ListItem> items) =>
      _run(_itemUrls(houseId, items));

  /// Prefetch preview images (thumbnail + full) for [photos]. Fire-and-forget:
  /// runs only while online and never throws.
  Future<void> prefetchPhotos(int houseId, Iterable<Photo> photos) =>
      _run(_photoUrls(houseId, photos));

  /// Download every not-yet-cached preview image for the house's offline
  /// snapshot — cached items across all lists plus cached photos — so a user
  /// who never opened each item or photo still sees them offline. Runs on load
  /// and on reconnect; already-cached images are skipped, so repeat sweeps are
  /// cheap. Guards against overlapping passes.
  Future<void> sweepHouse(int houseId) async {
    if (_sweeping || !SyncManager.instance.isOnline || _headers.isEmpty) return;
    _sweeping = true;
    try {
      final urls = <String>{};
      final lists = ChecklistService.instance.getCachedLists(houseId) ?? [];
      for (final list in lists) {
        final items = ChecklistService.instance.getCachedItems(list.id);
        if (items != null) urls.addAll(_itemUrls(houseId, items));
      }
      final photos = PhotoService.instance.getCachedPhotos(houseId);
      if (photos != null) urls.addAll(_photoUrls(houseId, photos));
      await _run(urls);
    } finally {
      _sweeping = false;
    }
  }

  Iterable<String> _itemUrls(int houseId, Iterable<ListItem> items) sync* {
    for (final item in items) {
      final fileId = item.imageFileId;
      if (fileId == null) continue;
      final owner = item.imageUploadedBy ?? '';
      for (final size in _itemSizes) {
        yield ChecklistService.instance
            .itemImagePreviewUri(houseId, fileId, owner, size: size)
            .toString();
      }
    }
  }

  Iterable<String> _photoUrls(int houseId, Iterable<Photo> photos) sync* {
    for (final photo in photos) {
      for (final size in _photoSizes) {
        yield PhotoService.instance
            .photoPreviewUri(houseId, photo.id, size: size)
            .toString();
      }
    }
  }

  /// Download [urls] with bounded concurrency, skipping any already on disk and
  /// bailing the moment connectivity drops.
  Future<void> _run(Iterable<String> urls) async {
    if (!SyncManager.instance.isOnline) return;
    final headers = _headers;
    if (headers.isEmpty) return;

    final queue = urls.toList();
    var next = 0;

    Future<void> worker() async {
      while (next < queue.length) {
        if (!SyncManager.instance.isOnline) return;
        final url = queue[next++];
        try {
          if (await manager.getFileFromCache(url) != null) continue;
          await manager.downloadFile(url, authHeaders: headers);
        } catch (e) {
          debugPrint('[ImageCacheService] prefetch failed for $url: $e');
        }
      }
    }

    await Future.wait([for (var i = 0; i < _maxConcurrent; i++) worker()]);
  }
}
