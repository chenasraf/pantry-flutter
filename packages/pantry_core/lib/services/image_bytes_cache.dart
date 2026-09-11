import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

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

  static ImageCacheManager Function()? _open;
  static ImageCacheManager? _opened;

  static bool get isInstalled => _open != null;

  static ImageCacheManager get manager {
    final open = _open;
    if (open == null) {
      throw StateError(
        'No image cache installed — call ImageBytesCache.install() at boot.',
      );
    }
    return _opened ??= open();
  }

  /// Register the store to read bytes from. Taken as a factory because a store
  /// opens a database and a directory over the platform channels, and boot —
  /// where the choice of store has to be made, before anything draws — is the
  /// one moment those are least likely to answer. The first image to be drawn
  /// opens it instead; nothing needs it earlier.
  static void install(ImageCacheManager Function() open) {
    _open = open;
    _opened = null;
  }

  /// The [FileService] an image store must be configured with.
  ///
  /// `flutter_cache_manager` otherwise builds its own, which opens an
  /// `HttpClient` there and then. An `HttpClient` resolves
  /// `HttpOverrides.global` once, when it is constructed, so a client that
  /// predates the overrides accepting a user-pinned certificate can never
  /// reach a self-signed server for as long as the process lives. Everything
  /// else in the app builds a client per request and is under that policy by
  /// construction; a store, which holds one, has to defer it.
  static FileService get fileService =>
      HttpFileService(httpClient: _DeferredClient());
}

/// An [http.Client] that opens its connection on the first request rather than
/// when it is constructed, so the TLS policy it runs under is the one the app
/// has by then.
class _DeferredClient extends http.BaseClient {
  http.Client? _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      (_inner ??= http.Client()).send(request);

  @override
  void close() => _inner?.close();
}
