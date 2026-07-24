import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/locale_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/services/theming_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/settings/nav_order_view.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late String? _selectedLocale;
  late String? _selectedTheme;

  static const _pollOptions = [15, 30, 60, 120, 360];
  static const _checkboxPositionOptions = ['start', 'end'];
  static const _densityOptions = ['normal', 'dense'];
  static const _itemTapActionOptions = ['done', 'view', 'edit', 'none'];
  static const _itemLongPressActionOptions = [
    'multiselect',
    'done',
    'view',
    'edit',
    'none',
  ];
  static const _reuseExistingItemsOptions = ['ask', 'reuse', 'never'];

  @override
  void initState() {
    super.initState();
    _selectedLocale = PrefsService.instance.locale;
    _selectedTheme = PrefsService.instance.themeMode;
  }

  Future<void> _setItemTapAction(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.defaultItemTapAction) return;
    await prefs.setDefaultItemTapAction(value);
  }

  String _itemTapActionLabel(String value) => switch (value) {
    'done' => m.settings.itemTapActionNames.done,
    'edit' => m.settings.itemTapActionNames.edit,
    'none' => m.settings.itemTapActionNames.none,
    _ => m.settings.itemTapActionNames.view,
  };

  Future<void> _setItemLongPressAction(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.defaultItemLongPressAction) return;
    await prefs.setDefaultItemLongPressAction(value);
  }

  String _itemLongPressActionLabel(String value) => switch (value) {
    'multiselect' => m.settings.itemLongPressActionNames.multiselect,
    'done' => m.settings.itemLongPressActionNames.done,
    'edit' => m.settings.itemLongPressActionNames.edit,
    'none' => m.settings.itemLongPressActionNames.none,
    _ => m.settings.itemLongPressActionNames.view,
  };

  Future<void> _setCheckboxPosition(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.checklistCheckboxPosition) return;
    await prefs.setChecklistCheckboxPosition(value);
  }

  String _checkboxPositionLabel(String value) => switch (value) {
    'end' => m.settings.checkboxPositionNames.end,
    _ => m.settings.checkboxPositionNames.start,
  };

  Future<void> _setDensity(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.checklistDensity) return;
    await prefs.setChecklistDensity(value);
  }

  String _densityLabel(String value) => switch (value) {
    'dense' => m.settings.densityNames.dense,
    _ => m.settings.densityNames.normal,
  };

  Future<void> _toggleSwipeActions(bool value) async {
    await context.read<PrefsService>().setSwipeActionsEnabled(value);
  }

  // -- Reuse existing items (account-scoped, persisted server-side) --

  Future<void> _setReuseExistingItems(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    final previous = prefs.reuseExistingItems;
    if (value == previous) return;
    // Optimistic: update the local cache (rebuilds the dropdown), then push to
    // the server. Revert the cache if the server rejects it.
    await prefs.setReuseExistingItemsCache(value);
    try {
      await AuthService.instance.setReuseExistingItems(value);
    } catch (e) {
      debugPrint('[SettingsView] Failed to persist reuseExistingItems: $e');
      await prefs.setReuseExistingItemsCache(previous);
    }
  }

  String _reuseExistingItemsLabel(String value) => switch (value) {
    'reuse' => m.settings.reuseExistingItemsNames.reuse,
    'never' => m.settings.reuseExistingItemsNames.never,
    _ => m.settings.reuseExistingItemsNames.ask,
  };

  // -- Language --

  Future<void> _setLocale(String? value) async {
    await LocaleService.instance.setLocale(value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
  }

  String _localeLabel(String? code) => switch (code) {
    'en' => m.settings.languageNames.english,
    'de' => m.settings.languageNames.german,
    'es' => m.settings.languageNames.spanish,
    'fr' => m.settings.languageNames.french,
    'he' => m.settings.languageNames.hebrew,
    _ => m.settings.languageNames.system,
  };

  // -- Theme --

  Future<void> _setTheme(String? value) async {
    await ThemingService.instance.setThemeMode(value);
    if (!mounted) return;
    setState(() => _selectedTheme = value);
  }

  String _themeLabel(String? code) => switch (code) {
    'light' => m.settings.themeNames.light,
    'dark' => m.settings.themeNames.dark,
    _ => m.settings.themeNames.system,
  };

  // -- Notifications --

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await LocalNotificationsService.instance
          .requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.settings.permissionDenied)));
        }
        return;
      }
    }

    if (!mounted) return;
    await context.read<PrefsService>().setNotificationsEnabled(value);

    if (value) {
      await registerBackgroundNotificationPoll();
    } else {
      await cancelBackgroundNotificationPoll();
      await LocalNotificationsService.instance.cancelAll();
    }
  }

  Future<void> _setPollInterval(int? minutes) async {
    if (minutes == null) return;
    final prefs = context.read<PrefsService>();
    if (minutes == prefs.pollIntervalMinutes) return;
    await prefs.setPollIntervalMinutes(minutes);
    if (prefs.notificationsEnabled) {
      await rescheduleBackgroundNotificationPoll();
    }
  }

  String _pollIntervalLabel(int minutes) => switch (minutes) {
    15 => m.settings.pollInterval15m,
    30 => m.settings.pollInterval30m,
    60 => m.settings.pollInterval1h,
    120 => m.settings.pollInterval2h,
    360 => m.settings.pollInterval6h,
    _ => '$minutes min',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<PrefsService>();
    final notificationsEnabled = prefs.notificationsEnabled;
    final pollIntervalMinutes = prefs.pollIntervalMinutes;
    final itemTapAction = prefs.defaultItemTapAction;
    final itemLongPressAction = prefs.defaultItemLongPressAction;
    final checkboxPosition = prefs.checklistCheckboxPosition;
    final density = prefs.checklistDensity;
    final swipeActionsEnabled = prefs.swipeActionsEnabled;
    final reuseExistingItems = prefs.reuseExistingItems;

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.title),
      ),
      body: ListTileTheme(
        data: theme.listTileTheme.copyWith(
          subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        child: ListView(
          children: [
            // -- General --
            _SectionHeader(m.settings.generalSection),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(m.settings.language),
              subtitle: Text(_localeLabel(_selectedLocale)),
              trailing: DropdownButton<String?>(
                value: _selectedLocale,
                onChanged: (v) => _setLocale(v),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(m.settings.languageNames.system),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'en',
                    child: Text(m.settings.languageNames.english),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'de',
                    child: Text(m.settings.languageNames.german),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'es',
                    child: Text(m.settings.languageNames.spanish),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'fr',
                    child: Text(m.settings.languageNames.french),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'he',
                    child: Text(m.settings.languageNames.hebrew),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(m.settings.theme),
              subtitle: Text(_themeLabel(_selectedTheme)),
              trailing: DropdownButton<String?>(
                value: _selectedTheme,
                onChanged: (v) => _setTheme(v),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(m.settings.themeNames.system),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'light',
                    child: Text(m.settings.themeNames.light),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'dark',
                    child: Text(m.settings.themeNames.dark),
                  ),
                ],
              ),
            ),

            // -- Interface --
            _SectionHeader(m.settings.interfaceSection),
            ListTile(
              leading: const Icon(Icons.reorder),
              title: Text(m.settings.navOrderTitle),
              subtitle: Text(m.settings.navOrderSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const NavOrderView()));
              },
            ),
            if (supportsFeature('pref-tap-row-to-complete'))
              ListTile(
                leading: const Icon(Icons.touch_app_outlined),
                title: Text(m.settings.defaultItemTapAction),
                subtitle: Text(m.settings.defaultItemTapActionBody),
                trailing: DropdownButton<String>(
                  value: itemTapAction,
                  onChanged: _setItemTapAction,
                  items: [
                    for (final option in _itemTapActionOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(_itemTapActionLabel(option)),
                      ),
                  ],
                ),
              ),
            if (supportsFeature('pref-tap-row-to-complete'))
              ListTile(
                leading: const Icon(Icons.touch_app),
                title: Text(m.settings.defaultItemLongPressAction),
                subtitle: Text(m.settings.defaultItemLongPressActionBody),
                trailing: DropdownButton<String>(
                  value: itemLongPressAction,
                  onChanged: _setItemLongPressAction,
                  items: [
                    for (final option in _itemLongPressActionOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(_itemLongPressActionLabel(option)),
                      ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: Text(m.settings.checkboxPosition),
              subtitle: Text(m.settings.checkboxPositionBody),
              trailing: DropdownButton<String>(
                value: checkboxPosition,
                onChanged: _setCheckboxPosition,
                items: [
                  for (final option in _checkboxPositionOptions)
                    DropdownMenuItem(
                      value: option,
                      child: Text(_checkboxPositionLabel(option)),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.density_medium),
              title: Text(m.settings.density),
              subtitle: Text(m.settings.densityBody),
              trailing: DropdownButton<String>(
                value: density,
                onChanged: _setDensity,
                items: [
                  for (final option in _densityOptions)
                    DropdownMenuItem(
                      value: option,
                      child: Text(_densityLabel(option)),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.swipe_outlined),
              // On desktop the actions are pinned in view rather than revealed
              // by a swipe, so the swipe-specific wording doesn't apply.
              title: Text(
                PlatformInfo.isDesktop
                    ? m.settings.itemActions
                    : m.settings.swipeActions,
              ),
              subtitle: Text(
                PlatformInfo.isDesktop
                    ? m.settings.itemActionsBody
                    : m.settings.swipeActionsBody,
              ),
              value: swipeActionsEnabled,
              onChanged: _toggleSwipeActions,
            ),
            if (hasFeature('reuse-existing-items'))
              ListTile(
                leading: const Icon(Icons.autorenew),
                title: Text(m.settings.reuseExistingItems),
                subtitle: Text(m.settings.reuseExistingItemsBody),
                trailing: DropdownButton<String>(
                  value: reuseExistingItems,
                  onChanged: _setReuseExistingItems,
                  items: [
                    for (final option in _reuseExistingItemsOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(_reuseExistingItemsLabel(option)),
                      ),
                  ],
                ),
              ),

            // -- Notifications --
            if (supportsFeature('notifications')) ...[
              _SectionHeader(m.settings.notificationsSection),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(m.settings.enableNotifications),
                subtitle: Text(m.settings.enableNotificationsBody),
                value: notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              ListTile(
                enabled: notificationsEnabled,
                leading: const Icon(Icons.timer_outlined),
                title: Text(m.settings.pollInterval),
                subtitle: Text(_pollIntervalLabel(pollIntervalMinutes)),
                trailing: DropdownButton<int>(
                  value: pollIntervalMinutes,
                  onChanged: notificationsEnabled ? _setPollInterval : null,
                  items: [
                    for (final minutes in _pollOptions)
                      DropdownMenuItem(
                        value: minutes,
                        child: Text(_pollIntervalLabel(minutes)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
