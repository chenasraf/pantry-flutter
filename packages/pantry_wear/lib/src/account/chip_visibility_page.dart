import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/entity_icons.dart';

import '../widgets/wear_choice_page.dart';

/// How many of the nine a checklist row is currently allowed to draw.
int visibleChipCount() => ItemChipKind.values
    .where((kind) => PrefsService.instance.isItemChipVisible(kind.key))
    .length;

/// Which details a checklist row draws, chosen on the watch for the watch.
///
/// The set arrives seeded from the phone at pairing and belongs to the wearer
/// from then on. `PrefsService` here is this device's own storage, so a change
/// reaches nothing else by construction — the phone keeps its own choice, and
/// only a fresh pair seeds this one again.
class ChipVisibilityPage extends StatelessWidget {
  const ChipVisibilityPage({super.key});

  /// The glyph the row itself draws, wherever the row draws one, so the
  /// picker is read against the thing it governs rather than against a second
  /// vocabulary for the same nine.
  static IconData _icon(ItemChipKind kind) => switch (kind) {
    ItemChipKind.category => EntityIcons.category,
    ItemChipKind.store => EntityIcons.store,
    ItemChipKind.label => EntityIcons.label,
    ItemChipKind.quantity => Icons.tag,
    ItemChipKind.price => EntityIcons.price,
    ItemChipKind.note => EntityIcons.notes,
    ItemChipKind.oneTime => Icons.looks_one_outlined,
    ItemChipKind.recurring => Icons.repeat,
    ItemChipKind.list => EntityIcons.checklists,
  };

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

  /// Written through the phone's own per-kind setter, so the stored format is
  /// the same string on both devices and a later pair can seed from it.
  static Future<void> _write(Set<ItemChipKind> visible) async {
    final prefs = PrefsService.instance;
    for (final kind in ItemChipKind.values) {
      final wanted = visible.contains(kind);
      if (prefs.isItemChipVisible(kind.key) == wanted) continue;
      await prefs.setItemChipVisible(kind.key, wanted);
    }
  }

  @override
  Widget build(BuildContext context) => WearMultiChoicePage<ItemChipKind>(
    empty: '',
    selected: {
      for (final kind in ItemChipKind.values)
        if (PrefsService.instance.isItemChipVisible(kind.key)) kind,
    },
    onChanged: (visible) => unawaited(_write(visible)),
    choices: [
      for (final kind in ItemChipKind.values)
        WearChoice(value: kind, label: _label(kind), icon: _icon(kind)),
    ],
  );
}
