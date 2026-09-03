import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// Settings sub-screen letting the user choose which metadata chips appear on
/// checklist item rows. One switch per [ItemChipKind]; all on by default.
class ChipVisibilityView extends StatelessWidget {
  const ChipVisibilityView({super.key});

  static String _label(ItemChipKind kind) => switch (kind) {
    ItemChipKind.category => m.settings.chipNames.category,
    ItemChipKind.store => m.settings.chipNames.store,
    ItemChipKind.label => m.settings.chipNames.label,
    ItemChipKind.quantity => m.settings.chipNames.quantity,
    ItemChipKind.price => m.settings.chipNames.price,
    ItemChipKind.note => m.settings.chipNames.note,
    ItemChipKind.oneTime => m.settings.chipNames.oneTime,
    ItemChipKind.recurring => m.settings.chipNames.recurring,
    ItemChipKind.list => m.settings.chipNames.list,
  };

  static IconData _icon(ItemChipKind kind) => switch (kind) {
    ItemChipKind.category => Icons.circle,
    ItemChipKind.store => EntityIcons.store,
    ItemChipKind.label => EntityIcons.label,
    ItemChipKind.quantity => Icons.tag,
    ItemChipKind.price => EntityIcons.price,
    ItemChipKind.note => Icons.notes,
    ItemChipKind.oneTime => Icons.check_circle_outline,
    ItemChipKind.recurring => Icons.repeat,
    ItemChipKind.list => Icons.checklist,
  };

  Future<void> _resetToDefault(BuildContext context) async {
    final prefs = context.read<PrefsService>();
    for (final kind in ItemChipKind.values) {
      await prefs.setItemChipVisible(kind.key, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<PrefsService>();
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.visibleChipsTitle),
        actions: [
          TextButton(
            onPressed: () => _resetToDefault(context),
            child: Text(m.settings.visibleChipsReset),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            child: Text(
              m.settings.visibleChipsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final kind in ItemChipKind.values)
            SwitchListTile(
              secondary: Icon(_icon(kind)),
              title: Text(_label(kind)),
              value: prefs.isItemChipVisible(kind.key),
              onChanged: (value) => context
                  .read<PrefsService>()
                  .setItemChipVisible(kind.key, value),
            ),
        ],
      ),
    );
  }
}
