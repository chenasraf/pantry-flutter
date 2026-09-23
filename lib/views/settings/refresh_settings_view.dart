import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry/views/settings/settings_tiles.dart';

class RefreshSettingsView extends StatelessWidget {
  /// Drawn beside the settings sidebar rather than as a screen of its own, so
  /// the row naming it is already on show and a bar repeating that name is
  /// chrome for nothing.
  final bool embedded;

  const RefreshSettingsView({super.key, this.embedded = false});

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

  static String _refreshLabel(int seconds) => switch (seconds) {
    PrefsService.shoppingRefreshInherit => m.settings.refreshInherit,
    0 => m.settings.refreshOff,
    15 => m.settings.refresh15s,
    30 => m.settings.refresh30s,
    60 => m.settings.refresh1m,
    120 => m.settings.refresh2m,
    300 => m.settings.refresh5m,
    _ => '$seconds s',
  };

  static Widget _refreshTile({
    required IconData icon,
    required String title,
    required int value,
    required List<int> options,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownSettingTile<int>(
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
    final prefs = context.watch<PrefsService>();

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(m.settings.refreshSection)),
      body: SettingsList(
        children: [
          const SizedBox(height: 16),
          SettingsSectionBody(m.settings.refreshSectionBody),
          _refreshTile(
            icon: EntityIcons.checklists,
            title: m.settings.checklistRefresh,
            value: prefs.checklistRefreshSeconds,
            options: _refreshOptions,
            onChanged: (seconds) {
              if (seconds == null) return;
              context.read<PrefsService>().setChecklistRefreshSeconds(seconds);
            },
          ),
          _refreshTile(
            icon: EntityIcons.notes,
            title: m.settings.notesRefresh,
            value: prefs.notesRefreshSeconds,
            options: _refreshOptions,
            onChanged: (seconds) {
              if (seconds == null) return;
              context.read<PrefsService>().setNotesRefreshSeconds(seconds);
            },
          ),
          _refreshTile(
            icon: EntityIcons.photos,
            title: m.settings.photosRefresh,
            value: prefs.photosRefreshSeconds,
            options: _refreshOptions,
            onChanged: (seconds) {
              if (seconds == null) return;
              context.read<PrefsService>().setPhotosRefreshSeconds(seconds);
            },
          ),
          _refreshTile(
            icon: Icons.shopping_cart_outlined,
            title: m.settings.shoppingRefresh,
            value: prefs.shoppingRefreshSeconds,
            options: _shoppingRefreshOptions,
            onChanged: (seconds) {
              if (seconds == null) return;
              context.read<PrefsService>().setShoppingRefreshSeconds(seconds);
            },
          ),
        ],
      ),
    );
  }
}
