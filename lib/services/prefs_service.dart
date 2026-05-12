import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrefsService {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  static const _lastHouseKey = 'last_house_id';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _pollIntervalMinutesKey = 'poll_interval_minutes';
  static const _notificationsIntroSeenKey = 'notifications_intro_seen';
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _checklistTapRowToToggleKey = 'checklist_tap_row_to_toggle';
  final _storage = const FlutterSecureStorage();

  int? _lastHouseId;
  int? get lastHouseId => _lastHouseId;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  int _pollIntervalMinutes = 15;
  int get pollIntervalMinutes => _pollIntervalMinutes;

  bool _notificationsIntroSeen = false;
  bool get notificationsIntroSeen => _notificationsIntroSeen;

  /// null = system default, "en" or "he"
  String? _locale;
  String? get locale => _locale;

  /// null = system default, "light", "dark"
  String? _themeMode;
  String? get themeMode => _themeMode;

  bool _checklistTapRowToToggle = false;
  bool get checklistTapRowToToggle => _checklistTapRowToToggle;

  Future<void> load() async {
    final lastHouse = await _storage.read(key: _lastHouseKey);
    if (lastHouse != null) _lastHouseId = int.tryParse(lastHouse);

    final notif = await _storage.read(key: _notificationsEnabledKey);
    if (notif != null) _notificationsEnabled = notif == 'true';

    final poll = await _storage.read(key: _pollIntervalMinutesKey);
    if (poll != null) {
      final parsed = int.tryParse(poll);
      if (parsed != null && parsed > 0) _pollIntervalMinutes = parsed;
    }

    final intro = await _storage.read(key: _notificationsIntroSeenKey);
    if (intro != null) _notificationsIntroSeen = intro == 'true';

    _locale = await _storage.read(key: _localeKey);
    _themeMode = await _storage.read(key: _themeModeKey);

    final tapRow = await _storage.read(key: _checklistTapRowToToggleKey);
    if (tapRow != null) _checklistTapRowToToggle = tapRow == 'true';
  }

  Future<void> setLastHouseId(int id) async {
    _lastHouseId = id;
    await _storage.write(key: _lastHouseKey, value: id.toString());
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(
      key: _notificationsEnabledKey,
      value: value.toString(),
    );
  }

  Future<void> setPollIntervalMinutes(int minutes) async {
    _pollIntervalMinutes = minutes;
    await _storage.write(
      key: _pollIntervalMinutesKey,
      value: minutes.toString(),
    );
  }

  Future<void> setLocale(String? locale) async {
    _locale = locale;
    if (locale == null) {
      await _storage.delete(key: _localeKey);
    } else {
      await _storage.write(key: _localeKey, value: locale);
    }
  }

  Future<void> setThemeMode(String? mode) async {
    _themeMode = mode;
    if (mode == null) {
      await _storage.delete(key: _themeModeKey);
    } else {
      await _storage.write(key: _themeModeKey, value: mode);
    }
  }

  Future<void> setChecklistTapRowToToggle(bool value) async {
    _checklistTapRowToToggle = value;
    await _storage.write(
      key: _checklistTapRowToToggleKey,
      value: value.toString(),
    );
  }

  Future<void> setNotificationsIntroSeen(bool value) async {
    _notificationsIntroSeen = value;
    await _storage.write(
      key: _notificationsIntroSeenKey,
      value: value.toString(),
    );
  }

  Future<void> clear() async {
    _lastHouseId = null;
    _notificationsEnabled = true;
    _pollIntervalMinutes = 15;
    _notificationsIntroSeen = false;
    _locale = null;
    _themeMode = null;
    _checklistTapRowToToggle = false;
    await _storage.delete(key: _lastHouseKey);
    await _storage.delete(key: _notificationsEnabledKey);
    await _storage.delete(key: _pollIntervalMinutesKey);
    await _storage.delete(key: _notificationsIntroSeenKey);
    await _storage.delete(key: _localeKey);
    await _storage.delete(key: _themeModeKey);
    await _storage.delete(key: _checklistTapRowToToggleKey);
  }
}
