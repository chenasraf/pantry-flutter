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

  /// The accent the app paints with. Falls back to [_defaultColor] when the
  /// user has opted out of the Nextcloud theme color, even if one is cached.
  Color get effectiveColor => PrefsService.instance.useServerThemeColor
      ? (_themeColor ?? _defaultColor)
      : _defaultColor;

  bool get useServerThemeColor => PrefsService.instance.useServerThemeColor;

  Future<void> setUseServerThemeColor(bool value) async {
    await PrefsService.instance.setUseServerThemeColor(value);
    notifyListeners();
  }

  /// Seed [_themeColor] from the last value persisted by [fetchTheme]. Lets
  /// the app paint the correct accent immediately on cold start, even if the
  /// capabilities call later fails or returns an empty `theming` block.
  void loadCached() {
    final hex = PrefsService.instance.themeColorHex;
    final cached = _parseHex(hex);
    if (cached != null) _themeColor = cached;
  }

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

    Color? fetched;

    // NC 34 dropped the legacy `/apps/theming/manifest/core` endpoint (now
    // 500s). Read the user's effective accent from the OCS capabilities
    // `theming` block instead — `ServerVersionService.fetch()` already
    // captures it for us.
    if (ServerVersionService.instance.isServerVersion('>=', '34.0.0')) {
      fetched = _readColorFromCaps(ServerVersionService.instance.themingCaps);
    } else {
      try {
        final uri = Uri.parse(
          '${creds.serverUrl}/index.php/apps/theming/manifest/core',
        );
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          fetched = _parseHex(data['theme_color'] as String?);
        }
      } catch (e) {
        debugPrint('[ThemingService] Failed to fetch theme: $e');
      }
    }

    // Keep the cached color on an empty fetch — a transient capabilities
    // response without a `theming` block shouldn't demote the accent.
    if (fetched == null) return;
    if (fetched == _themeColor) return;
    _themeColor = fetched;
    await PrefsService.instance.setThemeColorHex(_hexOf(fetched));
    notifyListeners();
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

  static String _hexOf(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void clear() {
    _themeColor = null;
  }
}
