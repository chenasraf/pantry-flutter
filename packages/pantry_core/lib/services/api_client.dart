import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when a request never reached the server — the socket failed, the
/// name did not resolve, or the wall-clock budget ran out.
///
/// Offline is a property of the *request*, not of the network interface: a
/// Bluetooth-proxied watch has no interface of its own and reaches the server
/// fine, while a phone on a captive Wi-Fi has one and reaches nothing. Carries
/// statusCode 0 so the sync queue treats it as retryable and spends no budget
/// on it.
class OfflineException extends ApiException {
  const OfflineException([String message = 'Server unreachable'])
    : super(0, message);
}

/// Thrown when the TLS handshake failed because this device has not accepted
/// the server's certificate.
///
/// An [OfflineException] by inheritance, and deliberately so: a server this
/// device refuses to talk to is unreachable for every purpose a caller has, so
/// the cache-first reads and the sync queue both want exactly the behaviour
/// they already have for a dead socket — fall back to the cache, hold the
/// queue, spend no retry budget. Dropping into the queue's generic failure
/// path instead would dead-letter the wearer's changes over a server that is
/// running and correct.
///
/// What the subclass adds is [hostKey], because the decision is answerable:
/// the phone's login screen asks it and the watch's sign-in asks it, and
/// neither can ask about a host it was not told.
class CertUntrustedException extends OfflineException {
  /// `host[:port]`, as [CertTrustService.hostKey] spells it.
  final String hostKey;

  /// The handshake failure verbatim, so this still answers to
  /// [CertTrustService.isHandshakeFailure] — the surfaces that offer a
  /// fingerprint recognise the failure by its message, and one of them sits
  /// behind a layer that wraps what it catches.
  const CertUntrustedException(
    this.hostKey, [
    super.message = 'HandshakeException',
  ]);
}

/// One request, described rather than performed.
///
/// A request already wrapped in a closure has nothing left to say about itself,
/// and a closure is not something another device can be asked to run. This is
/// what lets a failure be acted on instead of only reported: the only thing
/// that can rescue a request this device has no route for is a device that can
/// be told what to send.
class ApiRequest {
  /// Upper-case, as HTTP spells it.
  final String method;
  final Uri uri;
  final Map<String, String> headers;

  /// Body bytes, or null for a request carrying none. Bytes rather than a
  /// string because an upload is bytes and a JSON body is bytes of UTF-8 — one
  /// shape, which also means a multipart body crosses the link as itself
  /// rather than as a stream nothing on the far side could rebuild.
  final List<int>? body;

  final Duration timeout;

  const ApiRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.timeout,
    this.body,
  });

  /// Whether performing this again, after it already reached a server once,
  /// would be safe.
  ///
  /// Only ever asked about a request that failed without an answer, where the
  /// alternative is losing the wearer's change. A read is trivially safe; the
  /// writes this app makes are addressed at a row and carry the whole value,
  /// so repeating one sets the same field to the same thing. A create is the
  /// exception — it is the one verb whose repetition is a second row — which is
  /// why the queue's own at-least-once contract, and not this, is what the
  /// server arbitrates.
  bool get isRead => method == 'GET' || method == 'HEAD';
}

/// How a server answered a conditional GET.
enum ConditionalOutcome {
  /// A body came back — either it changed, or there was no token to compare
  /// against.
  changed,

  /// `304 Not Modified`: what the caller already holds is current, and nothing
  /// but headers crossed the wire.
  unchanged,

  /// `204 No Content`: the resource is empty. Nextcloud's notifications
  /// endpoint answers this way rather than sending an empty list.
  empty,
}

/// The result of [ApiClient.getConditional], carrying the token to send with
/// the next request for the same resource.
class ConditionalResponse<T> {
  final ConditionalOutcome outcome;

  /// Set only when [outcome] is [ConditionalOutcome.changed].
  final T? data;

  /// The server's `ETag`, or null if it sent none — in which case the next
  /// request is an ordinary unconditional GET.
  final String? etag;

  const ConditionalResponse({required this.outcome, this.data, this.etag});
}

class ApiClient {
  final String basePath;

  /// Creates a client for the given base path (appended to the server URL
  /// from [AuthService]). Use [ApiClient.instance] for the default Pantry
  /// endpoint.
  const ApiClient({required this.basePath});

  /// Default Pantry app API client.
  static const ApiClient instance = ApiClient(
    basePath: '/ocs/v2.php/apps/pantry/api',
  );

  /// Wall-clock budget for a single request. Without it an unreachable server
  /// (socket hangs rather than failing fast) would block the future forever, so
  /// the caller's cache-fallback path never runs and the UI spins.
  static const _timeout = Duration(seconds: 15);

  /// More generous budget than [_timeout] since uploads legitimately take
  /// longer, while still bailing on an unreachable server.
  static const _uploadTimeout = Duration(seconds: 60);

  /// Invoked on any `403 Forbidden`, regardless of verb or call site. Registered
  /// once at startup to surface a single "you don't have permission" snackbar —
  /// the safety net for roles that changed mid-session after the UI was gated.
  static void Function()? onForbidden;

  /// Asked to make a request this device could not get to a server, returning
  /// the answer it got or null when it could not help either.
  ///
  /// Null on every device that is the one holding the network. Only a watch
  /// installs one, at its entrypoint: a watch linked over Bluetooth is handed
  /// the phone's *internet* and not the phone's *network*, so a household
  /// server on the wearer's own LAN is unreachable across a perfectly healthy
  /// link — and the phone beside it is the only device with a route.
  ///
  /// A hook rather than a call, because the half that performs the request is
  /// the phone app and core cannot see it. Unset, there is no second path for
  /// anything to go wrong on.
  static Future<http.Response?> Function(ApiRequest request)? relay;

  /// Every response passes through here so a `401` and the success that
  /// disproves it are observed at the same point. The state itself lives on
  /// [AuthService], beside the credential it describes.
  static void _notify(int statusCode) {
    if (statusCode == 403) onForbidden?.call();
    if (statusCode == 401) {
      AuthService.instance.reportUnauthorized();
    } else if (statusCode < 400) {
      AuthService.instance.reportAuthorized();
    }
  }

  NextcloudCredentials get _credentials {
    final creds = AuthService.instance.credentials;
    if (creds == null) throw StateError('Not authenticated');
    return creds;
  }

  /// Performs [request] and reports what came back, so the app's notion of
  /// online is the outcome of a real request rather than a reading of the
  /// platform's interfaces.
  ///
  /// A transport failure becomes an [OfflineException] here rather than
  /// reaching callers raw: cache-first reads and the sync queue both branch on
  /// it, and neither can be asked to know that `ClientException` is what an
  /// Android socket says when a watch walks out of range.
  ///
  /// Every arm that classifies a failure first offers the request to [relay],
  /// because all four of them mean the same thing — *this never reached a
  /// server* — and that is exactly the condition another device may not share.
  Future<http.Response> _send(ApiRequest request) async {
    try {
      final response = await _perform(request);
      _reachable();
      return response;
    } on TlsException catch (e) {
      // A refused certificate is neither a socket failure nor an HTTP one, so
      // it reaches here as itself — `package:http` wraps `SocketException` and
      // `HttpException` and passes everything else through. Left uncaught it
      // would travel to callers raw, leaving the app believing it is online
      // while the queue burned its retry budget on a handshake no number of
      // attempts can change.
      final relayed = await _relay(request);
      if (relayed != null) return relayed;
      final host = _hostKey;
      SyncManager.instance.setOnline(false);
      CertTrustService.instance.reportUntrusted(host);
      throw CertUntrustedException(host, e.toString());
    } on SocketException catch (e) {
      final relayed = await _relay(request);
      if (relayed != null) return relayed;
      SyncManager.instance.setOnline(false);
      throw OfflineException(e.message);
    } on http.ClientException catch (e) {
      final relayed = await _relay(request);
      if (relayed != null) return relayed;
      SyncManager.instance.setOnline(false);
      throw OfflineException(e.message);
    } on TimeoutException {
      // A server that accepts the connection and then says nothing inside the
      // budget is unreachable for every purpose the caller has.
      final relayed = await _relay(request);
      if (relayed != null) return relayed;
      SyncManager.instance.setOnline(false);
      throw const OfflineException('Request timed out');
    }
  }

  /// A server answered, which disproves every standing claim that none would.
  void _reachable() {
    SyncManager.instance.setOnline(true);
    CertTrustService.instance.reportReachable();
  }

  /// Hand [request] to whoever can still reach the server, or null when nobody
  /// can.
  ///
  /// A relayed answer is reported exactly as a direct one: the server *was*
  /// reached, and a caller that branches on being offline would otherwise fall
  /// back to a cache while holding a fresh response. The same goes for the
  /// certificate — the handshake succeeded somewhere, so leaving a refusal
  /// standing would put a *Server not verified* notice above working data.
  Future<http.Response?> _relay(ApiRequest request) async {
    final ask = relay;
    if (ask == null) return null;
    try {
      final response = await ask(request);
      if (response == null) return null;
      _reachable();
      return response;
    } catch (e) {
      // A relay that throws is a relay that did not deliver, and the direct
      // failure it was asked to rescue is the honest answer to give back.
      debugPrint('[ApiClient] relay failed: $e');
      return null;
    }
  }

  Future<http.Response> _perform(ApiRequest r) {
    final body = r.body;
    return switch (r.method) {
      'GET' => http.get(r.uri, headers: r.headers).timeout(r.timeout),
      'POST' =>
        http.post(r.uri, headers: r.headers, body: body).timeout(r.timeout),
      'PUT' =>
        http.put(r.uri, headers: r.headers, body: body).timeout(r.timeout),
      'PATCH' =>
        http.patch(r.uri, headers: r.headers, body: body).timeout(r.timeout),
      'DELETE' =>
        http.delete(r.uri, headers: r.headers, body: body).timeout(r.timeout),
      _ => throw ArgumentError('Unsupported method ${r.method}'),
    };
  }

  /// Which server the failure above was against. Every request this client
  /// makes goes to the one [_uri] builds from, so the host is the session's
  /// rather than the call's — and it is read defensively, because a sign-out
  /// racing an in-flight request must not replace the failure with a
  /// [StateError] about the credential it no longer has.
  String get _hostKey {
    final url = AuthService.instance.credentials?.serverUrl;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url ?? '';
    final isHttps = uri.scheme != 'http';
    return CertTrustService.hostKey(
      uri.host,
      uri.hasPort ? uri.port : (isHttps ? 443 : 80),
      isHttps: isHttps,
    );
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(_credentials.serverUrl);
    final prefix = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: '$prefix$basePath$path',
      queryParameters: queryParameters,
    );
  }

  Map<String, String> get _headers => {
    ..._credentials.basicAuthHeaders,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<T> get<D, T>(
    String path, {
    Map<String, String>? query,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(
      ApiRequest(
        method: 'GET',
        uri: _uri(path, query),
        headers: _headers,
        timeout: _timeout,
      ),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  /// A GET the server may answer with "unchanged" instead of a body, given the
  /// [etag] it handed out for the copy the caller already holds. Callers that
  /// keep the previous result — and can say what to do when it is still good —
  /// spend a few headers per poll instead of a full download.
  Future<ConditionalResponse<T>> getConditional<D, T>(
    String path, {
    Map<String, String>? query,
    String? etag,
    required T Function(D data) fromJson,
  }) async {
    final headers = {..._headers, 'If-None-Match': ?etag};
    final response = await _send(
      ApiRequest(
        method: 'GET',
        uri: _uri(path, query),
        headers: headers,
        timeout: _timeout,
      ),
    );
    _notify(response.statusCode);
    // A 304 carries no ETag of its own on some servers; the one the caller sent
    // still describes what it holds, so hand that back rather than forgetting it.
    final tag = response.headers['etag'] ?? etag;
    if (response.statusCode == 304) {
      return ConditionalResponse(
        outcome: ConditionalOutcome.unchanged,
        etag: tag,
      );
    }
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    if (response.statusCode == 204 || response.body.isEmpty) {
      return ConditionalResponse(
        outcome: ConditionalOutcome.empty,
        etag: response.headers['etag'],
      );
    }
    final json = jsonDecode(response.body);
    final data = json['ocs']?['data'] ?? json;
    return ConditionalResponse(
      outcome: ConditionalOutcome.changed,
      data: fromJson(data as D),
      etag: response.headers['etag'],
    );
  }

  /// A verb carrying a JSON body, described.
  ///
  /// The charset is spelled out because `package:http` used to add it: handed a
  /// `String` body it appends `charset=utf-8` to a content type that has none,
  /// and handed bytes it does not. Encoding here rather than there would
  /// otherwise change what every write puts on the wire.
  ApiRequest _jsonRequest(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) => ApiRequest(
    method: method,
    uri: _uri(path),
    headers: body == null
        ? _headers
        : {..._headers, 'Content-Type': 'application/json; charset=utf-8'},
    timeout: _timeout,
    body: body == null ? null : utf8.encode(jsonEncode(body)),
  );

  Future<T> post<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(_jsonRequest('POST', path, body));
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> put<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(_jsonRequest('PUT', path, body));
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> patch<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(_jsonRequest('PATCH', path, body));
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<void> delete(String path) async {
    final response = await _send(_jsonRequest('DELETE', path, null));
    _notify(response.statusCode);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// DELETE that carries a request body and parses a response — for endpoints
  /// where the deletion needs parameters (e.g. remap-or-clear) and returns the
  /// updated resource.
  Future<T> deleteWithResult<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(_jsonRequest('DELETE', path, body));
    return _handleResponse<D, T>(response, fromJson);
  }

  /// Upload raw bytes (e.g. image) via POST with a given content type.
  Future<T> uploadBytes<D, T>(
    String path, {
    required List<int> bytes,
    required String contentType,
    Map<String, String>? query,
    required T Function(D data) fromJson,
  }) async {
    final headers = {
      ..._credentials.basicAuthHeaders,
      'Accept': 'application/json',
      'Content-Type': contentType,
    };
    final response = await _send(
      ApiRequest(
        method: 'POST',
        uri: _uri(path, query),
        headers: headers,
        timeout: _uploadTimeout,
        body: bytes,
      ),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  /// Upload a file via multipart form POST.
  Future<T> uploadMultipart<D, T>(
    String path, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String fieldName = 'file',
    Map<String, String>? fields,
    required T Function(D data) fromJson,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({
        ..._credentials.basicAuthHeaders,
        'Accept': 'application/json',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    if (fields != null) {
      request.fields.addAll(fields);
    }
    // Finalizing is what makes a multipart body describable: it picks the
    // boundary, writes it into the content type, and collapses the parts into
    // the bytes that would have gone out. A stream could not be handed to
    // anyone else to send, and could not be sent twice.
    final body = await request.finalize().toBytes();
    final response = await _send(
      ApiRequest(
        method: 'POST',
        uri: request.url,
        headers: request.headers,
        timeout: _uploadTimeout,
        body: body,
      ),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Uri buildUri(String path, [Map<String, String>? query]) => _uri(path, query);

  Map<String, String> get authHeaders => _credentials.basicAuthHeaders;

  T _handleResponse<D, T>(http.Response response, T Function(D) fromJson) {
    _notify(response.statusCode);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body);
    final data = json['ocs']?['data'] ?? json;
    return fromJson(data as D);
  }
}
