import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// A long-lived [http.Client] whose connections outlive the request that
/// opened them.
///
/// package:http's top-level `get`/`post`/… build a client per call and close it
/// with the response, which costs every request its own TCP and TLS handshake
/// and leaves a socket in TIME_WAIT on the server for each one. A household
/// scrolling a photo board produces enough of those to trip a server's flood
/// protection, so every request goes through a pool instead: idle connections
/// stay open for reuse, and no more than [maxConnectionsPerHost] are open to
/// one server at a time.
///
/// API calls and image downloads get separate pools so a grid of thumbnails
/// queued behind the per-host limit never delays a save.
class HttpPool {
  HttpPool({this.maxConnectionsPerHost = 6});

  /// The pool for API and other small requests.
  static final HttpPool shared = HttpPool();

  static final _bare = _BareOverrides();

  final int maxConnectionsPerHost;

  IOClient? _client;
  HttpOverrides? _builtUnder;

  /// The client to send the next request through.
  ///
  /// Inside `http.runWithClient` this is that zone's client, so tests keep
  /// supplying responses the way package:http intends.
  ///
  /// An [HttpClient] reads [HttpOverrides] once, when it is constructed, and
  /// the overrides are what accept a user-pinned certificate. So the pool opens
  /// its client on first use rather than at construction, and opens a fresh one
  /// whenever the overrides in effect are not the ones it was built under.
  http.Client get client {
    // package:http only says whether a `runWithClient` zone supplies a client
    // by handing one out; outside such a zone that is a throwaway, built under
    // bare overrides so the app's are never consulted for a client that never
    // sends.
    final zoned = HttpOverrides.runWithHttpOverrides(http.Client.new, _bare);
    if (zoned is! IOClient) return zoned;
    zoned.close();

    final overrides = HttpOverrides.current;
    final current = _client;
    if (current != null && identical(overrides, _builtUnder)) return current;
    current?.close();
    _builtUnder = overrides;
    return _client = IOClient(
      HttpClient()..maxConnectionsPerHost = maxConnectionsPerHost,
    );
  }

  /// Close the pool's connections. The next request opens new ones.
  void close() {
    _client?.close();
    _client = null;
    _builtUnder = null;
  }
}

class _BareOverrides extends HttpOverrides {}
