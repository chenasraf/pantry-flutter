import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pantry_core/services/image_bytes_cache.dart';

/// The watch's own store of preview bytes.
///
/// The phone's budget is actively wrong here: 3000 objects for 180 days, filled
/// by a sweep that pulls every photo in the house at two sizes on every
/// reconnect. On a watch that is the household downloaded over a
/// Bluetooth-proxied link, paid on every launch, for the narrow case of
/// browsing photos with no phone in range.
///
/// So the watch keeps only what the wearer actually looked at — the rows that
/// were on screen, and the detail sizes of the photos they opened — and there
/// is no prefetcher. The board asks for what it is about to draw, and whatever
/// that leaves behind is what survives going offline.
class WearImageCache extends CacheManager with ImageCacheManager {
  WearImageCache._()
    : super(
        Config(
          'pantryWearImageCache',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 200,
        ),
      );

  static final WearImageCache instance = WearImageCache._();

  static void install() => ImageBytesCache.install(instance);
}
