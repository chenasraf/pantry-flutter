import 'package:flutter/material.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../wear_shape.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_metrics.dart';
import 'checklists_controller.dart';
import '../widgets/wear_surfaces.dart';

/// An item, as a card on the centre-focus list of whichever page is drawing it.
///
/// One item looks like itself everywhere it appears — on the checklist, on a
/// trip's done page, on its skipped page — because they are the same item and
/// a wearer scanning for it is doing the same thing on all three. What differs
/// is the verb the page attaches and the glyph that names the state, which is
/// why [marked] and [markedIcon] are the caller's: this card knows what an
/// item looks like, never what checking one means.
///
/// [marked] is where the card is *going*, not where the item is: while an undo
/// window drains the row already reads as landed, because the window delays the
/// write and never the feedback.
class ItemCard extends StatelessWidget {
  final ListItem item;

  /// 0 on the centre line, 1 at the edge of the falloff.
  final double d;
  final ChecklistsController controller;

  /// Whether the row draws as acted on — checked, bought, skipped.
  final bool marked;

  /// The glyph that says so. A trip's skipped page is the case that needs it:
  /// a skipped item is not a checked one, and a tick would say it was.
  final IconData markedIcon;

  /// The undo window this row is holding, or null when it is holding none.
  final AnimationController? pending;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ItemCard({
    super.key,
    required this.item,
    required this.d,
    required this.controller,
    required this.marked,
    required this.pending,
    required this.onTap,
    this.markedIcon = Icons.check_circle,
    this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = WearMetrics.of(context);

    // The centre card is the only one that can afford a second line: every
    // other card is already scaled below 1 and leaving slack inside its
    // extent, so nothing has to grow for this to fit.
    final expansion = (1 - (d / 0.4)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(expansion);

    final radius = metrics.cardRadius;

    final card = DecoratedBox(
      decoration: WearSurface.card(
        context,
        fill: Color.lerp(
          scheme.surfaceContainerHighest,
          const Color(0xFF121215),
          d,
        ),
        radius: radius,
      ),
      child: Padding(
        // Tight enough that the centre card's second line still fits inside
        // the row extent: the expansion has to come out of slack the card
        // already has, or the fixed extent turns it into a gap.
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: WearShape.isRound ? 15 : 11,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  marked ? markedIcon : Icons.circle_outlined,
                  size: 16,
                  color: marked ? scheme.primary : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(item.name),
                    style: TextStyle(
                      fontSize: 15,
                      // Pinned rather than left to the font's own metrics: the
                      // card has to fit inside a fixed row extent, and an
                      // unpinned line height is the difference between fitting
                      // and the striped overflow banner.
                      height: 1.1,
                      // Weight is the one thing the scale cannot carry: a
                      // scaled regular is still a regular.
                      fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                      color: marked ? Colors.white38 : Colors.white,
                      decoration: marked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // The only place a quantity is drawn. It rides the title line
                // rather than the meta line because it is the one detail that
                // qualifies the name itself — and drawing it in both put it on
                // screen twice on every row between the centre and the edge.
                if (item.quantity != null &&
                    PrefsService.instance.isItemChipVisible(
                      ItemChipKind.quantity.key,
                    ))
                  Text(
                    item.quantity!,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
              ],
            ),
            if (expansion > 0)
              // The slot and the content shrink by the *same* factor, so the
              // chips zoom away rather than being sliced off by the edge of a
              // collapsing box.
              Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: eased,
                child: Transform.scale(
                  scale: eased,
                  alignment: AlignmentDirectional.topStart.resolve(
                    Directionality.of(context),
                  ),
                  child: Opacity(
                    opacity: eased,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 3),
                      child: _MetaLine(item: item, controller: controller),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Center(
        // Fixed, not content-sized: a card that shrinks to its one line leaves
        // the difference as dead space inside its row rather than closing the
        // list up, so every card claims its extent less the gap.
        child: SizedBox(
          height: metrics.cardHeight,
          child: UndoStroke(
            window: pending,
            color: scheme.primary,
            radius: radius,
            child: card,
          ),
        ),
      ),
    );
  }
}

/// The second line the centre card earns.
///
/// Chips are filtered by `hiddenItemChips`, which the wearer owns on this
/// device — and by what the surface already says: whichever chip names the
/// current grouping repeats its own header, the list is only named when the
/// rail is not already naming it, and quantity is absent because the title
/// line draws it on every row rather than only on this one.
///
/// They draw in the enum's own order, so what survives a clip is predictable
/// and the picker reads in the order the row does. Nothing caps the count:
/// the row clips at the card's edge, on the card the wearer is reading, and
/// the lever against it is the picker.
class _MetaLine extends StatelessWidget {
  final ListItem item;
  final ChecklistsController controller;

  const _MetaLine({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    const neutral = Color(0xFFB6B6BE);
    final prefs = PrefsService.instance;
    final grouping = controller.grouping;
    final parts = <Widget>[];

    void chip(ItemChipKind kind, Widget child) {
      if (!prefs.isItemChipVisible(kind.key)) return;
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 5));
      parts.add(child);
    }

    final category = controller.categoryOf(item);
    if (grouping != ChecklistGrouping.category && category != null) {
      final tint = parseHexColor(category.color) ?? neutral;
      chip(
        ItemChipKind.category,
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: category.name,
          leading: Icon(categoryIcon(category.icon), size: 9, color: tint),
        ),
      );
    }

    final store = controller.storeOf(item);
    if (grouping != ChecklistGrouping.store && store != null) {
      final tint = parseHexColor(store.color) ?? neutral;
      chip(
        ItemChipKind.store,
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: store.name,
          leading: Icon(storeIcon(store.icon), size: 9, color: tint),
        ),
      );
    }
    if (item.labelIds.isNotEmpty) {
      // A count, not the labels: five labels cost one short chip instead of
      // five long ones, and the id list carries the number already — so the
      // watch draws this without a label model, service or cache of its own.
      chip(
        ItemChipKind.label,
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: '${item.labelIds.length}',
          leading: const Icon(EntityIcons.label, size: 9, color: neutral),
        ),
      );
    }
    final resolved = resolveItemPrice(
      item.prices,
      controller.session?.activeStoreId,
    );
    final price = resolved == null
        ? null
        : formatPrice(
            priceType: resolved.priceType,
            priceMin: resolved.priceMin,
            priceMax: resolved.priceMax,
            priceCurrency: resolved.priceCurrency,
          );
    if (price != null) {
      chip(
        ItemChipKind.price,
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: price,
        ),
      );
    }
    if ((item.description ?? '').isNotEmpty) {
      chip(
        ItemChipKind.note,
        const EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          leading: Icon(Icons.sticky_note_2_outlined, size: 9, color: neutral),
        ),
      );
    }
    // The phone's own reading of the two flags, so one pref key means one
    // thing on both devices: a one-time item is the one that leaves the list
    // when it is checked, not merely one without a schedule.
    switch (lifecycleOf(item)) {
      case ItemLifecycle.once:
        chip(
          ItemChipKind.oneTime,
          const EntityChip(
            density: ChipDensity.dense,
            textColor: neutral,
            leading: Icon(Icons.looks_one_outlined, size: 9, color: neutral),
          ),
        );
      case ItemLifecycle.recurring:
        chip(
          ItemChipKind.recurring,
          const EntityChip(
            density: ChipDensity.dense,
            textColor: neutral,
            leading: Icon(Icons.repeat, size: 9, color: neutral),
          ),
        );
      case ItemLifecycle.staple:
        break;
    }

    final list = controller.railNamesList ? null : controller.listOf(item);
    if (list != null) {
      final tint = parseHexColor(list.color) ?? neutral;
      chip(
        ItemChipKind.list,
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: list.name,
          leading: Icon(checklistIcon(list.icon), size: 9, color: tint),
        ),
      );
    }

    // Never scrolled — it is here so a row of chips wider than the card clips
    // at the edge instead of raising an overflow. Its *height* is the chips'
    // own, so a wearer's font size is answered by a taller line rather than by
    // chips drawn through the row below.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: parts),
    );
  }
}
