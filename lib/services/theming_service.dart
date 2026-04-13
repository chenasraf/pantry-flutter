import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/prefs_service.dart';

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

    try {
      final uri = Uri.parse(
        '${creds.serverUrl}/index.php/apps/theming/manifest/core',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hex = data['theme_color'] as String?;
        if (hex != null && hex.startsWith('#')) {
          _themeColor = Color(int.parse('FF${hex.substring(1)}', radix: 16));
        }
      }
    } catch (e) {
      debugPrint('[ThemingService] Failed to fetch theme: $e');
    }
  }

  void clear() {
    _themeColor = null;
  }
}
