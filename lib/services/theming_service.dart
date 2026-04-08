import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pantry/services/auth_service.dart';

class ThemingService {
  ThemingService._();
  static final ThemingService instance = ThemingService._();

  Color? _themeColor;
  Color? get themeColor => _themeColor;

  static const _defaultColor = Color(0xFF0082C9);

  Color get effectiveColor => _themeColor ?? _defaultColor;

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
