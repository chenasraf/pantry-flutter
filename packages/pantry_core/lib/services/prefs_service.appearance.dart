part of 'prefs_service.dart';

extension PrefsServiceAppearanceSetters on PrefsService {
  Future<void> setLocale(String? locale) async {
    _locale = locale;
    if (locale == null) {
      await _storage.delete(key: PrefsService._localeKey);
    } else {
      await _storage.write(key: PrefsService._localeKey, value: locale);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(String? mode) async {
    _themeMode = mode;
    if (mode == null) {
      await _storage.delete(key: PrefsService._themeModeKey);
    } else {
      await _storage.write(key: PrefsService._themeModeKey, value: mode);
    }
    notifyListeners();
  }

  /// The theme the home-screen widget should paint with — `light` or `dark`,
  /// resolving `system` against the current platform brightness.
  String get resolvedThemeName => switch (_themeMode) {
    'light' => 'light',
    'dark' => 'dark',
    _ =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark
          ? 'dark'
          : 'light',
  };

  Future<void> setThemeColorHex(String? hex) async {
    if (_themeColorHex == hex) return;
    _themeColorHex = hex;
    if (hex == null) {
      await _storage.delete(key: PrefsService._themeColorKey);
    } else {
      await _storage.write(key: PrefsService._themeColorKey, value: hex);
    }
    notifyListeners();
  }

  Future<void> setUseServerThemeColor(bool value) async {
    if (_useServerThemeColor == value) return;
    _useServerThemeColor = value;
    await _storage.write(
      key: PrefsService._useServerThemeColorKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setUserProfileCache({
    required String? displayName,
    required String? serverLanguage,
  }) async {
    var changed = false;
    if (_displayName != displayName) {
      _displayName = displayName;
      if (displayName == null) {
        await _storage.delete(key: PrefsService._displayNameKey);
      } else {
        await _storage.write(
          key: PrefsService._displayNameKey,
          value: displayName,
        );
      }
      changed = true;
    }
    if (_serverLanguage != serverLanguage) {
      _serverLanguage = serverLanguage;
      if (serverLanguage == null) {
        await _storage.delete(key: PrefsService._serverLanguageKey);
      } else {
        await _storage.write(
          key: PrefsService._serverLanguageKey,
          value: serverLanguage,
        );
      }
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> setFirstDayOfWeekCache(int? value) async {
    if (_firstDayOfWeek == value) return;
    _firstDayOfWeek = value;
    if (value == null) {
      await _storage.delete(key: PrefsService._firstDayOfWeekKey);
    } else {
      await _storage.write(
        key: PrefsService._firstDayOfWeekKey,
        value: value.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> setNavOrder(List<NavSection> order) async {
    final normalized = decodeNavOrder(encodeNavOrder(order));
    _navOrder = normalized;
    await _storage.write(
      key: PrefsService._navOrderKey,
      value: encodeNavOrder(normalized),
    );
    notifyListeners();
  }

  /// Show or hide [section] in the primary navigation. Hiding is rejected when
  /// [section] is the last visible one, so at least one tab always remains.
  Future<void> setNavSectionEnabled(NavSection section, bool enabled) async {
    final bool changed;
    if (enabled) {
      changed = _navDisabled.remove(section);
    } else {
      changed = enabledNavOrder.length > 1 && _navDisabled.add(section);
    }
    if (!changed) return;
    await _storage.write(
      key: PrefsService._navDisabledKey,
      value: encodeNavDisabled(_navDisabled),
    );
    notifyListeners();
  }
}
