import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The disk store the AVIF-aware image providers read their bytes from.
///
/// Decoding is the same policy everywhere — sniff the bytes, hand AVIF to
/// `flutter_avif` and everything else to Flutter — so it lives in core. The
/// budget is not: a phone keeps thousands of objects for months and prefetches
/// a whole house into them, where a watch keeps what the wearer actually
/// looked at. So core owns the provider and each form factor installs the
/// store behind it.
///
/// Nothing falls back to `flutter_cache_manager`'s own default: its 200-object
/// store is neither budget, and inheriting it silently is exactly the drift
/// this seam exists to prevent.
class ImageBytesCache {
  const ImageBytesCache._();

  static ImageCacheManager? _installed;

  static bool get isInstalled => _installed != null;

  static ImageCacheManager get manager {
    final manager = _installed;
    if (manager == null) {
      throw StateError(
        'No image cache installed — call ImageBytesCache.install() at boot.',
      );
    }
    return manager;
  }

  static void install(ImageCacheManager manager) => _installed = manager;
}
