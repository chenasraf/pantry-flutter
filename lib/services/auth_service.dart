import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
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

  /// First day of week from Nextcloud user settings.
  /// 0 = Sunday, 1 = Monday, ..., 6 = Saturday.
  int _firstDayOfWeek = _firstDayFromLocale();
  int get firstDayOfWeek => _firstDayOfWeek;

  Future<void> loadCredentials() async {
    final json = await _storage.read(key: _credentialsKey);
    if (json != null) {
      _credentials = NextcloudCredentials.fromJson(jsonDecode(json));
      await fetchFirstDayOfWeek();
    }
  }

  static String get _userAgent {
    final platform = kIsWeb
        ? 'Web'
        : Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
        ? 'iOS'
        : Platform.isMacOS
        ? 'macOS'
        : Platform.isLinux
        ? 'Linux'
        : Platform.isWindows
        ? 'Windows'
        : 'Unknown';
    return 'Pantry ($platform)';
  }

  Future<void> fetchFirstDayOfWeek() async {
    if (_credentials == null) return;
    try {
      final uri = Uri.parse(
        '${_credentials!.serverUrl}/ocs/v2.php/apps/pantry/api/prefs',
      );
      final response = await http.get(
        uri,
        headers: {
          ..._credentials!.basicAuthHeaders,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = data['ocs']?['data'] as Map<String, dynamic>?;
        final firstDay = prefs?['firstDayOfWeek'] as int?;
        _firstDayOfWeek = (firstDay != null && firstDay >= 0)
            ? firstDay
            : _firstDayFromLocale();
      }
    } catch (e) {
      debugPrint('[AuthService] Failed to fetch first day of week: $e');
      _firstDayOfWeek = _firstDayFromLocale();
    }
  }

  /// Derives the first day of week from the device locale.
  /// Returns 0 = Sunday, 1 = Monday, ..., 6 = Saturday.
  static int _firstDayFromLocale() {
    final tag = ui.PlatformDispatcher.instance.locale.toLanguageTag();
    final region = _regionFromLocale(tag);

    // Countries/regions where Sunday is the first day of week
    const sundayFirst = {
      'US',
      'CA',
      'BR',
      'JP',
      'KR',
      'TW',
      'IL',
      'SA',
      'AE',
      'BH',
      'DZ',
      'EG',
      'IQ',
      'JO',
      'KW',
      'LY',
      'OM',
      'QA',
      'SY',
      'YE',
      'AG',
      'AS',
      'BD',
      'BZ',
      'BT',
      'BO',
      'BS',
      'BW',
      'CO',
      'DM',
      'DO',
      'ET',
      'GU',
      'GT',
      'GY',
      'HK',
      'HN',
      'ID',
      'IN',
      'JM',
      'KE',
      'KH',
      'LA',
      'MH',
      'MM',
      'MO',
      'MT',
      'MX',
      'MZ',
      'NI',
      'NP',
      'PA',
      'PE',
      'PH',
      'PK',
      'PR',
      'PT',
      'PY',
      'SG',
      'SV',
      'TH',
      'TT',
      'UM',
      'VE',
      'VI',
      'WS',
      'ZA',
      'ZW',
    };

    // Countries where Saturday is the first day
    const saturdayFirst = {'AF', 'IR'};

    if (region != null) {
      if (sundayFirst.contains(region)) return 0;
      if (saturdayFirst.contains(region)) return 6;
    }

    // Default: Monday
    return 1;
  }

  static String? _regionFromLocale(String tag) {
    // Handle both "en_US" and "en-US" formats
    final parts = tag.split(RegExp(r'[_-]'));
    if (parts.length >= 2) {
      final candidate = parts[1].toUpperCase();
      if (candidate.length == 2) return candidate;
    }
    return null;
  }

  Future<LoginFlowResult> initiateLoginFlow(String serverUrl) async {
    final url = '$serverUrl/index.php/login/v2';
    final response = await http.post(
      Uri.parse(url),
      headers: {'User-Agent': _userAgent},
    );

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
    await _storage.delete(key: _credentialsKey);
  }
}
