import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/theme/app_theme.dart';

import 'restock_feedback.dart';

/// The marks a checklist item linked to inventories carries, in the list and
/// in Shopping Mode alike.
extension RestockMarkers on ListItem {
  /// The quantity chip turns into the set-by-hand chip.
  bool get showsPinnedQuantity => quantityPinned && !done;

  /// The success line under a ticked item saying what the tick restocked.
  String? get restockLine {
    if (!done) return null;
    final text = restockText(restock ?? const []);
    return text == null ? null : m.stock.restock.uncheckToUndo(text);
  }

  /// Ticked off by the restock sync rather than a member: nothing linked to
  /// it needs restock any more.
  bool get noLongerNeeded => done && doneBy == null && restocks.isNotEmpty;
}

/// The small package before a linked item's name.
class RestocksMarker extends StatelessWidget {
  const RestocksMarker({super.key, required this.sources});

  final List<StockLinkSource> sources;

  @override
  Widget build(BuildContext context) {
    final text = restocksText(sources);
    return Tooltip(
      message: text,
      child: Semantics(
        label: text,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// "× 4 · set by hand" with a pin, standing in for the quantity chip of an
/// item whose quantity a member set. Tapping it hands the quantity back to
/// stock.
class PinnedQuantityChip extends StatelessWidget {
  const PinnedQuantityChip({super.key, required this.quantity, this.onClear});

  final String? quantity;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = AppSurfaces.of(context).accent;
    final q = quantity?.trim() ?? '';
    final r = m.stock.restock;
    return Tooltip(
      message: r.setByHandTooltip,
      child: EntityChip(
        leading: Icon(Icons.push_pin_outlined, size: 13, color: accent),
        label: q.isEmpty ? r.setByHandBare : r.setByHand(q),
        textColor: accent,
        background: cs.primary.withValues(alpha: 0.12),
        trailing: onClear == null
            ? null
            : Icon(Icons.close, size: 13, color: accent),
        onTap: onClear,
      ),
    );
  }
}

/// The line under a checklist item's name: what its tick restocked, or that
/// the restock sync ticked it off.
class RestockStatusLine extends StatelessWidget {
  const RestockStatusLine({super.key, required this.item});

  final ListItem item;

  static bool showsFor(ListItem item) =>
      item.restockLine != null || item.noLongerNeeded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = item.restockLine;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: line != null
          ? AppSurfaces.of(context).success
          : theme.colorScheme.onSurfaceVariant,
    );
    return Text(line ?? m.stock.restock.noLongerNeeded, style: style);
  }
}
