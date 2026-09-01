import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/item_chip.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/label_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/views/checklists/checklist_density.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/widgets/avif_image.dart';
import 'package:pantry/widgets/description_detail_dialog.dart';
import 'package:pantry/widgets/member_avatar.dart';
import 'package:pantry/widgets/store_detail_dialog.dart';
import 'swipe_reveal_row.dart';

/// Row layout used when swipe actions are turned off: the item content fills
/// the row and a trailing overflow menu button exposes the same actions the
/// swipe gesture would have revealed, with the same icons and colors.
class ChecklistTileOverflowMenuRow extends StatelessWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final ChecklistDensity density;

  const ChecklistTileOverflowMenuRow({
    super.key,
    required this.child,
    required this.actions,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Row(
        children: [
          Expanded(child: child),
          PopupMenuButton<VoidCallback>(
            tooltip: m.checklists.moreActions,
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            iconSize: density.overflowIconSize,
            onSelected: (onPressed) => onPressed(),
            itemBuilder: (context) => [
              for (final a in actions)
                PopupMenuItem<VoidCallback>(
                  value: a.onPressed,
                  child: Row(
                    children: [
                      Icon(a.icon, size: 20, color: a.tint),
                      const SizedBox(width: 12),
                      Text(a.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChecklistTileRowContent extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final Color catColor;
  final int houseId;
  final bool isCardsView;
  final bool trashMode;
  final bool archiveMode;
  final ChecklistDensity density;
  final String? addedByUserId;
  final String? addedByDisplayName;
  final ItemListBadge? listBadge;
  final bool hideCategory;
  final int? priceStoreContext;
  final VoidCallback? onCheckboxTap;
  final VoidCallback? onRowTap;
  final VoidCallback? onRowLongPress;
  final bool selectionMode;
  final bool selected;

  /// Read-only reuse suggestion: omit the leading checkbox entirely and let the
  /// row's background stay transparent so it blends into the suggestions panel.
  final bool suggestion;

  /// Suggestion drawn from the archive: adds the trailing "Archived" badge.
  final bool archived;

  const ChecklistTileRowContent({
    super.key,
    required this.item,
    required this.category,
    required this.stores,
    required this.labels,
    required this.catColor,
    required this.houseId,
    required this.isCardsView,
    required this.trashMode,
    required this.archiveMode,
    required this.density,
    required this.addedByUserId,
    required this.addedByDisplayName,
    required this.listBadge,
    required this.hideCategory,
    this.priceStoreContext,
    required this.onCheckboxTap,
    required this.onRowTap,
    required this.onRowLongPress,
    required this.selectionMode,
    required this.selected,
    this.suggestion = false,
    this.archived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final checked = item.done;
    final prefs = context.watch<PrefsService>();
    final checkboxAtEnd = prefs.checklistCheckboxPosition == 'end';

    final nameStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w600,
      color: checked ? cs.onSurfaceVariant : cs.onSurface,
      decoration: checked ? TextDecoration.lineThrough : null,
    );

    // Spacing is folded into the checkbox's tap target so taps around the box
    // toggle the item instead of falling through to the row's Edit action.
    final checkboxPadding = checkboxAtEnd
        ? const EdgeInsetsDirectional.only(start: 14, end: 16)
        : const EdgeInsetsDirectional.only(start: 18, end: 14);

    // In selection mode the done-checkbox is replaced by a selection circle;
    // the whole row toggles selection, so the circle itself needs no tap.
    final Widget leadingControl = selectionMode
        ? Padding(
            padding: checkboxPadding,
            child: Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 24,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          )
        : _Checkbox(
            checked: checked,
            trashMode: trashMode,
            archiveMode: archiveMode,
            accent: cs.primary,
            onTap: onCheckboxTap,
            disabled: onCheckboxTap == null && !trashMode && !archiveMode,
            // Shorter tap target in denser modes so single-line rows don't
            // reserve the full 48px Material height.
            hitHeight: density.checkboxHitHeight,
            padding: checkboxPadding,
          );

    return Material(
      color: suggestion
          ? Colors.transparent
          : selectionMode && selected
          ? Color.alphaBlend(cs.primary.withValues(alpha: 0.12), cs.surface)
          : cs.surface,
      child: InkWell(
        onTap: onRowTap,
        onLongPress: onRowLongPress,
        child: Stack(
          children: [
            if (isCardsView)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: catColor),
              ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                (suggestion || checkboxAtEnd) ? 18 : 0,
                density.rowPadV,
                (suggestion || !checkboxAtEnd) ? 16 : 0,
                density.rowPadV,
              ),
              child: Row(
                children: [
                  if (!checkboxAtEnd && !suggestion) leadingControl,
                  if (item.imageFileId != null) ...[
                    _ItemThumb(
                      houseId: houseId,
                      fileId: item.imageFileId!,
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
                          style: nameStyle,
                          maxLines: prefs.truncateItemNames ? 1 : null,
                          overflow: prefs.truncateItemNames
                              ? TextOverflow.ellipsis
                              : null,
                        ),
                        if (_hasMeta(prefs)) ...[
                          SizedBox(height: density.metaGap),
                          _MetaRow(
                            item: item,
                            category: hideCategory ? null : category,
                            stores: stores,
                            labels: labels,
                            catColor: catColor,
                            listBadge: listBadge,
                            priceStoreContext: priceStoreContext,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (addedByUserId != null && addedByUserId!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    MemberAvatar(
                      userId: addedByUserId,
                      displayName: addedByDisplayName ?? addedByUserId!,
                      size: 26,
                    ),
                  ],
                  if (suggestion && archived) ...[
                    const SizedBox(width: 10),
                    _Chip(
                      leading: Icon(
                        Icons.archive_outlined,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      label: m.checklists.reuse.archivedBadge,
                      textColor: cs.onSurfaceVariant,
                      background: cs.surfaceContainerHighest,
                    ),
                  ],
                  if (checkboxAtEnd && !suggestion) leadingControl,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMeta(PrefsService prefs) {
    final hasCat =
        category != null &&
        !hideCategory &&
        prefs.isItemChipVisible(ItemChipKind.category.key);
    final hasStores =
        stores.isNotEmpty && prefs.isItemChipVisible(ItemChipKind.store.key);
    final hasLabels =
        labels.isNotEmpty && prefs.isItemChipVisible(ItemChipKind.label.key);
    final hasQty =
        item.quantity != null &&
        item.quantity!.trim().isNotEmpty &&
        prefs.isItemChipVisible(ItemChipKind.quantity.key);
    final hasPrice =
        item.hasPriceFor(priceStoreContext) &&
        hasFeature('item-price') &&
        prefs.isItemChipVisible(ItemChipKind.price.key);
    final hasDesc =
        item.description != null &&
        item.description!.trim().isNotEmpty &&
        prefs.isItemChipVisible(ItemChipKind.note.key);
    final lc = lifecycleOf(item);
    final hasType =
        (lc == ItemLifecycle.once &&
            prefs.isItemChipVisible(ItemChipKind.oneTime.key)) ||
        (lc == ItemLifecycle.recurring &&
            prefs.isItemChipVisible(ItemChipKind.recurring.key));
    final hasList =
        listBadge != null && prefs.isItemChipVisible(ItemChipKind.list.key);
    return hasCat ||
        hasStores ||
        hasLabels ||
        hasQty ||
        hasPrice ||
        hasDesc ||
        hasType ||
        hasList;
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final bool trashMode;
  final bool archiveMode;
  final Color accent;
  final VoidCallback? onTap;

  /// Greys the box and ignores taps — the user lacks `canCheckItems`.
  final bool disabled;

  /// Padding folded into the tap target. The opaque hit area covers the box,
  /// this padding, and the full 48px height, so taps around the box still
  /// toggle the item.
  final EdgeInsetsDirectional padding;

  /// Height of the tap target. The 24px box is centered within it. Normally
  /// Material's 48px minimum; dense mode trims it to fit more rows.
  final double hitHeight;

  const _Checkbox({
    required this.checked,
    required this.trashMode,
    required this.archiveMode,
    required this.accent,
    required this.onTap,
    required this.padding,
    required this.hitHeight,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final boxAccent = disabled ? cs.onSurface.withValues(alpha: 0.38) : accent;
    final boxBorder = disabled
        ? cs.outlineVariant.withValues(alpha: 0.5)
        : null;
    final Widget visual = trashMode
        ? Icon(Icons.delete_outline, color: cs.onSurfaceVariant, size: 22)
        : archiveMode
        ? Icon(Icons.archive_outlined, color: cs.onSurfaceVariant, size: 22)
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: checked ? boxAccent : Colors.transparent,
              border: checked
                  ? Border.all(color: boxAccent, width: 2)
                  : Border.all(color: boxBorder ?? cs.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          );
    return GestureDetector(
      onTap: trashMode || archiveMode ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding,
        // Fixed height (not a flex/stretch fill) so the tap target stays
        // valid even where the row's own height is unbounded (e.g. cards
        // view). widthFactor keeps the cell only as wide as the box.
        child: SizedBox(
          height: hitHeight,
          child: Center(widthFactor: 1, child: visual),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final Color catColor;
  final ItemListBadge? listBadge;
  final int? priceStoreContext;

  const _MetaRow({
    required this.item,
    required this.category,
    required this.stores,
    required this.labels,
    required this.catColor,
    required this.listBadge,
    this.priceStoreContext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prefs = context.watch<PrefsService>();
    final lc = lifecycleOf(item);
    // List chip is rendered first — it answers "where does this live?" before
    // the user reads any other metadata.
    final listColor = listBadge != null
        ? (parseHexColor(listBadge!.color) ?? cs.primary)
        : cs.primary;

    return Wrap(
      spacing: 7,
      runSpacing: 4,
      children: [
        if (listBadge != null && prefs.isItemChipVisible(ItemChipKind.list.key))
          _Chip(
            leading: Icon(
              checklistIcon(listBadge!.icon),
              size: 12,
              color: listColor,
            ),
            label: listBadge!.name,
            textColor: listColor,
            background: listColor.withValues(alpha: 0.13),
          ),
        if (category != null &&
            prefs.isItemChipVisible(ItemChipKind.category.key))
          _Chip(
            leading: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
            ),
            label: category!.name,
            textColor: catColor,
            background: catColor.withValues(alpha: 0.13),
          ),
        if (prefs.isItemChipVisible(ItemChipKind.store.key))
          for (final s in stores)
            _Chip(
              leading: Icon(
                storeIcon(s.icon),
                size: 12,
                color: parseHexColor(s.color) ?? cs.primary,
              ),
              label: s.name,
              textColor: parseHexColor(s.color) ?? cs.primary,
              background: (parseHexColor(s.color) ?? cs.primary).withValues(
                alpha: 0.13,
              ),
              onTap: () => showStoreDetails(context, s),
            ),
        if (prefs.isItemChipVisible(ItemChipKind.label.key))
          for (final l in labels)
            _Chip(
              leading: Icon(
                labelIcon(l.icon),
                size: 12,
                color: parseHexColor(l.color) ?? cs.primary,
              ),
              label: l.name,
              textColor: parseHexColor(l.color) ?? cs.primary,
              background: (parseHexColor(l.color) ?? cs.primary).withValues(
                alpha: 0.13,
              ),
            ),
        if (item.quantity != null &&
            item.quantity!.trim().isNotEmpty &&
            prefs.isItemChipVisible(ItemChipKind.quantity.key))
          _Chip(
            label: item.quantity!,
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (item.hasPriceFor(priceStoreContext) &&
            hasFeature('item-price') &&
            prefs.isItemChipVisible(ItemChipKind.price.key))
          _Chip(
            label: item.formattedPriceFor(priceStoreContext)!,
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (item.description != null &&
            item.description!.trim().isNotEmpty &&
            prefs.isItemChipVisible(ItemChipKind.note.key))
          _Chip(
            leading: Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
            onTap: () {
              final controller = context.read<ChecklistsController>();
              final canToggle =
                  controller.isItemWritable(item) &&
                  controller.permissions.canEditLists;
              showItemDescription(
                context,
                item.description!,
                onChanged: canToggle
                    ? (updated) =>
                          controller.updateItem(item, description: updated)
                    : null,
              );
            },
          ),
        if (lc == ItemLifecycle.once &&
            prefs.isItemChipVisible(ItemChipKind.oneTime.key))
          _Chip(
            label: m.checklists.itemTypes.onceTime,
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (lc == ItemLifecycle.recurring &&
            prefs.isItemChipVisible(ItemChipKind.recurring.key))
          _Chip(
            label: _recurringLabel(item),
            textColor: cs.primary,
            background: cs.primary.withValues(alpha: 0.13),
          ),
      ],
    );
  }

  static String _recurringLabel(ListItem item) {
    final rrule = item.rrule ?? '';
    final summary = formatRrule(rrule);
    return summary;
  }
}

class _Chip extends StatelessWidget {
  final Widget? leading;

  /// Chip caption. When null the chip renders as an icon-only badge (used by
  /// the description chip), so the leading icon carries the whole meaning.
  final String? label;
  final Color textColor;
  final Color background;

  /// When set, the chip becomes tappable (used by the store chip to open the
  /// store details view). Other chips stay inert.
  final VoidCallback? onTap;

  const _Chip({
    this.leading,
    this.label,
    required this.textColor,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;
    final radius = BorderRadius.circular(7);
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: hasLabel ? 9 : 6, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            if (hasLabel) const SizedBox(width: 6),
          ],
          if (hasLabel)
            Text(
              label!,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  final int houseId;
  final int fileId;
  final String owner;

  const _ItemThumb({
    required this.houseId,
    required this.fileId,
    required this.owner,
  });

  @override
  Widget build(BuildContext context) {
    final uri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      fileId,
      owner,
      size: 96,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AvifNetworkImage(
        imageUrl: uri.toString(),
        headers: headers,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: 40,
          height: 40,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined, size: 18),
        ),
      ),
    );
  }
}
