import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';

class ThemingService extends ChangeNotifier {
  ThemingService._();
  static final ThemingService instance = ThemingService._();

  Color? _themeColor;
  Color? get themeColor => _themeColor;

  static const _defaultColor = Color(0xFF0082C9);

  Color get effectiveColor => _themeColor ?? _defaultColor;

  ThemeMode get themeMode {
    switch (PrefsService.instance.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(String? mode) async {
    await PrefsService.instance.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> fetchTheme() async {
    final creds = AuthService.instance.credentials;
    if (creds == null) return;

    // NC 34 dropped the legacy `/apps/theming/manifest/core` endpoint (now
    // 500s). Read the user's effective accent from the OCS capabilities
    // `theming` block instead — `ServerVersionService.fetch()` already
    // captures it for us.
    if (ServerVersionService.instance.isServerVersion('>=', '34.0.0')) {
      _themeColor = _readColorFromCaps(
        ServerVersionService.instance.themingCaps,
      );
      return;
    }

    try {
      final uri = Uri.parse(
        '${creds.serverUrl}/index.php/apps/theming/manifest/core',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _themeColor = _parseHex(data['theme_color'] as String?);
      }
    } catch (e) {
      debugPrint('[ThemingService] Failed to fetch theme: $e');
    }
  }

  static Color? _readColorFromCaps(Map<String, dynamic>? caps) {
    if (caps == null) return null;
    // `primaryColor` exists on NC 30+; `color` is the older field still
    // populated on 34. Prefer the newer one but fall back if absent.
    return _parseHex(caps['primaryColor'] as String?) ??
        _parseHex(caps['color'] as String?);
  }

  static Color? _parseHex(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  void clear() {
    _themeColor = null;
  }
}
