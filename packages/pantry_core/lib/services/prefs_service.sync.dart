part of 'prefs_service.dart';

extension PrefsServiceSyncSetters on PrefsService {
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(
      key: PrefsService._notificationsEnabledKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setPollIntervalMinutes(int minutes) async {
    _pollIntervalMinutes = minutes;
    await _storage.write(
      key: PrefsService._pollIntervalMinutesKey,
      value: minutes.toString(),
    );
    notifyListeners();
  }

  Future<void> setNotificationsIntroSeen(bool value) async {
    _notificationsIntroSeen = value;
    await _storage.write(
      key: PrefsService._notificationsIntroSeenKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setChecklistRefreshSeconds(int seconds) async {
    if (!PrefsService._validRefreshSeconds.contains(seconds)) return;
    if (_checklistRefreshSeconds == seconds) return;
    _checklistRefreshSeconds = seconds;
    await _storage.write(
      key: PrefsService._checklistRefreshSecondsKey,
      value: seconds.toString(),
    );
    notifyListeners();
  }

  Future<void> setNotesRefreshSeconds(int seconds) async {
    if (!PrefsService._validRefreshSeconds.contains(seconds)) return;
    if (_notesRefreshSeconds == seconds) return;
    _notesRefreshSeconds = seconds;
    await _storage.write(
      key: PrefsService._notesRefreshSecondsKey,
      value: seconds.toString(),
    );
    notifyListeners();
  }

  Future<void> setPhotosRefreshSeconds(int seconds) async {
    if (!PrefsService._validRefreshSeconds.contains(seconds)) return;
    if (_photosRefreshSeconds == seconds) return;
    _photosRefreshSeconds = seconds;
    await _storage.write(
      key: PrefsService._photosRefreshSecondsKey,
      value: seconds.toString(),
    );
    notifyListeners();
  }

  Future<void> setWearPollSeconds(int seconds) async {
    if (!PrefsService._validRefreshSeconds.contains(seconds)) return;
    if (_wearPollSeconds == seconds) return;
    _wearPollSeconds = seconds;
    await _storage.write(
      key: PrefsService._wearPollSecondsKey,
      value: seconds.toString(),
    );
    notifyListeners();
  }

  Future<void> setShoppingRefreshSeconds(int seconds) async {
    if (seconds != PrefsService.shoppingRefreshInherit &&
        !PrefsService._validRefreshSeconds.contains(seconds)) {
      return;
    }
    if (_shoppingRefreshSeconds == seconds) return;
    _shoppingRefreshSeconds = seconds;
    await _storage.write(
      key: PrefsService._shoppingRefreshSecondsKey,
      value: seconds.toString(),
    );
    notifyListeners();
  }
}
