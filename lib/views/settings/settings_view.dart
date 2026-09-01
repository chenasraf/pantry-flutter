import 'dart:math' as math;

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
import 'package:pantry/views/settings/chip_visibility_view.dart';
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
  static const _densityOptions = ['normal', 'dense', 'compact'];
  static const _itemTapActionOptions = ['done', 'view', 'edit', 'none'];
  static const _itemLongPressActionOptions = [
    'multiselect',
    'done',
    'view',
    'edit',
    'none',
  ];
  static const _reuseExistingItemsOptions = ['ask', 'reuse', 'never'];
  static const _refreshOptions = [0, 15, 30, 60, 120, 300];
  static const _shoppingRefreshOptions = [
    PrefsService.shoppingRefreshInherit,
    0,
    15,
    30,
    60,
    120,
    300,
  ];

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
    'compact' => m.settings.densityNames.compact,
    _ => m.settings.densityNames.normal,
  };

  Future<void> _toggleSwipeActions(bool value) async {
    await context.read<PrefsService>().setSwipeActionsEnabled(value);
  }

  Future<void> _toggleStartShoppingFab(bool value) async {
    await context.read<PrefsService>().setStartShoppingFabEnabled(value);
  }

  Future<void> _toggleTruncateItemNames(bool value) async {
    await context.read<PrefsService>().setTruncateItemNames(value);
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

  // -- Suggest archived items (account-scoped, persisted server-side) --

  Future<void> _toggleSuggestArchivedItems(bool value) async {
    final prefs = context.read<PrefsService>();
    final previous = prefs.suggestArchivedItems;
    if (value == previous) return;
    // Optimistic: flip the local cache, then push to the server; revert on
    // failure.
    await prefs.setSuggestArchivedItemsCache(value);
    try {
      await AuthService.instance.setSuggestArchivedItems(value);
    } catch (e) {
      debugPrint('[SettingsView] Failed to persist suggestArchivedItems: $e');
      await prefs.setSuggestArchivedItemsCache(previous);
    }
  }

  // -- Language --

  Future<void> _setLocale(String? value) async {
    await LocaleService.instance.setLocale(value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
  }

  String _localeLabel(String? code) =>
      languageNativeNames[code] ?? m.settings.systemLanguage;

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

  Future<void> _toggleUseServerThemeColor(bool value) async {
    await ThemingService.instance.setUseServerThemeColor(value);
  }

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

  // -- Auto-refresh intervals --

  String _refreshLabel(int seconds) => switch (seconds) {
    PrefsService.shoppingRefreshInherit => m.settings.refreshInherit,
    0 => m.settings.refreshOff,
    15 => m.settings.refresh15s,
    30 => m.settings.refresh30s,
    60 => m.settings.refresh1m,
    120 => m.settings.refresh2m,
    300 => m.settings.refresh5m,
    _ => '$seconds s',
  };

  Future<void> _setChecklistRefresh(int? seconds) async {
    if (seconds == null) return;
    await context.read<PrefsService>().setChecklistRefreshSeconds(seconds);
  }

  Future<void> _setNotesRefresh(int? seconds) async {
    if (seconds == null) return;
    await context.read<PrefsService>().setNotesRefreshSeconds(seconds);
  }

  Future<void> _setPhotosRefresh(int? seconds) async {
    if (seconds == null) return;
    await context.read<PrefsService>().setPhotosRefreshSeconds(seconds);
  }

  Future<void> _setShoppingRefresh(int? seconds) async {
    if (seconds == null) return;
    await context.read<PrefsService>().setShoppingRefreshSeconds(seconds);
  }

  Widget _refreshTile({
    required IconData icon,
    required String title,
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
  }) {
    return _DropdownSettingTile<int>(
      icon: icon,
      title: title,
      subtitle: _refreshLabel(value),
      value: value,
      options: options,
      labelOf: _refreshLabel,
      onChanged: onChanged,
    );
  }

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
    final startShoppingFabEnabled = prefs.startShoppingFabEnabled;
    final truncateItemNames = prefs.truncateItemNames;
    final reuseExistingItems = prefs.reuseExistingItems;
    final suggestArchivedItems = prefs.suggestArchivedItems;
    final useServerThemeColor = prefs.useServerThemeColor;
    final checklistRefresh = prefs.checklistRefreshSeconds;
    final notesRefresh = prefs.notesRefreshSeconds;
    final photosRefresh = prefs.photosRefreshSeconds;
    final shoppingRefresh = prefs.shoppingRefreshSeconds;

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
            _DropdownSettingTile<String?>(
              icon: Icons.language,
              title: m.settings.language,
              subtitle: _localeLabel(_selectedLocale),
              value: _selectedLocale,
              options: [
                null,
                for (final locale in supportedLocales) locale.languageCode,
              ],
              labelOf: _localeLabel,
              onChanged: _setLocale,
            ),

            _DropdownSettingTile<String?>(
              icon: Icons.palette_outlined,
              title: m.settings.theme,
              subtitle: _themeLabel(_selectedTheme),
              value: _selectedTheme,
              options: const [null, 'light', 'dark'],
              labelOf: _themeLabel,
              onChanged: _setTheme,
            ),

            SwitchListTile(
              secondary: const Icon(Icons.color_lens_outlined),
              title: Text(m.settings.useServerThemeColor),
              subtitle: Text(m.settings.useServerThemeColorBody),
              value: useServerThemeColor,
              onChanged: _toggleUseServerThemeColor,
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
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(m.settings.visibleChipsTitle),
              subtitle: Text(m.settings.visibleChipsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChipVisibilityView()),
                );
              },
            ),
            if (supportsFeature('pref-tap-row-to-complete'))
              _DropdownSettingTile<String>(
                icon: Icons.touch_app_outlined,
                title: m.settings.defaultItemTapAction,
                subtitle: m.settings.defaultItemTapActionBody,
                value: itemTapAction,
                options: _itemTapActionOptions,
                labelOf: _itemTapActionLabel,
                onChanged: _setItemTapAction,
              ),
            if (supportsFeature('pref-tap-row-to-complete'))
              _DropdownSettingTile<String>(
                icon: Icons.touch_app,
                title: m.settings.defaultItemLongPressAction,
                subtitle: m.settings.defaultItemLongPressActionBody,
                value: itemLongPressAction,
                options: _itemLongPressActionOptions,
                labelOf: _itemLongPressActionLabel,
                onChanged: _setItemLongPressAction,
              ),
            _DropdownSettingTile<String>(
              icon: Icons.check_box_outlined,
              title: m.settings.checkboxPosition,
              subtitle: m.settings.checkboxPositionBody,
              value: checkboxPosition,
              options: _checkboxPositionOptions,
              labelOf: _checkboxPositionLabel,
              onChanged: _setCheckboxPosition,
            ),
            _DropdownSettingTile<String>(
              icon: Icons.density_medium,
              title: m.settings.density,
              subtitle: m.settings.densityBody,
              value: density,
              options: _densityOptions,
              labelOf: _densityLabel,
              onChanged: _setDensity,
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
            if (hasFeature('shopping'))
              SwitchListTile(
                secondary: const Icon(Icons.shopping_cart_outlined),
                title: Text(m.settings.startShoppingButton),
                subtitle: Text(m.settings.startShoppingButtonBody),
                value: startShoppingFabEnabled,
                onChanged: _toggleStartShoppingFab,
              ),
            SwitchListTile(
              secondary: const Icon(Icons.notes_outlined),
              title: Text(m.settings.truncateItemNames),
              subtitle: Text(m.settings.truncateItemNamesBody),
              value: truncateItemNames,
              onChanged: _toggleTruncateItemNames,
            ),
            if (hasFeature('reuse-existing-items'))
              _DropdownSettingTile<String>(
                icon: Icons.autorenew,
                title: m.settings.reuseExistingItems,
                subtitle: m.settings.reuseExistingItemsBody,
                value: reuseExistingItems,
                options: _reuseExistingItemsOptions,
                labelOf: _reuseExistingItemsLabel,
                onChanged: _setReuseExistingItems,
              ),
            if (hasFeature('pref-suggest-archived-items'))
              SwitchListTile(
                secondary: const Icon(Icons.archive_outlined),
                title: Text(m.settings.suggestArchivedItems),
                subtitle: Text(m.settings.suggestArchivedItemsBody),
                value: suggestArchivedItems,
                onChanged: _toggleSuggestArchivedItems,
              ),

            // -- Auto-refresh --
            _SectionHeader(m.settings.refreshSection),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(
                m.settings.refreshSectionBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _refreshTile(
              icon: Icons.checklist_rtl,
              title: m.settings.checklistRefresh,
              value: checklistRefresh,
              options: _refreshOptions,
              onChanged: _setChecklistRefresh,
            ),
            _refreshTile(
              icon: Icons.sticky_note_2_outlined,
              title: m.settings.notesRefresh,
              value: notesRefresh,
              options: _refreshOptions,
              onChanged: _setNotesRefresh,
            ),
            _refreshTile(
              icon: Icons.photo_library_outlined,
              title: m.settings.photosRefresh,
              value: photosRefresh,
              options: _refreshOptions,
              onChanged: _setPhotosRefresh,
            ),
            _refreshTile(
              icon: Icons.shopping_cart_outlined,
              title: m.settings.shoppingRefresh,
              value: shoppingRefresh,
              options: _shoppingRefreshOptions,
              onChanged: _setShoppingRefresh,
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
              _DropdownSettingTile<int>(
                icon: Icons.timer_outlined,
                title: m.settings.pollInterval,
                subtitle: _pollIntervalLabel(pollIntervalMinutes),
                value: pollIntervalMinutes,
                options: _pollOptions,
                labelOf: _pollIntervalLabel,
                onChanged: _setPollInterval,
                enabled: notificationsEnabled,
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

/// A settings row with a value dropdown. The dropdown normally sits at the end
/// of the row, but drops below the title when the (translated) title would be
/// squeezed narrower than its longest word — which otherwise forces an ugly
/// character-by-character wrap in longer locales.
class _DropdownSettingTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const _DropdownSettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  static double _measureWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final titleStyle =
        theme.listTileTheme.titleTextStyle ?? theme.textTheme.bodyLarge!;
    final dropdownStyle = theme.textTheme.titleMedium!;

    final dropdown = DropdownButton<T>(
      value: value,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      items: [
        for (final option in options)
          DropdownMenuItem<T>(value: option, child: Text(labelOf(option))),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // Footprint of the collapsed dropdown: widest label plus its arrow,
        // capped at half the row so a long value can't crowd out the title.
        var widestLabel = 0.0;
        for (final option in options) {
          final w = _measureWidth(
            labelOf(option),
            dropdownStyle,
            textScaler,
            textDirection,
          );
          if (w > widestLabel) widestLabel = w;
        }
        const arrowWidth = 24.0;
        final dropdownWidth = math.min(
          widestLabel + arrowWidth + 8,
          maxWidth * 0.5,
        );

        // ListTile overhead beside the title: content padding (16 each side),
        // the leading icon slot (40) and the gaps around the title (16 each).
        const overhead = 16.0 + 40.0 + 16.0 + 16.0 + 16.0;
        final titleColWidth = maxWidth - overhead - dropdownWidth;

        var longestWord = 0.0;
        for (final word in title.split(RegExp(r'\s+'))) {
          final w = _measureWidth(word, titleStyle, textScaler, textDirection);
          if (w > longestWord) longestWord = w;
        }

        if (longestWord <= titleColWidth) {
          return ListTile(
            enabled: enabled,
            leading: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle!),
            trailing: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dropdownWidth),
              child: dropdown,
            ),
          );
        }

        return ListTile(
          enabled: enabled,
          titleAlignment: ListTileTitleAlignment.top,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) Text(subtitle!),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 8),
                child: dropdown,
              ),
            ],
          ),
        );
      },
    );
  }
}
