import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pantry/services/auth_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _basePath = '/ocs/v2.php/apps/pantry/api';

  NextcloudCredentials get _credentials {
    final creds = AuthService.instance.credentials;
    if (creds == null) throw StateError('Not authenticated');
    return creds;
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(_credentials.serverUrl);
    return base.replace(
      path: '$_basePath$path',
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
    final response = await http.get(_uri(path, query), headers: _headers);
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> post<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<T> put<D, T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(D data) fromJson,
  }) async {
    final response = await http.put(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<D, T>(response, fromJson);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers);
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Uri buildUri(String path, [Map<String, String>? query]) => _uri(path, query);

  Map<String, String> get authHeaders => _credentials.basicAuthHeaders;

  T _handleResponse<D, T>(http.Response response, T Function(D) fromJson) {
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body);
    final data = json['ocs']?['data'] ?? json;
    return fromJson(data as D);
  }
}
