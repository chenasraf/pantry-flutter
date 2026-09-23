import 'package:flutter/material.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/markdown_preview.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

/// Where an item's description is drawn on its row, for the rows that draw one
/// at all. The setting's third value, showing nothing but the note icon, is
/// absent here: it is the case where [itemDescription] answers null.
enum ItemDescriptionPlacement {
  /// A line of its own under the item's name, with the row's full width to
  /// truncate against.
  line,

  /// Written into the note chip, among the item's other details, truncating
  /// at a width that leaves room for them beside it.
  chip,
}

/// The description [item] shows on its row and where it shows it, or null when
/// the row shows only the note icon: the setting is off, the user has turned
/// the description off in item details, the item has no description, or the
/// description carries no text to show.
///
/// A null answer is also what tells a row to fall back to the icon, so the two
/// are decided in one place rather than drifting apart.
({ItemDescriptionPlacement placement, String text})? itemDescription(
  ListItem item,
  PrefsService prefs,
) {
  final placement = switch (prefs.itemDescriptionDisplay) {
    'line' => ItemDescriptionPlacement.line,
    'chip' => ItemDescriptionPlacement.chip,
    _ => null,
  };
  if (placement == null) return null;
  if (!prefs.isItemChipVisible(ItemChipKind.note.key)) return null;
  final description = item.description;
  if (description == null || description.trim().isEmpty) return null;
  final preview = markdownPreview(description);
  if (preview.isEmpty) return null;
  return (placement: placement, text: preview);
}

/// How wide a written-out description may draw.
///
/// Uncapped the chip takes the whole width, and a [Wrap] moves a child that
/// wide onto a line of its own — costing the row the same height as the line
/// placement while showing less than the line would. Roughly half a phone row,
/// so the item's other details keep their place beside it, which is the reason
/// to pick the chip over the line at all.
///
/// A fixed width rather than a share of the row: the row's width isn't known
/// without laying it out, and a [LayoutBuilder] can't be used here — swipe rows
/// measure their children with [IntrinsicHeight], which needs a dry layout that
/// a layout callback can't answer.
const double _chipMaxWidth = 160;

/// The note chip on an item's row: its icon alone, or — when [text] is given —
/// the description written out beside it, truncated to fit the cap and carried
/// in full by a tooltip for a pointer that can hover over it.
class ItemDescriptionChip extends StatelessWidget {
  /// The description to write into the chip. Null leaves the chip its icon,
  /// which is then all that marks the item as having one.
  final String? text;

  /// Opens the description in full. Null leaves the chip inert.
  final VoidCallback? onTap;

  const ItemDescriptionChip({super.key, this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = this.text;
    final chip = EntityChip(
      // Alone the glyph carries the whole chip, so it is drawn at a size that
      // reads as one; beside text it is a label's leading icon like any other.
      leading: Icon(
        Icons.notes,
        size: text == null ? 16 : 12,
        color: cs.onSurfaceVariant,
      ),
      label: text,
      maxLines: 1,
      textColor: cs.onSurfaceVariant,
      background: cs.onSurface.withValues(alpha: 0.06),
      onTap: onTap,
    );
    if (text == null) return chip;
    return Directionality(
      // Its own direction, so a description in the other script reads from the
      // correct edge and truncates at the far one — icon included, which is
      // why this is a Directionality rather than a text setting.
      textDirection: detectTextDirection(text),
      child: Tooltip(
        message: text,
        // Hover only. A touch device reaches the description by tapping the
        // chip, which opens it in full — more than a tooltip shows, and the
        // long press a tooltip would otherwise answer to belongs to the row,
        // where it selects.
        triggerMode: TooltipTriggerMode.manual,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _chipMaxWidth),
          child: chip,
        ),
      ),
    );
  }
}

/// An item's description on one line beneath its name.
///
/// It takes the row's full width rather than sitting among the chips, which is
/// what lets it truncate late: the ellipsis lands wherever the row actually
/// runs out, on any screen, at any density or font scale, instead of at a
/// character count picked in advance that is too short on a tablet and too
/// long on a phone. The chip placement trades that width away for a row that
/// stays one line tall.
///
/// Shared so the checklist and the shopping trip read the same — what differs
/// is only whether the line takes a tap.
class ItemDescriptionLine extends StatelessWidget {
  final String text;

  /// Opens the description in full. Null leaves the line inert, for a row
  /// whose own tap is the thing the reader wants (checking an item off).
  final VoidCallback? onTap;

  const ItemDescriptionLine({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = Text(
      text,
      textDirection: detectTextDirection(text),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    if (onTap == null) return line;
    return GestureDetector(
      onTap: onTap,
      // The row beneath it already takes a tap, so the line has to claim the
      // gesture over its own text rather than only where a glyph is inked.
      behavior: HitTestBehavior.opaque,
      child: line,
    );
  }
}
