import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/sync/sync_manager.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when a request is attempted while the device has no connectivity.
/// Surfaced as a fast failure (statusCode 0) so callers fall back to their
/// on-disk cache immediately instead of waiting out the request timeout.
class OfflineException extends ApiException {
  const OfflineException() : super(0, 'Device is offline');
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

  /// Wall-clock budget for a single request. Without this an unreachable
  /// server (common when away from the home network — the socket hangs
  /// rather than failing fast) blocks the awaiting future forever, so the
  /// caller's cache-fallback/error path never runs and the UI spins
  /// indefinitely (issue #87).
  static const _timeout = Duration(seconds: 15);

  /// Uploads (photos) legitimately take longer than a regular request, so
  /// they get a more generous budget than [_timeout] while still bailing on
  /// an unreachable server instead of hanging forever.
  static const _uploadTimeout = Duration(seconds: 60);

  /// Invoked whenever any request comes back `403 Forbidden`, regardless of
  /// verb or call site (direct awaits and SyncManager-queued ops alike funnel
  /// through here). Registered once at app startup to surface a single
  /// "you don't have permission" snackbar. The server is the source of truth
  /// for roles; this is the safety net for permissions that changed
  /// mid-session after the UI was already gated.
  static void Function()? onForbidden;

  static void _notify(int statusCode) {
    if (statusCode == 403) onForbidden?.call();
  }

  NextcloudCredentials get _credentials {
    final creds = AuthService.instance.credentials;
    if (creds == null) throw StateError('Not authenticated');
    return creds;
  }

  /// Fails fast when connectivity is known to be down, so reads fall back to
  /// cache immediately instead of waiting out [_timeout]. Note this only
  /// catches a missing network interface — a reachable network with an
  /// unreachable server still relies on [_timeout].
  void _ensureOnline() {
    if (!SyncManager.instance.isOnline) throw const OfflineException();
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
    _ensureOnline();
    final response = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(_timeout);
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> post<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    _ensureOnline();
    final response = await http
        .post(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> put<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    _ensureOnline();
    final response = await http
        .put(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> patch<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    _ensureOnline();
    final response = await http
        .patch(
          _uri(path),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<void> delete(String path) async {
    _ensureOnline();
    final response = await http
        .delete(_uri(path), headers: _headers)
        .timeout(_timeout);
    if (response.statusCode >= 400) {
      _notify(response.statusCode);
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Upload raw bytes (e.g. image) via POST with a given content type.
  Future<T> uploadBytes<D, T>(
    String path, {
    required List<int> bytes,
    required String contentType,
    Map<String, String>? query,
    required T Function(D data) fromJson,
  }) async {
    _ensureOnline();
    final headers = {
      ..._credentials.basicAuthHeaders,
      'Accept': 'application/json',
      'Content-Type': contentType,
    };
    final response = await http
        .post(_uri(path, query), headers: headers, body: bytes)
        .timeout(_uploadTimeout);
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
    _ensureOnline();
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({
        ..._credentials.basicAuthHeaders,
        'Accept': 'application/json',
      })
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
      );
    if (fields != null) {
      request.fields.addAll(fields);
    }
    final streamed = await request.send().timeout(_uploadTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_uploadTimeout);
    return _handleResponse<D, T>(response, fromJson);
  }

  Uri buildUri(String path, [Map<String, String>? query]) => _uri(path, query);

  Map<String, String> get authHeaders => _credentials.basicAuthHeaders;

  T _handleResponse<D, T>(http.Response response, T Function(D) fromJson) {
    if (response.statusCode >= 400) {
      _notify(response.statusCode);
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body);
    final data = json['ocs']?['data'] ?? json;
    return fromJson(data as D);
  }
}
