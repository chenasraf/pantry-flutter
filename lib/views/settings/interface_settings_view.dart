import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/views/settings/chip_visibility_view.dart';
import 'package:pantry/views/settings/nav_order_view.dart';
import 'package:pantry/views/settings/settings_tiles.dart';

class InterfaceSettingsView extends StatelessWidget {
  /// Drawn beside the settings sidebar rather than as a screen of its own, so
  /// the row naming it is already on show and a bar repeating that name is
  /// chrome for nothing.
  final bool embedded;

  const InterfaceSettingsView({super.key, this.embedded = false});

  static const _checkboxPositionOptions = ['start', 'end'];
  static const _composeBarPositionOptions = ['bottom', 'top'];
  static const _densityOptions = ['normal', 'dense', 'compact'];
  static const _itemDescriptionOptions = ['off', 'line', 'chip'];
  static const _itemTapActionOptions = ['done', 'view', 'edit', 'none'];
  static const _itemLongPressActionOptions = [
    'multiselect',
    'done',
    'view',
    'edit',
    'none',
  ];
  static const _reuseExistingItemsOptions = ['ask', 'reuse', 'never'];

  static Future<void> _setItemTapAction(
    BuildContext context,
    String? value,
  ) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.defaultItemTapAction) return;
    await prefs.setDefaultItemTapAction(value);
  }

  static String _itemTapActionLabel(String value) => switch (value) {
    'done' => m.settings.itemTapActionNames.done,
    'edit' => m.settings.itemTapActionNames.edit,
    'none' => m.settings.itemTapActionNames.none,
    _ => m.settings.itemTapActionNames.view,
  };

  static Future<void> _setItemLongPressAction(
    BuildContext context,
    String? value,
  ) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.defaultItemLongPressAction) return;
    await prefs.setDefaultItemLongPressAction(value);
  }

  static String _itemLongPressActionLabel(String value) => switch (value) {
    'multiselect' => m.settings.itemLongPressActionNames.multiselect,
    'done' => m.settings.itemLongPressActionNames.done,
    'edit' => m.settings.itemLongPressActionNames.edit,
    'none' => m.settings.itemLongPressActionNames.none,
    _ => m.settings.itemLongPressActionNames.view,
  };

  static Future<void> _setCheckboxPosition(
    BuildContext context,
    String? value,
  ) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.checklistCheckboxPosition) return;
    await prefs.setChecklistCheckboxPosition(value);
  }

  static String _checkboxPositionLabel(String value) => switch (value) {
    'end' => m.settings.checkboxPositionNames.end,
    _ => m.settings.checkboxPositionNames.start,
  };

  static Future<void> _setComposeBarPosition(
    BuildContext context,
    String? value,
  ) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.composeBarPosition) return;
    await prefs.setComposeBarPosition(value);
  }

  static String _composeBarPositionLabel(String value) => switch (value) {
    'top' => m.settings.composeBarPositionNames.top,
    _ => m.settings.composeBarPositionNames.bottom,
  };

  static Future<void> _setDensity(BuildContext context, String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.checklistDensity) return;
    await prefs.setChecklistDensity(value);
  }

  static String _densityLabel(String value) => switch (value) {
    'dense' => m.settings.densityNames.dense,
    'compact' => m.settings.densityNames.compact,
    _ => m.settings.densityNames.normal,
  };

  static Future<void> _setItemDescription(
    BuildContext context,
    String? value,
  ) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.itemDescriptionDisplay) return;
    await prefs.setItemDescriptionDisplay(value);
  }

  static String _itemDescriptionLabel(String value) => switch (value) {
    'line' => m.settings.itemDescriptionNames.line,
    'chip' => m.settings.itemDescriptionNames.chip,
    _ => m.settings.itemDescriptionNames.off,
  };

  // -- Reuse existing items (account-scoped, persisted server-side) --

  static Future<void> _setReuseExistingItems(
    BuildContext context,
    String? value,
  ) async {
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
      debugPrint(
        '[InterfaceSettingsView] Failed to persist '
        'reuseExistingItems: $e',
      );
      await prefs.setReuseExistingItemsCache(previous);
    }
  }

  static String _reuseExistingItemsLabel(String value) => switch (value) {
    'reuse' => m.settings.reuseExistingItemsNames.reuse,
    'never' => m.settings.reuseExistingItemsNames.never,
    _ => m.settings.reuseExistingItemsNames.ask,
  };

  // -- Suggest archived items (account-scoped, persisted server-side) --

  static Future<void> _toggleSuggestArchivedItems(
    BuildContext context,
    bool value,
  ) async {
    final prefs = context.read<PrefsService>();
    final previous = prefs.suggestArchivedItems;
    if (value == previous) return;
    // Optimistic: flip the local cache, then push to the server; revert on
    // failure.
    await prefs.setSuggestArchivedItemsCache(value);
    try {
      await AuthService.instance.setSuggestArchivedItems(value);
    } catch (e) {
      debugPrint(
        '[InterfaceSettingsView] Failed to persist '
        'suggestArchivedItems: $e',
      );
      await prefs.setSuggestArchivedItemsCache(previous);
    }
  }

  /// A header plus its rows, or nothing at all when the server or platform
  /// leaves the section without a single row.
  static List<Widget> _section(String title, List<Widget> rows) =>
      rows.isEmpty ? const [] : [SettingsSectionHeader(title), ...rows];

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();

    final navigation = <Widget>[
      SettingsPageTile(
        icon: Icons.reorder,
        title: m.settings.navOrderTitle,
        subtitle: m.settings.navOrderSubtitle,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NavOrderView())),
      ),
      if (hasFeature('shopping'))
        SwitchListTile(
          secondary: const Icon(Icons.shopping_cart_outlined),
          title: Text(m.settings.startShoppingButton),
          subtitle: Text(m.settings.startShoppingButtonBody),
          value: prefs.startShoppingFabEnabled,
          onChanged: (value) =>
              context.read<PrefsService>().setStartShoppingFabEnabled(value),
        ),
    ];

    final lists = <Widget>[
      DropdownSettingTile<String>(
        icon: Icons.density_medium,
        title: m.settings.density,
        subtitle: m.settings.densityBody,
        value: prefs.checklistDensity,
        options: _densityOptions,
        labelOf: _densityLabel,
        onChanged: (value) => _setDensity(context, value),
      ),
      DropdownSettingTile<String>(
        icon: Icons.check_box_outlined,
        title: m.settings.checkboxPosition,
        subtitle: m.settings.checkboxPositionBody,
        value: prefs.checklistCheckboxPosition,
        options: _checkboxPositionOptions,
        labelOf: _checkboxPositionLabel,
        onChanged: (value) => _setCheckboxPosition(context, value),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.notes_outlined),
        title: Text(m.settings.truncateItemNames),
        subtitle: Text(m.settings.truncateItemNamesBody),
        value: prefs.truncateItemNames,
        onChanged: (value) =>
            context.read<PrefsService>().setTruncateItemNames(value),
      ),
      DropdownSettingTile<String>(
        icon: Icons.subject,
        title: m.settings.itemDescription,
        subtitle: m.settings.itemDescriptionBody,
        value: prefs.itemDescriptionDisplay,
        options: _itemDescriptionOptions,
        labelOf: _itemDescriptionLabel,
        onChanged: (value) => _setItemDescription(context, value),
      ),
      SettingsPageTile(
        icon: Icons.label_outline,
        title: m.settings.visibleChipsTitle,
        subtitle: m.settings.visibleChipsSubtitle,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChipVisibilityView())),
      ),
    ];

    final itemActions = <Widget>[
      if (supportsFeature('pref-tap-row-to-complete')) ...[
        DropdownSettingTile<String>(
          icon: Icons.touch_app_outlined,
          title: m.settings.defaultItemTapAction,
          subtitle: m.settings.defaultItemTapActionBody,
          value: prefs.defaultItemTapAction,
          options: _itemTapActionOptions,
          labelOf: _itemTapActionLabel,
          onChanged: (value) => _setItemTapAction(context, value),
        ),
        DropdownSettingTile<String>(
          icon: Icons.touch_app,
          title: m.settings.defaultItemLongPressAction,
          subtitle: m.settings.defaultItemLongPressActionBody,
          value: prefs.defaultItemLongPressAction,
          options: _itemLongPressActionOptions,
          labelOf: _itemLongPressActionLabel,
          onChanged: (value) => _setItemLongPressAction(context, value),
        ),
      ],
      SwitchListTile(
        secondary: const Icon(Icons.swipe_outlined),
        // On desktop the actions are pinned in view rather than revealed by a
        // swipe, so the swipe-specific wording doesn't apply.
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
        value: prefs.swipeActionsEnabled,
        onChanged: (value) =>
            context.read<PrefsService>().setSwipeActionsEnabled(value),
      ),
    ];

    final adding = <Widget>[
      // Mobile keeps the bar pinned to the bottom, where the keyboard rises to
      // meet it.
      if (PlatformInfo.isDesktop)
        DropdownSettingTile<String>(
          icon: Icons.vertical_align_bottom,
          title: m.settings.composeBarPosition,
          subtitle: m.settings.composeBarPositionBody,
          value: prefs.composeBarPosition,
          options: _composeBarPositionOptions,
          labelOf: _composeBarPositionLabel,
          onChanged: (value) => _setComposeBarPosition(context, value),
        ),
      if (hasFeature('reuse-existing-items'))
        DropdownSettingTile<String>(
          icon: Icons.autorenew,
          title: m.settings.reuseExistingItems,
          subtitle: m.settings.reuseExistingItemsBody,
          value: prefs.reuseExistingItems,
          options: _reuseExistingItemsOptions,
          labelOf: _reuseExistingItemsLabel,
          onChanged: (value) => _setReuseExistingItems(context, value),
        ),
      if (hasFeature('pref-suggest-archived-items'))
        SwitchListTile(
          secondary: const Icon(Icons.archive_outlined),
          title: Text(m.settings.suggestArchivedItems),
          subtitle: Text(m.settings.suggestArchivedItemsBody),
          value: prefs.suggestArchivedItems,
          onChanged: (value) => _toggleSuggestArchivedItems(context, value),
        ),
    ];

    return Scaffold(
      appBar: embedded
          ? null
          : AppBar(title: Text(m.settings.interfaceSection)),
      body: SettingsList(
        children: [
          ..._section(m.settings.interfaceNavigationSection, navigation),
          ..._section(m.settings.interfaceListsSection, lists),
          ..._section(m.settings.interfaceItemActionsSection, itemActions),
          ..._section(m.settings.interfaceAddingSection, adding),
        ],
      ),
    );
  }
}
