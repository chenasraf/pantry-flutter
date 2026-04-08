import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class NextcloudCredentials {
  final String serverUrl;
  final String loginName;
  final String appPassword;

  const NextcloudCredentials({
    required this.serverUrl,
    required this.loginName,
    required this.appPassword,
  });

  Map<String, String> get basicAuthHeaders => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$loginName:$appPassword'))}',
    'OCS-APIREQUEST': 'true',
  };

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'loginName': loginName,
    'appPassword': appPassword,
  };

  factory NextcloudCredentials.fromJson(Map<String, dynamic> json) =>
      NextcloudCredentials(
        serverUrl: json['serverUrl'] as String,
        loginName: json['loginName'] as String,
        appPassword: json['appPassword'] as String,
      );
}

class LoginFlowResult {
  final String loginUrl;
  final String pollEndpoint;
  final String pollToken;

  const LoginFlowResult({
    required this.loginUrl,
    required this.pollEndpoint,
    required this.pollToken,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _credentialsKey = 'nextcloud_credentials';
  final _storage = const FlutterSecureStorage();

  NextcloudCredentials? _credentials;
  NextcloudCredentials? get credentials => _credentials;
  bool get isLoggedIn => _credentials != null;

  Uint8List? _avatarBytes;
  Uint8List? get avatarBytes => _avatarBytes;

  Future<void> loadCredentials() async {
    final json = await _storage.read(key: _credentialsKey);
    if (json != null) {
      _credentials = NextcloudCredentials.fromJson(jsonDecode(json));
      await fetchAvatar();
    }
  }

  Future<void> fetchAvatar() async {
    if (_credentials == null) return;
    try {
      final uri = Uri.parse(
        '${_credentials!.serverUrl}/index.php/avatar/${_credentials!.loginName}/128',
      );
      final response = await http.get(
        uri,
        headers: _credentials!.basicAuthHeaders,
      );
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _avatarBytes = response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to load avatar: $e');
    }
  }

  Future<LoginFlowResult> initiateLoginFlow(String serverUrl) async {
    final url = '$serverUrl/index.php/login/v2';
    final response = await http.post(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to initiate login flow: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final poll = data['poll'] as Map<String, dynamic>;

    return LoginFlowResult(
      loginUrl: data['login'] as String,
      pollEndpoint: poll['endpoint'] as String,
      pollToken: poll['token'] as String,
    );
  }

  Future<NextcloudCredentials?> pollLoginFlow(
    String serverUrl,
    LoginFlowResult flow,
  ) async {
    debugPrint('[AuthService] Polling ${flow.pollEndpoint}');
    final response = await http.post(
      Uri.parse(flow.pollEndpoint),
      body: {'token': flow.pollToken},
    );

    debugPrint('[AuthService] Poll response: ${response.statusCode}');
    debugPrint('[AuthService] Poll body: ${response.body}');

    if (response.statusCode == 404) {
      return null; // Not yet authenticated
    }

    if (response.statusCode != 200) {
      throw Exception('Poll failed: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('[AuthService] Poll data keys: ${data.keys.toList()}');
    final creds = NextcloudCredentials(
      serverUrl: data['server'] as String,
      loginName: data['loginName'] as String,
      appPassword: data['appPassword'] as String,
    );

    debugPrint('[AuthService] Got credentials for ${creds.loginName}');
    await _saveCredentials(creds);
    return creds;
  }

  Future<void> _saveCredentials(NextcloudCredentials creds) async {
    _credentials = creds;
    await _storage.write(
      key: _credentialsKey,
      value: jsonEncode(creds.toJson()),
    );
  }

  Future<void> logout() async {
    if (_credentials != null) {
      try {
        // Revoke the app password
        final uri = Uri.parse(
          '${_credentials!.serverUrl}/ocs/v2.php/core/apppassword',
        );
        await http.delete(uri, headers: _credentials!.basicAuthHeaders);
      } catch (e) {
        debugPrint('Failed to revoke app password: $e');
      }
    }
    _credentials = null;
    _avatarBytes = null;
    await _storage.delete(key: _credentialsKey);
  }
}
