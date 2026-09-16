import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/item_thumb.dart';

/// A single to-buy row.
///
/// Built from the same pieces as a checklist row — the item's picture and its
/// chips — so an item is recognised in the aisle by what it looks like on the
/// list. What differs is what a tap means: here the whole row checks the item
/// off, whatever `defaultItemTapAction` says elsewhere, because that is the one
/// thing a shopper does over and over with a phone in one hand. Reaching the
/// item itself is the trailing button's job, and no chip takes a tap, so
/// nothing in the middle of the row can swallow the gesture.
///
/// Swiping the row aside removes the item from this trip only (see [onSkip]).
class ShoppingItemRow extends StatelessWidget {
  final ListItem item;
  final ShoppingSessionController controller;
  final VoidCallback onCheck;
  final VoidCallback onSkip;
  final VoidCallback onView;

  const ShoppingItemRow({
    super.key,
    required this.item,
    required this.controller,
    required this.onCheck,
    required this.onSkip,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.watch<PrefsService>();
    // The store leg being walked, so a row shows this store's price rather than
    // always the store-less default.
    final storeContext = controller.session.activeStoreId;
    final chips = _chips(context, prefs, storeContext);

    return Dismissible(
      key: ValueKey('skip-${item.id}'),
      // End-to-start (trailing → leading) keeps the "swipe it away" gesture
      // distinct from the whole-row tap and is direction-aware for RTL.
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onSkip(),
      background: _skipBackground(theme),
      child: InkWell(
        onTap: onCheck,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 22,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 14),
              if (item.imageFileId != null) ...[
                ItemThumb(
                  houseId: controller.houseId,
                  fileId: item.imageFileId,
                  owner: item.imageUploadedBy ?? '',
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      textDirection: detectTextDirection(item.name),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(spacing: 7, runSpacing: 4, children: chips),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: m.checklists.swipeView,
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: onView,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The row's chips, in the checklist's own order and honouring the same
  /// per-chip visibility prefs.
  ///
  /// Category, store and list are left out: the category is already the header
  /// this row sits under, the store is the shop being stood in — the trip's own
  /// bar names it — and which list an item came from is not what a shopper
  /// picks it up by. Every chip here is inert, so the row keeps its tap.
  List<Widget> _chips(
    BuildContext context,
    PrefsService prefs,
    int? storeContext,
  ) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    if (prefs.isItemChipVisible(ItemChipKind.label.key)) {
      for (final models.Label label in controller.labelsFor(item)) {
        final color = parseHexColor(label.color) ?? cs.primary;
        chips.add(
          EntityChip(
            leading: Icon(labelIcon(label.icon), size: 12, color: color),
            label: label.name,
            textColor: color,
            background: color.withValues(alpha: 0.13),
          ),
        );
      }
    }

    final quantity = item.quantity;
    if (quantity != null &&
        quantity.trim().isNotEmpty &&
        prefs.isItemChipVisible(ItemChipKind.quantity.key)) {
      chips.add(
        EntityChip(
          label: quantity,
          textColor: cs.onSurfaceVariant,
          background: cs.onSurface.withValues(alpha: 0.06),
        ),
      );
    }

    if (item.hasPriceFor(storeContext) &&
        hasFeature('item-price') &&
        prefs.isItemChipVisible(ItemChipKind.price.key)) {
      chips.add(
        EntityChip(
          label: item.formattedPriceFor(storeContext)!,
          textColor: cs.onSurfaceVariant,
          background: cs.onSurface.withValues(alpha: 0.06),
        ),
      );
    }

    final description = item.description;
    if (description != null &&
        description.trim().isNotEmpty &&
        prefs.isItemChipVisible(ItemChipKind.note.key)) {
      chips.add(
        EntityChip(
          leading: Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
          textColor: cs.onSurfaceVariant,
          background: cs.onSurface.withValues(alpha: 0.06),
        ),
      );
    }

    final lifecycle = lifecycleOf(item);
    if (lifecycle == ItemLifecycle.once &&
        prefs.isItemChipVisible(ItemChipKind.oneTime.key)) {
      chips.add(
        EntityChip(
          label: m.checklists.itemTypes.onceTime,
          textColor: cs.onSurfaceVariant,
          background: cs.onSurface.withValues(alpha: 0.06),
        ),
      );
    }
    if (lifecycle == ItemLifecycle.recurring &&
        prefs.isItemChipVisible(ItemChipKind.recurring.key)) {
      chips.add(
        EntityChip(
          label: formatRrule(item.rrule ?? ''),
          textColor: cs.primary,
          background: cs.primary.withValues(alpha: 0.13),
        ),
      );
    }

    return chips;
  }

  Widget _skipBackground(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.shopping.removeFromTrip,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.remove_shopping_cart_outlined, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
