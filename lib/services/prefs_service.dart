import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:home_widget/home_widget.dart';

import '../models/nav_section.dart';
import '../utils/platform_info.dart';
import 'checklist_service.dart';
import 'house_service.dart';

class PrefsService extends ChangeNotifier {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  static const _lastHouseKey = 'last_house_id';
  static const _pinnedListIdsKey = 'pinned_list_ids';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _pollIntervalMinutesKey = 'poll_interval_minutes';
  static const _notificationsIntroSeenKey = 'notifications_intro_seen';
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _checklistTapRowToToggleKey = 'checklist_tap_row_to_toggle';
  static const _defaultItemTapActionKey = 'default_item_tap_action';
  static const _checklistCategorySpacingKey = 'checklist_category_spacing';
  static const _checklistViewKey = 'checklist_view';
  static const _checklistListFilterKey = 'checklist_list_filter';
  static const _checklistDoneCollapsedKey = 'checklist_done_collapsed';
  static const _checklistProgressHeroHiddenKey =
      'checklist_progress_hero_hidden';
  static const _lastSeenOnboardingVersionKey = 'last_seen_onboarding_version';
  static const _navOrderKey = 'nav_order';
  static const _themeColorKey = 'theme_color';
  static const _displayNameKey = 'display_name';
  static const _serverLanguageKey = 'server_language';
  static const _firstDayOfWeekKey = 'first_day_of_week';
  static const _devForceAllFeaturesKey = 'dev_force_all_features';
  final _storage = const FlutterSecureStorage();

  int? _lastHouseId;
  int? get lastHouseId => _lastHouseId;

  Set<int> _pinnedListIds = {};
  Set<int> get pinnedListIds => _pinnedListIds;
  bool isListPinned(int id) => _pinnedListIds.contains(id);

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

  /// Action performed when the user taps an item row. One of:
  /// `done`, `view`, `edit`, `none`. Default is `view`.
  String _defaultItemTapAction = 'view';
  String get defaultItemTapAction => _defaultItemTapAction;

  /// "disabled", "space", "divider"
  String _checklistCategorySpacing = 'disabled';
  String get checklistCategorySpacing => _checklistCategorySpacing;

  /// "list" or "cards"
  String _checklistView = 'list';
  String get checklistView => _checklistView;

  /// Selected list IDs for the All-lists view's per-list filter. Empty means
  /// "all lists". Local-only (not synced) so each device keeps its own focus.
  Set<int> _checklistListFilter = {};
  Set<int> get checklistListFilter => _checklistListFilter;

  bool _checklistDoneCollapsed = true;
  bool get checklistDoneCollapsed => _checklistDoneCollapsed;

  /// User has swiped away the top progress-ring card. When true, the card
  /// (circular ring + "{N} items left" / "{done} of {total} done") is hidden
  /// on every checklist. Re-enable from Settings → Interface.
  bool _checklistProgressHeroHidden = false;
  bool get checklistProgressHeroHidden => _checklistProgressHeroHidden;

  /// The app version of the most recent onboarding the user finished or
  /// skipped. `null` means the user has never seen any onboarding (treat as
  /// brand new). Compared against [appOnboardingPages] keys to decide which
  /// pages still need to be shown.
  String? _lastSeenOnboardingVersion;
  String? get lastSeenOnboardingVersion => _lastSeenOnboardingVersion;

  /// Order of primary navigation destinations (bottom bar on mobile, rail on
  /// desktop). The first entry is also the section opened by default at
  /// cold start. Always contains every [NavSection] exactly once.
  List<NavSection> _navOrder = List.of(kDefaultNavOrder);
  List<NavSection> get navOrder => List.unmodifiable(_navOrder);

  /// Last Nextcloud theme color fetched from the server, persisted as
  /// "#RRGGBB". Cached so the app can render with the right accent on a
  /// cold start before (or even without) a successful capabilities call —
  /// covers transient empty `theming` blocks and offline launches.
  String? _themeColorHex;
  String? get themeColorHex => _themeColorHex;

  /// Cached snapshot of values fetched from the Nextcloud user profile. These
  /// change rarely (user has to change them in Nextcloud), so we seed
  /// [AuthService] from them on cold start and refresh in the background.
  String? _displayName;
  String? get displayName => _displayName;

  String? _serverLanguage;
  String? get serverLanguage => _serverLanguage;

  /// Cached first-day-of-week from the Pantry per-user prefs endpoint.
  /// `null` means we've never fetched it; callers should fall back to a
  /// locale-derived default.
  int? _firstDayOfWeek;
  int? get firstDayOfWeek => _firstDayOfWeek;

  /// Debug-only override: when true, [ServerVersionService.hasFeature] and
  /// [ServerVersionService.supportsFeature] return true for every feature,
  /// regardless of what the server reports. Lets us drive every gated UI
  /// against a backend that doesn't (yet) advertise the feature.
  bool _devForceAllFeatures = false;
  bool get devForceAllFeatures => _devForceAllFeatures;

  Future<void> load() async {
    // One platform-channel round trip instead of ~17 sequential reads —
    // measurably shaves cold-start time on iOS Keychain / Android Keystore.
    final all = await _storage.readAll();

    final lastHouse = all[_lastHouseKey];
    if (lastHouse != null) _lastHouseId = int.tryParse(lastHouse);

    final pins = all[_pinnedListIdsKey];
    if (pins != null && pins.isNotEmpty) {
      _pinnedListIds = pins.split(',').map(int.parse).toSet();
    }

    final notif = all[_notificationsEnabledKey];
    if (notif != null) _notificationsEnabled = notif == 'true';

    final poll = all[_pollIntervalMinutesKey];
    if (poll != null) {
      final parsed = int.tryParse(poll);
      if (parsed != null && parsed > 0) _pollIntervalMinutes = parsed;
    }

    final intro = all[_notificationsIntroSeenKey];
    if (intro != null) _notificationsIntroSeen = intro == 'true';

    _locale = all[_localeKey];
    _themeMode = all[_themeModeKey];

    final tapAction = all[_defaultItemTapActionKey];
    if (tapAction != null && _isValidTapAction(tapAction)) {
      _defaultItemTapAction = tapAction;
    } else {
      // Migrate the legacy boolean: true → done, false → view.
      final legacyTapRow = all[_checklistTapRowToToggleKey];
      if (legacyTapRow != null) {
        _defaultItemTapAction = legacyTapRow == 'true' ? 'done' : 'view';
        await _storage.write(
          key: _defaultItemTapActionKey,
          value: _defaultItemTapAction,
        );
        await _storage.delete(key: _checklistTapRowToToggleKey);
      }
    }

    final spacing = all[_checklistCategorySpacingKey];
    if (spacing != null &&
        (spacing == 'disabled' || spacing == 'space' || spacing == 'divider')) {
      _checklistCategorySpacing = spacing;
    }

    final view = all[_checklistViewKey];
    if (view != null && (view == 'list' || view == 'cards')) {
      _checklistView = view;
    }

    final listFilter = all[_checklistListFilterKey];
    if (listFilter != null && listFilter.isNotEmpty) {
      _checklistListFilter = listFilter
          .split(',')
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    }

    final doneCollapsed = all[_checklistDoneCollapsedKey];
    if (doneCollapsed != null) {
      _checklistDoneCollapsed = doneCollapsed == 'true';
    }

    final progressHeroHidden = all[_checklistProgressHeroHiddenKey];
    if (progressHeroHidden != null) {
      _checklistProgressHeroHidden = progressHeroHidden == 'true';
    }

    _lastSeenOnboardingVersion = all[_lastSeenOnboardingVersionKey];

    _navOrder = decodeNavOrder(all[_navOrderKey]);

    _themeColorHex = all[_themeColorKey];

    _displayName = all[_displayNameKey];
    _serverLanguage = all[_serverLanguageKey];
    final firstDay = all[_firstDayOfWeekKey];
    if (firstDay != null) _firstDayOfWeek = int.tryParse(firstDay);

    final devForce = all[_devForceAllFeaturesKey];
    if (devForce != null) _devForceAllFeatures = devForce == 'true';
  }

  Future<void> setLastHouseId(int id) async {
    _lastHouseId = id;
    await _storage.write(key: _lastHouseKey, value: id.toString());
    notifyListeners();
  }

  /// The home-screen widget exists only on Android. Other platforms ship no
  /// widget host, so invoking `home_widget` channels there throws
  /// MissingPluginException. Gate every widget side-effect on this.
  static bool get _supportsWidget => PlatformInfo.isAndroid;

  /// Toggle pin for [listId]. Pass [pinnedListsJson] — a JSON-encoded list of
  /// `{id, name, houseId}` objects for all currently pinned lists after the
  /// toggle — so the Android widget SharedPrefs stay in sync.
  Future<void> togglePinnedList(
    int listId,
    List<Map<String, dynamic>> allPinnedAfterToggle,
  ) async {
    if (_pinnedListIds.contains(listId)) {
      _pinnedListIds.remove(listId);
    } else {
      _pinnedListIds.add(listId);
    }
    await _storage.write(
      key: _pinnedListIdsKey,
      value: _pinnedListIds.isEmpty ? '' : _pinnedListIds.join(','),
    );
    if (_supportsWidget) {
      await HomeWidget.saveWidgetData<String>(
        'pinned_lists',
        jsonEncode(allPinnedAfterToggle),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'dev.casraf.pantry.PantryWidgetProvider',
      );
    }
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _storage.write(
      key: _notificationsEnabledKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setPollIntervalMinutes(int minutes) async {
    _pollIntervalMinutes = minutes;
    await _storage.write(
      key: _pollIntervalMinutesKey,
      value: minutes.toString(),
    );
    notifyListeners();
  }

  Future<void> setLocale(String? locale) async {
    _locale = locale;
    if (locale == null) {
      await _storage.delete(key: _localeKey);
    } else {
      await _storage.write(key: _localeKey, value: locale);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(String? mode) async {
    _themeMode = mode;
    if (mode == null) {
      await _storage.delete(key: _themeModeKey);
    } else {
      await _storage.write(key: _themeModeKey, value: mode);
    }
    await pushWidgetTheme();
    notifyListeners();
  }

  /// Rebuild the pinned-lists JSON the Android widget reads — from cached
  /// lists + items for the current house. Call after caches load on app
  /// start so the widget survives an `HomeWidgetPreferences` wipe (e.g. a
  /// fresh install) without waiting for the next pin toggle.
  Future<void> pushWidgetPinnedLists() async {
    if (!_supportsWidget) return;
    if (_pinnedListIds.isEmpty) {
      await HomeWidget.saveWidgetData<String>('pinned_lists', '[]');
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'dev.casraf.pantry.PantryWidgetProvider',
      );
      return;
    }
    final cs = ChecklistService.instance;
    final houseId = _lastHouseId;
    final lists = houseId == null ? null : cs.getCachedLists(houseId);
    if (lists == null) return;
    final housesById = {
      for (final h in HouseService.instance.getCached() ?? []) h.id: h.name,
    };
    final entries = lists.where((l) => _pinnedListIds.contains(l.id)).map((l) {
      final cached = cs.getCachedItems(l.id) ?? [];
      final active = cached.where((i) => i.deletedAt == null).toList();
      final unchecked = active.where((i) => !i.done).length;
      return {
        'id': l.id,
        'name': l.name,
        'houseId': l.houseId,
        'houseName': housesById[l.houseId],
        'icon': l.icon,
        'unchecked': unchecked,
        'total': active.length,
      };
    }).toList();
    await HomeWidget.saveWidgetData<String>(
      'pinned_lists',
      jsonEncode(entries),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'dev.casraf.pantry.PantryWidgetProvider',
    );
  }

  /// Push the effective theme (`light` or `dark`) to the Android home-screen
  /// widget. Call after the user changes the in-app theme, and when the
  /// platform brightness changes while in system mode.
  Future<void> pushWidgetTheme() async {
    if (!_supportsWidget) return;
    final resolved = switch (_themeMode) {
      'light' => 'light',
      'dark' => 'dark',
      _ =>
        PlatformDispatcher.instance.platformBrightness == Brightness.dark
            ? 'dark'
            : 'light',
    };
    await HomeWidget.saveWidgetData<String>('widget_theme', resolved);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'dev.casraf.pantry.PantryWidgetProvider',
    );
  }

  static bool _isValidTapAction(String value) =>
      value == 'done' || value == 'view' || value == 'edit' || value == 'none';

  Future<void> setDefaultItemTapAction(String value) async {
    if (!_isValidTapAction(value)) return;
    if (_defaultItemTapAction == value) return;
    _defaultItemTapAction = value;
    await _storage.write(key: _defaultItemTapActionKey, value: value);
    notifyListeners();
  }

  Future<void> setChecklistCategorySpacing(String value) async {
    _checklistCategorySpacing = value;
    await _storage.write(key: _checklistCategorySpacingKey, value: value);
    notifyListeners();
  }

  Future<void> setChecklistView(String value) async {
    if (value != 'list' && value != 'cards') return;
    _checklistView = value;
    await _storage.write(key: _checklistViewKey, value: value);
    notifyListeners();
  }

  Future<void> setChecklistListFilter(Set<int> ids) async {
    _checklistListFilter = {...ids};
    await _storage.write(
      key: _checklistListFilterKey,
      value: _checklistListFilter.isEmpty ? '' : _checklistListFilter.join(','),
    );
    notifyListeners();
  }

  Future<void> setChecklistDoneCollapsed(bool value) async {
    _checklistDoneCollapsed = value;
    await _storage.write(
      key: _checklistDoneCollapsedKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setChecklistProgressHeroHidden(bool value) async {
    if (_checklistProgressHeroHidden == value) return;
    _checklistProgressHeroHidden = value;
    await _storage.write(
      key: _checklistProgressHeroHiddenKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> setLastSeenOnboardingVersion(String? version) async {
    _lastSeenOnboardingVersion = version;
    if (version == null) {
      await _storage.delete(key: _lastSeenOnboardingVersionKey);
    } else {
      await _storage.write(key: _lastSeenOnboardingVersionKey, value: version);
    }
    notifyListeners();
  }

  Future<void> setThemeColorHex(String? hex) async {
    if (_themeColorHex == hex) return;
    _themeColorHex = hex;
    if (hex == null) {
      await _storage.delete(key: _themeColorKey);
    } else {
      await _storage.write(key: _themeColorKey, value: hex);
    }
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
        await _storage.delete(key: _displayNameKey);
      } else {
        await _storage.write(key: _displayNameKey, value: displayName);
      }
      changed = true;
    }
    if (_serverLanguage != serverLanguage) {
      _serverLanguage = serverLanguage;
      if (serverLanguage == null) {
        await _storage.delete(key: _serverLanguageKey);
      } else {
        await _storage.write(key: _serverLanguageKey, value: serverLanguage);
      }
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<void> setFirstDayOfWeekCache(int? value) async {
    if (_firstDayOfWeek == value) return;
    _firstDayOfWeek = value;
    if (value == null) {
      await _storage.delete(key: _firstDayOfWeekKey);
    } else {
      await _storage.write(key: _firstDayOfWeekKey, value: value.toString());
    }
    notifyListeners();
  }

  Future<void> setNavOrder(List<NavSection> order) async {
    final normalized = decodeNavOrder(encodeNavOrder(order));
    _navOrder = normalized;
    await _storage.write(key: _navOrderKey, value: encodeNavOrder(normalized));
    notifyListeners();
  }

  Future<void> setDevForceAllFeatures(bool value) async {
    if (_devForceAllFeatures == value) return;
    _devForceAllFeatures = value;
    await _storage.write(key: _devForceAllFeaturesKey, value: value.toString());
    notifyListeners();
  }

  Future<void> setNotificationsIntroSeen(bool value) async {
    _notificationsIntroSeen = value;
    await _storage.write(
      key: _notificationsIntroSeenKey,
      value: value.toString(),
    );
    notifyListeners();
  }

  Future<void> clear() async {
    _lastHouseId = null;
    _pinnedListIds = {};
    _notificationsEnabled = true;
    _pollIntervalMinutes = 15;
    _notificationsIntroSeen = false;
    _locale = null;
    _themeMode = null;
    _defaultItemTapAction = 'view';
    _checklistCategorySpacing = 'disabled';
    _checklistView = 'list';
    _checklistListFilter = {};
    _checklistDoneCollapsed = true;
    _checklistProgressHeroHidden = false;
    _lastSeenOnboardingVersion = null;
    _navOrder = List.of(kDefaultNavOrder);
    _themeColorHex = null;
    _displayName = null;
    _serverLanguage = null;
    _firstDayOfWeek = null;
    _devForceAllFeatures = false;
    await _storage.delete(key: _lastHouseKey);
    await _storage.delete(key: _pinnedListIdsKey);
    await _storage.delete(key: _notificationsEnabledKey);
    await _storage.delete(key: _pollIntervalMinutesKey);
    await _storage.delete(key: _notificationsIntroSeenKey);
    await _storage.delete(key: _localeKey);
    await _storage.delete(key: _themeModeKey);
    await _storage.delete(key: _checklistTapRowToToggleKey);
    await _storage.delete(key: _defaultItemTapActionKey);
    await _storage.delete(key: _checklistCategorySpacingKey);
    await _storage.delete(key: _checklistViewKey);
    await _storage.delete(key: _checklistListFilterKey);
    await _storage.delete(key: _checklistDoneCollapsedKey);
    await _storage.delete(key: _checklistProgressHeroHiddenKey);
    await _storage.delete(key: _lastSeenOnboardingVersionKey);
    await _storage.delete(key: _navOrderKey);
    await _storage.delete(key: _themeColorKey);
    await _storage.delete(key: _displayNameKey);
    await _storage.delete(key: _serverLanguageKey);
    await _storage.delete(key: _firstDayOfWeekKey);
    await _storage.delete(key: _devForceAllFeaturesKey);
    notifyListeners();
  }
}
