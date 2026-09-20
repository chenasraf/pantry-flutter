import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_core/services/api_client.dart';

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
      HttpFileService(httpClient: deferredClient());

  /// The client [fileService] is built on.
  ///
  /// Named rather than inlined because it carries two policies of its own — it
  /// defers its connection so the TLS overrides it runs under are the ones the
  /// app has by then, and it falls back to [ApiClient.relay] so a photo is not
  /// the one thing a relayed session cannot fetch.
  @visibleForTesting
  static http.Client deferredClient() => _DeferredClient();
}

/// An [http.Client] that opens its connection on the first request rather than
/// when it is constructed, so the TLS policy it runs under is the one the app
/// has by then.
///
/// It also honours [ApiClient.relay], because an image is the one thing the app
/// fetches that does not go through [ApiClient] at all — a store holds its own
/// client so that `flutter_cache_manager` can stream bytes to disk. A watch
/// whose server it has no route to would otherwise read every list and note
/// through the relay and still draw an empty photo board.
class _DeferredClient extends http.BaseClient {
  http.Client? _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await (_inner ??= http.Client()).send(request);
    } catch (e) {
      if (!_neverArrived(e)) rethrow;
      final relayed = await _viaRelay(request);
      if (relayed != null) return relayed;
      // The original failure, not a description of it: the cache manager has a
      // path for the exception it already knows and draws whatever is on disk,
      // where an unfamiliar one it logs and draws nothing.
      rethrow;
    }
  }

  /// The four ways a request fails without reaching a server — the same set
  /// [ApiClient] classifies, and the only condition another device may not
  /// share.
  static bool _neverArrived(Object e) =>
      e is SocketException ||
      e is TlsException ||
      e is http.ClientException ||
      e is TimeoutException;

  /// Ask whoever can still reach the server, and answer null when nobody can.
  ///
  /// Reads only. A body is a stream that the failed attempt has already
  /// consumed, so it could not be handed to anyone else — and an image store
  /// makes nothing but reads, which is the whole of what this seam is for.
  Future<http.StreamedResponse?> _viaRelay(http.BaseRequest request) async {
    final ask = ApiClient.relay;
    if (ask == null) return null;
    final method = request.method.toUpperCase();
    final described = ApiRequest(
      method: method,
      uri: request.url,
      headers: request.headers,
      timeout: const Duration(seconds: 30),
    );
    if (!described.isRead) return null;
    final response = await ask(described);
    if (response == null) return null;
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      contentLength: response.bodyBytes.length,
      request: request,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner?.close();
}
