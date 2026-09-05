import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pantry_core/models/nav_section.dart';

part 'prefs_service.checklist.dart';
part 'prefs_service.appearance.dart';
part 'prefs_service.sync.dart';

class PrefsService extends ChangeNotifier {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  // Exposed so the setter extensions in this library's part files can notify;
  // ChangeNotifier.notifyListeners is otherwise @protected to the subclass body.
  @override
  void notifyListeners() => super.notifyListeners();

  static const _lastHouseKey = 'last_house_id';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _pollIntervalMinutesKey = 'poll_interval_minutes';
  static const _notificationsIntroSeenKey = 'notifications_intro_seen';
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _checklistTapRowToToggleKey = 'checklist_tap_row_to_toggle';
  static const _defaultItemTapActionKey = 'default_item_tap_action';
  static const _defaultItemLongPressActionKey =
      'default_item_long_press_action';
  static const _checklistCategorySpacingKey = 'checklist_category_spacing';
  static const _reuseExistingItemsKey = 'reuse_existing_items';
  static const _suggestArchivedItemsKey = 'suggest_archived_items';
  static const _checklistViewKey = 'checklist_view';
  static const _checklistCheckboxPositionKey = 'checklist_checkbox_position';
  static const _checklistDensityKey = 'checklist_density';
  static const _validDensities = {'normal', 'dense', 'compact'};
  static const _swipeActionsEnabledKey = 'swipe_actions_enabled';
  static const _startShoppingFabEnabledKey = 'start_shopping_fab_enabled';
  static const _truncateItemNamesKey = 'truncate_item_names';
  static const _checklistListFilterKey = 'checklist_list_filter';
  static const _hiddenItemChipsKey = 'hidden_item_chips';
  static const _checklistDoneCollapsedKey = 'checklist_done_collapsed';
  static const _allListsProgressHeroHiddenKey =
      'all_lists_progress_hero_hidden';
  static const _progressHeroHiddenListIdsKey = 'progress_hero_hidden_list_ids';
  static const _lastSeenOnboardingVersionKey = 'last_seen_onboarding_version';
  static const _navOrderKey = 'nav_order';
  static const _navDisabledKey = 'nav_disabled';
  static const _themeColorKey = 'theme_color';
  static const _useServerThemeColorKey = 'use_server_theme_color';
  static const _displayNameKey = 'display_name';
  static const _serverLanguageKey = 'server_language';
  static const _firstDayOfWeekKey = 'first_day_of_week';
  static const _devForceAllFeaturesKey = 'dev_force_all_features';
  static const _checklistRefreshSecondsKey = 'checklist_refresh_seconds';
  static const _notesRefreshSecondsKey = 'notes_refresh_seconds';
  static const _photosRefreshSecondsKey = 'photos_refresh_seconds';
  static const _shoppingRefreshSecondsKey = 'shopping_refresh_seconds';
  static const _wearPollSecondsKey = 'wear_poll_seconds';

  /// Allowed auto-refresh intervals in seconds. 0 means "off" (no background
  /// polling; manual pull-to-refresh only).
  static const _validRefreshSeconds = {0, 15, 30, 60, 120, 300};

  /// Sentinel for the shopping view's "same as checklists" option: resolve it
  /// against [checklistRefreshSeconds] at read time via
  /// [shoppingRefreshSecondsResolved].
  static const shoppingRefreshInherit = -1;
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

  /// Action performed when the user taps an item row. One of:
  /// `done`, `view`, `edit`, `none`. Default is `view`.
  String _defaultItemTapAction = 'view';
  String get defaultItemTapAction => _defaultItemTapAction;

  /// Action performed when the user long-presses an item row. One of:
  /// `multiselect`, `done`, `view`, `edit`, `none`. Default is `multiselect`,
  /// which keeps the built-in behavior: enter multi-select under any
  /// non-custom sort, or drag-to-reorder under custom sort.
  String _defaultItemLongPressAction = 'multiselect';
  String get defaultItemLongPressAction => _defaultItemLongPressAction;

  /// Account-scoped pref synced from the Pantry user-prefs endpoint, cached
  /// locally so the add-item path can read it synchronously. One of `ask`
  /// (default), `reuse`, `never`. Only meaningful when the server advertises
  /// the `reuse-existing-items` capability.
  String _reuseExistingItems = 'ask';
  String get reuseExistingItems => _reuseExistingItems;

  /// Account-scoped pref synced from the Pantry user-prefs endpoint, cached
  /// locally so the add-item path can read it synchronously. When true, the
  /// item-reuse suggestions also search archived items on the target list.
  /// Only meaningful when the server advertises the
  /// `pref-suggest-archived-items` capability.
  bool _suggestArchivedItems = false;
  bool get suggestArchivedItems => _suggestArchivedItems;

  /// "list" or "cards"
  String _checklistView = 'list';
  String get checklistView => _checklistView;

  /// Which side of a checklist row the checkbox sits on. Directional so it
  /// follows text direction: "start" (default) is the leading edge, "end" the
  /// trailing edge.
  String _checklistCheckboxPosition = 'start';
  String get checklistCheckboxPosition => _checklistCheckboxPosition;

  /// Visual density of checklist rows: "normal" (default), "dense", "compact".
  /// Denser values trim padding, tap height and swipe sizing to fit more rows.
  /// Legacy prefs stored only "normal"/"dense" (both still valid), so no
  /// migration is needed.
  String _checklistDensity = 'normal';
  String get checklistDensity => _checklistDensity;

  /// When true (default), checklist rows reveal their actions on a horizontal
  /// swipe (pinned buttons on desktop). When false, the actions move into a
  /// trailing overflow menu instead — for users who trigger the swipe
  /// gesture accidentally while scrolling.
  bool _swipeActionsEnabled = true;
  bool get swipeActionsEnabled => _swipeActionsEnabled;

  /// When true (default), the "Start shopping" floating action button shows on
  /// the checklists screen. When false, the button is hidden and the action
  /// moves into the overflow menu instead.
  bool _startShoppingFabEnabled = true;
  bool get startShoppingFabEnabled => _startShoppingFabEnabled;

  /// When false (default), long item names wrap onto multiple lines. When true,
  /// each item name is kept to a single line and truncated with an ellipsis.
  bool _truncateItemNames = false;
  bool get truncateItemNames => _truncateItemNames;

  /// Selected list IDs for the All-lists view's per-list filter. Empty means
  /// "all lists". Local-only (not synced) so each device keeps its own focus.
  Set<int> _checklistListFilter = {};
  Set<int> get checklistListFilter => _checklistListFilter;

  /// Keys of the item-row chips the user has hidden (see [ItemChipKind]). Empty
  /// by default, so every chip is visible until the user turns one off. Stored
  /// as a hidden-set — rather than a visible-set — so the default of "show
  /// everything" needs no seeding and survives new chip kinds being added.
  Set<String> _hiddenItemChips = {};
  Set<String> get hiddenItemChips => _hiddenItemChips;
  bool isItemChipVisible(String key) => !_hiddenItemChips.contains(key);

  bool _checklistDoneCollapsed = true;
  bool get checklistDoneCollapsed => _checklistDoneCollapsed;

  /// Progress-card visibility for the synthetic All-lists view. The All-lists
  /// view has no server entity, so its toggle lives here, keyed by sentinel
  /// id 0.
  bool _allListsProgressHeroHidden = false;
  bool get allListsProgressHeroHidden => _allListsProgressHeroHidden;

  /// IDs of real lists whose progress card the user dismissed. The card is a
  /// client-only feature — the server doesn't store its visibility — so the
  /// hidden state is persisted locally and re-applied after each list refresh.
  Set<int> _progressHeroHiddenListIds = {};
  Set<int> get progressHeroHiddenListIds => _progressHeroHiddenListIds;
  bool isListProgressHeroHidden(int id) =>
      _progressHeroHiddenListIds.contains(id);

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

  /// Sections the user has hidden from the primary navigation. Never contains
  /// every section — [setNavSectionEnabled] refuses to hide the last visible
  /// one, so [enabledNavOrder] always yields at least one section.
  Set<NavSection> _navDisabled = {};
  Set<NavSection> get navDisabled => Set.unmodifiable(_navDisabled);
  bool isNavSectionEnabled(NavSection s) => !_navDisabled.contains(s);

  /// [navOrder] with hidden sections removed. This is the order actually shown
  /// in the bottom bar / rail; its first entry is opened at cold start.
  List<NavSection> get enabledNavOrder =>
      List.unmodifiable(_navOrder.where((s) => !_navDisabled.contains(s)));

  /// Last Nextcloud theme color fetched from the server, persisted as
  /// "#RRGGBB". Cached so the app can render with the right accent on a
  /// cold start before (or even without) a successful capabilities call —
  /// covers transient empty `theming` blocks and offline launches.
  String? _themeColorHex;
  String? get themeColorHex => _themeColorHex;

  /// When true (default), the app is tinted with the Nextcloud user's theme
  /// color fetched from the server. When false, the app uses its own built-in
  /// accent regardless of what the server reports.
  bool _useServerThemeColor = true;
  bool get useServerThemeColor => _useServerThemeColor;

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

  /// How often each view silently polls the server in the foreground, in
  /// seconds. 0 disables auto-refresh for that view. Shopping additionally
  /// accepts [shoppingRefreshInherit] to follow the checklist interval.
  int _checklistRefreshSeconds = 30;
  int get checklistRefreshSeconds => _checklistRefreshSeconds;

  int _notesRefreshSeconds = 60;
  int get notesRefreshSeconds => _notesRefreshSeconds;

  int _photosRefreshSeconds = 60;
  int get photosRefreshSeconds => _photosRefreshSeconds;

  int _shoppingRefreshSeconds = shoppingRefreshInherit;
  int get shoppingRefreshSeconds => _shoppingRefreshSeconds;

  /// How often the watch re-reads what it is showing, in seconds. It does not
  /// inherit [checklistRefreshSeconds]: that interval was chosen for a device
  /// on mains power with a phone's battery, and following it would put the
  /// watch's endurance in a pref set on another wrist-less screen.
  int _wearPollSeconds = 60;
  int get wearPollSeconds => _wearPollSeconds;

  /// The shopping interval with [shoppingRefreshInherit] resolved to the
  /// current checklist interval, so callers get a concrete seconds value.
  int get shoppingRefreshSecondsResolved =>
      _shoppingRefreshSeconds == shoppingRefreshInherit
      ? _checklistRefreshSeconds
      : _shoppingRefreshSeconds;

  Future<void> load() async {
    // One platform-channel round trip instead of ~17 sequential reads —
    // measurably shaves cold-start time on iOS Keychain / Android Keystore.
    final all = await _storage.readAll();

    final lastHouse = all[_lastHouseKey];
    if (lastHouse != null) _lastHouseId = int.tryParse(lastHouse);

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

    final longPressAction = all[_defaultItemLongPressActionKey];
    if (longPressAction != null && _isValidLongPressAction(longPressAction)) {
      _defaultItemLongPressAction = longPressAction;
    }

    // The category-spacing setting was replaced by grouped category headers;
    // drop any stored value as a one-time cleanup.
    if (all.containsKey(_checklistCategorySpacingKey)) {
      await _storage.delete(key: _checklistCategorySpacingKey);
    }

    final reuse = all[_reuseExistingItemsKey];
    if (reuse != null && _isValidReuseExistingItems(reuse)) {
      _reuseExistingItems = reuse;
    }

    final suggestArchived = all[_suggestArchivedItemsKey];
    if (suggestArchived != null) {
      _suggestArchivedItems = suggestArchived == 'true';
    }

    final view = all[_checklistViewKey];
    if (view != null && (view == 'list' || view == 'cards')) {
      _checklistView = view;
    }

    final checkboxPosition = all[_checklistCheckboxPositionKey];
    if (checkboxPosition != null &&
        (checkboxPosition == 'start' || checkboxPosition == 'end')) {
      _checklistCheckboxPosition = checkboxPosition;
    }

    final density = all[_checklistDensityKey];
    if (density != null && _validDensities.contains(density)) {
      _checklistDensity = density;
    }

    final swipeActions = all[_swipeActionsEnabledKey];
    if (swipeActions != null) _swipeActionsEnabled = swipeActions == 'true';

    final startShoppingFab = all[_startShoppingFabEnabledKey];
    if (startShoppingFab != null) {
      _startShoppingFabEnabled = startShoppingFab == 'true';
    }

    final truncateItemNames = all[_truncateItemNamesKey];
    if (truncateItemNames != null) {
      _truncateItemNames = truncateItemNames == 'true';
    }

    final listFilter = all[_checklistListFilterKey];
    if (listFilter != null && listFilter.isNotEmpty) {
      _checklistListFilter = listFilter
          .split(',')
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    }

    final hiddenChips = all[_hiddenItemChipsKey];
    if (hiddenChips != null && hiddenChips.isNotEmpty) {
      _hiddenItemChips = hiddenChips
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    final doneCollapsed = all[_checklistDoneCollapsedKey];
    if (doneCollapsed != null) {
      _checklistDoneCollapsed = doneCollapsed == 'true';
    }

    final progressHeroHidden = all[_allListsProgressHeroHiddenKey];
    if (progressHeroHidden != null) {
      _allListsProgressHeroHidden = progressHeroHidden == 'true';
    }

    final hiddenHeroIds = all[_progressHeroHiddenListIdsKey];
    if (hiddenHeroIds != null && hiddenHeroIds.isNotEmpty) {
      _progressHeroHiddenListIds = hiddenHeroIds
          .split(',')
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    }

    _lastSeenOnboardingVersion = all[_lastSeenOnboardingVersionKey];

    _navOrder = decodeNavOrder(all[_navOrderKey]);
    _navDisabled = decodeNavDisabled(all[_navDisabledKey]);
    // Never leave zero visible sections — guard against a corrupt or stale
    // value that hides everything.
    if (_navOrder.every(_navDisabled.contains)) _navDisabled = {};

    _themeColorHex = all[_themeColorKey];

    final useServerTheme = all[_useServerThemeColorKey];
    if (useServerTheme != null) {
      _useServerThemeColor = useServerTheme == 'true';
    }

    _displayName = all[_displayNameKey];
    _serverLanguage = all[_serverLanguageKey];
    final firstDay = all[_firstDayOfWeekKey];
    if (firstDay != null) _firstDayOfWeek = int.tryParse(firstDay);

    final devForce = all[_devForceAllFeaturesKey];
    if (devForce != null) _devForceAllFeatures = devForce == 'true';

    final checklistRefresh = int.tryParse(
      all[_checklistRefreshSecondsKey] ?? '',
    );
    if (checklistRefresh != null &&
        _validRefreshSeconds.contains(checklistRefresh)) {
      _checklistRefreshSeconds = checklistRefresh;
    }

    final notesRefresh = int.tryParse(all[_notesRefreshSecondsKey] ?? '');
    if (notesRefresh != null && _validRefreshSeconds.contains(notesRefresh)) {
      _notesRefreshSeconds = notesRefresh;
    }

    final photosRefresh = int.tryParse(all[_photosRefreshSecondsKey] ?? '');
    if (photosRefresh != null && _validRefreshSeconds.contains(photosRefresh)) {
      _photosRefreshSeconds = photosRefresh;
    }

    final shoppingRefresh = int.tryParse(all[_shoppingRefreshSecondsKey] ?? '');
    if (shoppingRefresh != null &&
        (shoppingRefresh == shoppingRefreshInherit ||
            _validRefreshSeconds.contains(shoppingRefresh))) {
      _shoppingRefreshSeconds = shoppingRefresh;
    }

    final wearPoll = int.tryParse(all[_wearPollSecondsKey] ?? '');
    if (wearPoll != null && _validRefreshSeconds.contains(wearPoll)) {
      _wearPollSeconds = wearPoll;
    }
  }

  Future<void> setLastHouseId(int id) async {
    _lastHouseId = id;
    await _storage.write(key: _lastHouseKey, value: id.toString());
    notifyListeners();
  }

  static bool _isValidTapAction(String value) =>
      value == 'done' || value == 'view' || value == 'edit' || value == 'none';

  static bool _isValidLongPressAction(String value) =>
      value == 'multiselect' ||
      value == 'done' ||
      value == 'view' ||
      value == 'edit' ||
      value == 'none';

  static bool _isValidReuseExistingItems(String value) =>
      value == 'ask' || value == 'reuse' || value == 'never';

  Future<void> setLastSeenOnboardingVersion(String? version) async {
    _lastSeenOnboardingVersion = version;
    if (version == null) {
      await _storage.delete(key: _lastSeenOnboardingVersionKey);
    } else {
      await _storage.write(key: _lastSeenOnboardingVersionKey, value: version);
    }
    notifyListeners();
  }

  Future<void> setDevForceAllFeatures(bool value) async {
    if (_devForceAllFeatures == value) return;
    _devForceAllFeatures = value;
    await _storage.write(key: _devForceAllFeaturesKey, value: value.toString());
    notifyListeners();
  }

  Future<void> clear() async {
    _lastHouseId = null;
    _notificationsEnabled = true;
    _pollIntervalMinutes = 15;
    _notificationsIntroSeen = false;
    _locale = null;
    _themeMode = null;
    _defaultItemTapAction = 'view';
    _defaultItemLongPressAction = 'multiselect';
    _reuseExistingItems = 'ask';
    _suggestArchivedItems = false;
    _checklistView = 'list';
    _checklistCheckboxPosition = 'start';
    _checklistDensity = 'normal';
    _swipeActionsEnabled = true;
    _startShoppingFabEnabled = true;
    _checklistListFilter = {};
    _hiddenItemChips = {};
    _checklistDoneCollapsed = true;
    _allListsProgressHeroHidden = false;
    _progressHeroHiddenListIds = {};
    _lastSeenOnboardingVersion = null;
    _navOrder = List.of(kDefaultNavOrder);
    _navDisabled = {};
    _themeColorHex = null;
    _useServerThemeColor = true;
    _displayName = null;
    _serverLanguage = null;
    _firstDayOfWeek = null;
    _devForceAllFeatures = false;
    _checklistRefreshSeconds = 30;
    _notesRefreshSeconds = 60;
    _photosRefreshSeconds = 60;
    _shoppingRefreshSeconds = shoppingRefreshInherit;
    _wearPollSeconds = 60;
    final keys = [
      _lastHouseKey,
      _notificationsEnabledKey,
      _pollIntervalMinutesKey,
      _notificationsIntroSeenKey,
      _localeKey,
      _themeModeKey,
      _checklistTapRowToToggleKey,
      _defaultItemTapActionKey,
      _defaultItemLongPressActionKey,
      _checklistCategorySpacingKey,
      _reuseExistingItemsKey,
      _suggestArchivedItemsKey,
      _checklistViewKey,
      _checklistCheckboxPositionKey,
      _checklistDensityKey,
      _swipeActionsEnabledKey,
      _startShoppingFabEnabledKey,
      _checklistListFilterKey,
      _hiddenItemChipsKey,
      _checklistDoneCollapsedKey,
      _allListsProgressHeroHiddenKey,
      _progressHeroHiddenListIdsKey,
      _lastSeenOnboardingVersionKey,
      _navOrderKey,
      _navDisabledKey,
      _themeColorKey,
      _useServerThemeColorKey,
      _displayNameKey,
      _serverLanguageKey,
      _firstDayOfWeekKey,
      _devForceAllFeaturesKey,
      _checklistRefreshSecondsKey,
      _notesRefreshSecondsKey,
      _photosRefreshSecondsKey,
      _shoppingRefreshSecondsKey,
      _wearPollSecondsKey,
    ];
    final futures = <Future>[];
    for (final key in keys) {
      futures.add(_storage.delete(key: key));
    }
    await Future.wait(futures);
    notifyListeners();
  }
}
