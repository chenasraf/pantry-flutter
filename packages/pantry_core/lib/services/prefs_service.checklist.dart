part of 'prefs_service.dart';

extension PrefsServiceChecklistSetters on PrefsService {
  Future<void> setDefaultItemTapAction(String value) async {
    if (!PrefsService._isValidTapAction(value)) return;
    if (_defaultItemTapAction == value) return;
    _defaultItemTapAction = value;
    await _storage.write(
      key: PrefsService._defaultItemTapActionKey,
      value: value,
    );
    notifyListeners();
  }

  Future<void> setDefaultItemLongPressAction(String value) async {
    if (!PrefsService._isValidLongPressAction(value)) return;
    if (_defaultItemLongPressAction == value) return;
    _defaultItemLongPressAction = value;
    await _storage.write(
      key: PrefsService._defaultItemLongPressActionKey,
      value: value,
    );
    notifyListeners();
  }

  Future<void> setReuseExistingItemsCache(String value) async {
    if (!PrefsService._isValidReuseExistingItems(value)) return;
    if (_reuseExistingItems == value) return;
    _reuseExistingItems = value;
    await _storage.write(
      key: PrefsService._reuseExistingItemsKey,
      value: value,
    );
    notifyListeners();
  }

  Future<void> setSuggestArchivedItemsCache(bool value) async {
    if (_suggestArchivedItems == value) return;
    _suggestArchivedItems = value;
    await _storage.write(
      key: PrefsService._suggestArchivedItemsKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setChecklistView(String value) async {
    if (value != 'list' && value != 'cards') return;
    _checklistView = value;
    await _storage.write(key: PrefsService._checklistViewKey, value: value);
    notifyListeners();
  }

  Future<void> setChecklistCheckboxPosition(String value) async {
    if (value != 'start' && value != 'end') return;
    if (_checklistCheckboxPosition == value) return;
    _checklistCheckboxPosition = value;
    await _storage.write(
      key: PrefsService._checklistCheckboxPositionKey,
      value: value,
    );
    notifyListeners();
  }

  Future<void> setChecklistDensity(String value) async {
    if (!PrefsService._validDensities.contains(value)) return;
    if (_checklistDensity == value) return;
    _checklistDensity = value;
    await _storage.write(key: PrefsService._checklistDensityKey, value: value);
    notifyListeners();
  }

  Future<void> setSwipeActionsEnabled(bool value) async {
    if (_swipeActionsEnabled == value) return;
    _swipeActionsEnabled = value;
    await _storage.write(
      key: PrefsService._swipeActionsEnabledKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setStartShoppingFabEnabled(bool value) async {
    if (_startShoppingFabEnabled == value) return;
    _startShoppingFabEnabled = value;
    await _storage.write(
      key: PrefsService._startShoppingFabEnabledKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setTruncateItemNames(bool value) async {
    if (_truncateItemNames == value) return;
    _truncateItemNames = value;
    await _storage.write(
      key: PrefsService._truncateItemNamesKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setChecklistListFilter(Set<int> ids) async {
    _checklistListFilter = {...ids};
    await _storage.write(
      key: PrefsService._checklistListFilterKey,
      value: _checklistListFilter.isEmpty ? '' : _checklistListFilter.join(','),
    );
    notifyListeners();
  }

  Future<void> setItemChipVisible(String key, bool visible) async {
    final changed = visible
        ? _hiddenItemChips.remove(key)
        : _hiddenItemChips.add(key);
    if (!changed) return;
    await _storage.write(
      key: PrefsService._hiddenItemChipsKey,
      value: _hiddenItemChips.isEmpty ? '' : _hiddenItemChips.join(','),
    );
    notifyListeners();
  }

  Future<void> setChecklistDoneCollapsed(bool value) async {
    _checklistDoneCollapsed = value;
    await _storage.write(
      key: PrefsService._checklistDoneCollapsedKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setAllListsProgressHeroHidden(bool value) async {
    if (_allListsProgressHeroHidden == value) return;
    _allListsProgressHeroHidden = value;
    await _storage.write(
      key: PrefsService._allListsProgressHeroHiddenKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setListProgressHeroHidden(int id, bool hidden) async {
    final changed = hidden
        ? _progressHeroHiddenListIds.add(id)
        : _progressHeroHiddenListIds.remove(id);
    if (!changed) return;
    await _storage.write(
      key: PrefsService._progressHeroHiddenListIdsKey,
      value: _progressHeroHiddenListIds.isEmpty
          ? ''
          : _progressHeroHiddenListIds.join(','),
    );
    notifyListeners();
  }
}
