import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pantry_core/services/auth_service.dart';
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

  /// Runs [send] and reports what came back, so the app's notion of online is
  /// the outcome of a real request rather than a reading of the platform's
  /// interfaces.
  ///
  /// A transport failure becomes an [OfflineException] here rather than
  /// reaching callers raw: cache-first reads and the sync queue both branch on
  /// it, and neither can be asked to know that `ClientException` is what an
  /// Android socket says when a watch walks out of range.
  Future<http.Response> _send(Future<http.Response> Function() send) async {
    try {
      final response = await send();
      SyncManager.instance.setOnline(true);
      return response;
    } on SocketException catch (e) {
      SyncManager.instance.setOnline(false);
      throw OfflineException(e.message);
    } on http.ClientException catch (e) {
      SyncManager.instance.setOnline(false);
      throw OfflineException(e.message);
    } on TimeoutException {
      // A server that accepts the connection and then says nothing inside the
      // budget is unreachable for every purpose the caller has.
      SyncManager.instance.setOnline(false);
      throw const OfflineException('Request timed out');
    }
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
      () => http.get(_uri(path, query), headers: _headers).timeout(_timeout),
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
      () => http.get(_uri(path, query), headers: headers).timeout(_timeout),
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

  Future<T> post<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(
      () => http
          .post(
            _uri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> put<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(
      () => http
          .put(
            _uri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> patch<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await _send(
      () => http
          .patch(
            _uri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<void> delete(String path) async {
    final response = await _send(
      () => http.delete(_uri(path), headers: _headers).timeout(_timeout),
    );
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
    final response = await _send(
      () => http
          .delete(
            _uri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
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
      () => http
          .post(_uri(path, query), headers: headers, body: bytes)
          .timeout(_uploadTimeout),
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
    final response = await _send(() async {
      final streamed = await request.send().timeout(_uploadTimeout);
      return http.Response.fromStream(streamed).timeout(_uploadTimeout);
    });
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
