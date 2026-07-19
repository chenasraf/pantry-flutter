import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/views/checklists/checklist_switcher_sheet.dart'
    show parseHexColor;
import 'package:pantry/widgets/member_avatar.dart';
import 'swipe_reveal_row.dart';

/// Lightweight pointer to the list an item belongs to, used by the All-lists
/// view to render a per-item chip identifying its parent list.
class ItemListBadge {
  final String name;
  final String icon;
  final String? color;
  const ItemListBadge({required this.name, required this.icon, this.color});
}

/// Item lifecycle as expressed by the design's chip:
/// - staple: stays on list after completion (no rrule, deleteOnDone=false)
/// - once: removed once completed (no rrule, deleteOnDone=true)
/// - recurring: returns on a schedule (rrule set; deleteOnDone preserved as-is)
enum ItemLifecycle { staple, once, recurring }

ItemLifecycle lifecycleOf(ListItem item) {
  if (item.rrule != null && item.rrule!.isNotEmpty) {
    return ItemLifecycle.recurring;
  }
  if (item.deleteOnDone) return ItemLifecycle.once;
  return ItemLifecycle.staple;
}

class ChecklistItemTile extends StatefulWidget {
  final ListItem item;
  final models.Category? category;
  final int houseId;
  final bool isCardsView;
  final bool trashMode;
  final bool archiveMode;
  final ValueChanged<ListItem> onToggle;
  final ValueChanged<ListItem> onView;

  /// Edit the item's fields. Null when the user lacks the edit-lists
  /// capability — the edit swipe action and tap-to-edit fall back to view.
  final ValueChanged<ListItem>? onEdit;

  /// When false, the done/undone checkbox is shown but disabled (greyed).
  /// Mirrors `canCheckItems`: viewing is allowed, toggling completion is not.
  final bool canCheck;
  final ValueChanged<ListItem>? onMove;
  final ValueChanged<ListItem>? onCopy;
  final ValueChanged<ListItem>? onDelete;
  final ValueChanged<ListItem>? onRestore;
  final ValueChanged<ListItem>? onPermanentDelete;

  /// Archive an active item / return an archived one. [onArchive] appears as a
  /// swipe action in the active view; [onUnarchive] in the archive view.
  final ValueChanged<ListItem>? onArchive;
  final ValueChanged<ListItem>? onUnarchive;

  /// When non-null, render the author's avatar at the trailing end of the
  /// row. Controlled by the user's "Show who added each item" preference and
  /// gated on the item actually having an `addedBy` value.
  final String? addedByUserId;
  final String? addedByDisplayName;

  /// When non-null (the All-lists view), render a chip identifying the list
  /// this item belongs to. Suppressed in per-list views where it would be
  /// redundant.
  final ItemListBadge? listBadge;

  /// Suppress the per-row category chip. Set while the list is grouped under
  /// sticky category headers (category sort), where the chip would just repeat
  /// the header above it.
  final bool hideCategory;

  /// Multi-select (group actions) state. When [selectionMode] is true, tapping
  /// the row toggles [selected] via [onSelectToggle] instead of running the
  /// normal tap action, swipe actions are suppressed, and the leading control
  /// becomes a selection circle. When [selectionMode] is false and
  /// [onLongPressSelect] is non-null, long-pressing the row enters selection.
  final bool selectionMode;
  final bool selected;
  final ValueChanged<ListItem>? onSelectToggle;
  final ValueChanged<ListItem>? onLongPressSelect;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.category,
    required this.houseId,
    required this.isCardsView,
    required this.onToggle,
    required this.onView,
    this.onDelete,
    this.onEdit,
    this.canCheck = true,
    this.onMove,
    this.onCopy,
    this.trashMode = false,
    this.archiveMode = false,
    this.onRestore,
    this.onPermanentDelete,
    this.onArchive,
    this.onUnarchive,
    this.addedByUserId,
    this.addedByDisplayName,
    this.listBadge,
    this.hideCategory = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
  });

  @override
  State<ChecklistItemTile> createState() => _ChecklistItemTileState();
}

class _ChecklistItemTileState extends State<ChecklistItemTile> {
  final _swipeKey = GlobalKey<SwipeRevealRowState>();

  void _toggleAndCloseSwipe() {
    _swipeKey.currentState?.close();
    widget.onToggle(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = widget.item;
    final cat = widget.category;
    final prefs = context.watch<PrefsService>();
    final tapAction = prefs.defaultItemTapAction;
    final dense = prefs.checklistDensity == 'dense';
    final swipeEnabled = prefs.swipeActionsEnabled;

    final catColor = cat != null
        ? (_parseColor(cat.color) ?? cs.primary)
        : cs.onSurfaceVariant;

    // Action buttons overlay the row's foreground in SwipeRevealRow, so a
    // translucent background lets chips and text bleed through. Pre-blend
    // each tint onto cs.surface (the foreground row's Material color) to get
    // the same visual tone with no transparency.
    Color tintedSurface(Color tint, double alpha) =>
        Color.alphaBlend(tint.withValues(alpha: alpha), cs.surface);

    final selecting = widget.selectionMode;

    final actions = <SwipeAction>[];
    // Swipe actions are suppressed while selecting — the row tap toggles
    // selection and there's no foreground gesture to reveal them.
    if (!selecting) {
      if (widget.trashMode || widget.archiveMode) {
        if (widget.trashMode && widget.onRestore != null) {
          actions.add(
            SwipeAction(
              icon: Icons.restore_from_trash,
              label: m.checklists.restoreItem,
              tint: const Color(0xFF5FBF8A),
              background: tintedSurface(const Color(0xFF5FBF8A), 0.16),
              onPressed: () => widget.onRestore!(item),
            ),
          );
        }
        if (widget.archiveMode && widget.onUnarchive != null) {
          actions.add(
            SwipeAction(
              icon: Icons.unarchive_outlined,
              label: m.checklists.unarchiveItem,
              tint: const Color(0xFF5FBF8A),
              background: tintedSurface(const Color(0xFF5FBF8A), 0.16),
              onPressed: () => widget.onUnarchive!(item),
            ),
          );
        }
        if (widget.onPermanentDelete != null) {
          actions.add(
            SwipeAction(
              icon: Icons.delete_forever,
              label: m.checklists.permanentlyDeleteItem,
              tint: const Color(0xFFEF7878),
              background: tintedSurface(const Color(0xFFEF7878), 0.2),
              onPressed: () => widget.onPermanentDelete!(item),
            ),
          );
        }
      } else {
        // Drop any swipe action the row tap already performs, so swipe never
        // duplicates the tap. When tap does nothing, both View and Edit show.
        // In overflow-menu mode there's no tap-gesture overlap, so the menu
        // keeps the default action's entry too (e.g. View while tap = view).
        if (!swipeEnabled || tapAction != 'view') {
          actions.add(
            SwipeAction(
              icon: Icons.visibility_outlined,
              label: m.checklists.swipeView,
              tint: const Color(0xFF5CB3EC),
              background: tintedSurface(const Color(0xFF5CB3EC), 0.16),
              onPressed: () => widget.onView(item),
            ),
          );
        }
        if ((!swipeEnabled || tapAction != 'edit') && widget.onEdit != null) {
          actions.add(
            SwipeAction(
              icon: Icons.edit_outlined,
              label: m.checklists.swipeEdit,
              tint: cs.onSurfaceVariant,
              background: tintedSurface(cs.onSurface, 0.07),
              onPressed: () => widget.onEdit!(item),
            ),
          );
        }
        if (widget.onMove != null) {
          actions.add(
            SwipeAction(
              icon: Icons.drive_file_move_outlined,
              label: m.checklists.swipeMove,
              tint: const Color(0xFFD9B441),
              background: tintedSurface(const Color(0xFFD9B441), 0.18),
              onPressed: () => widget.onMove!(item),
            ),
          );
        }
        if (widget.onCopy != null) {
          actions.add(
            SwipeAction(
              icon: Icons.copy_outlined,
              label: m.checklists.swipeCopy,
              tint: const Color(0xFF7AAE8E),
              background: tintedSurface(const Color(0xFF7AAE8E), 0.18),
              onPressed: () => widget.onCopy!(item),
            ),
          );
        }
        if (widget.onArchive != null) {
          actions.add(
            SwipeAction(
              icon: Icons.archive_outlined,
              label: m.checklists.swipeArchive,
              tint: const Color(0xFF9B8AD9),
              background: tintedSurface(const Color(0xFF9B8AD9), 0.18),
              onPressed: () => widget.onArchive!(item),
            ),
          );
        }
        if (widget.onDelete != null) {
          actions.add(
            SwipeAction(
              icon: Icons.delete_outline,
              label: m.checklists.swipeDelete,
              tint: const Color(0xFFEF7878),
              background: tintedSurface(const Color(0xFFEF7878), 0.2),
              onPressed: () => widget.onDelete!(item),
            ),
          );
        }
      }
    }

    final VoidCallback? rowTap;
    if (selecting) {
      rowTap = () => widget.onSelectToggle?.call(item);
    } else if (widget.trashMode || widget.archiveMode) {
      rowTap = () => widget.onView(item);
    } else {
      rowTap = switch (tapAction) {
        'done' =>
          widget.canCheck ? _toggleAndCloseSwipe : () => widget.onView(item),
        'edit' =>
          widget.onEdit != null
              ? () => widget.onEdit!(item)
              : () => widget.onView(item),
        'none' => null,
        _ => () => widget.onView(item),
      };
    }

    // Long-press enters selection, but only when the row isn't already in
    // selection mode and the caller opted in (reorder contexts pass null so
    // the drag-start listener keeps long-press).
    final VoidCallback? rowLongPress =
        !selecting && widget.onLongPressSelect != null
        ? () => widget.onLongPressSelect!(item)
        : null;

    final content = _RowContent(
      item: item,
      category: cat,
      catColor: catColor,
      houseId: widget.houseId,
      isCardsView: widget.isCardsView,
      trashMode: widget.trashMode,
      archiveMode: widget.archiveMode,
      dense: dense,
      addedByUserId: widget.addedByUserId,
      addedByDisplayName: widget.addedByDisplayName,
      listBadge: widget.listBadge,
      hideCategory: widget.hideCategory,
      onCheckboxTap: widget.canCheck ? _toggleAndCloseSwipe : null,
      onRowTap: rowTap,
      onRowLongPress: rowLongPress,
      selectionMode: selecting,
      selected: widget.selected,
    );

    // In selection mode the row toggles selection and shows no swipe actions,
    // so skip the action wrapper entirely. When the user has turned swipe
    // actions off, the same actions move into a trailing overflow menu.
    final Widget body;
    if (selecting) {
      body = content;
    } else if (!swipeEnabled) {
      body = _OverflowMenuRow(actions: actions, dense: dense, child: content);
    } else {
      body = SwipeRevealRow(
        key: _swipeKey,
        actions: actions,
        dense: dense,
        child: content,
      );
    }

    if (widget.isCardsView) {
      // Foreground border paints on top of the (already-clipped) child so
      // the rounded corners stay crisp. Painting the border under the
      // child — the default for BoxDecoration — let the swipe row's
      // Material surface antialias over it at the corners and erase them.
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    }
    return body;
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}

/// Row layout used when swipe actions are turned off: the item content fills
/// the row and a trailing overflow menu button exposes the same actions the
/// swipe gesture would have revealed, with the same icons and colors.
class _OverflowMenuRow extends StatelessWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final bool dense;

  const _OverflowMenuRow({
    required this.child,
    required this.actions,
    required this.dense,
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
            iconSize: dense ? 20 : 24,
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

class _RowContent extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final Color catColor;
  final int houseId;
  final bool isCardsView;
  final bool trashMode;
  final bool archiveMode;
  final bool dense;
  final String? addedByUserId;
  final String? addedByDisplayName;
  final ItemListBadge? listBadge;
  final bool hideCategory;
  final VoidCallback? onCheckboxTap;
  final VoidCallback? onRowTap;
  final VoidCallback? onRowLongPress;
  final bool selectionMode;
  final bool selected;

  const _RowContent({
    required this.item,
    required this.category,
    required this.catColor,
    required this.houseId,
    required this.isCardsView,
    required this.trashMode,
    required this.archiveMode,
    required this.dense,
    required this.addedByUserId,
    required this.addedByDisplayName,
    required this.listBadge,
    required this.hideCategory,
    required this.onCheckboxTap,
    required this.onRowTap,
    required this.onRowLongPress,
    required this.selectionMode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final checked = item.done;
    final checkboxAtEnd =
        context.watch<PrefsService>().checklistCheckboxPosition == 'end';

    final nameStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w600,
      color: checked ? cs.onSurfaceVariant : cs.onSurface,
      decoration: checked ? TextDecoration.lineThrough : null,
    );

    // Spacing around the checkbox is folded into its own tap target so the
    // whole padded area toggles the item — taps just above, below, or beside
    // the box no longer fall through to the row's Edit action. The box keeps
    // its 24px look but sits in a 48px-tall (Material minimum) hit area.
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
            // Shorter tap target in dense mode so single-line rows don't
            // reserve the full 48px Material height.
            hitHeight: dense ? 40 : 48,
            padding: checkboxPadding,
          );

    return Material(
      color: selectionMode && selected
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
                checkboxAtEnd ? 18 : 0,
                dense ? 6 : 13,
                checkboxAtEnd ? 0 : 16,
                dense ? 6 : 13,
              ),
              child: Row(
                children: [
                  if (!checkboxAtEnd) leadingControl,
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
                        Text(item.name, style: nameStyle),
                        if (_hasMeta) ...[
                          SizedBox(height: dense ? 3 : 5),
                          _MetaRow(
                            item: item,
                            category: hideCategory ? null : category,
                            catColor: catColor,
                            listBadge: listBadge,
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
                  if (checkboxAtEnd) leadingControl,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasMeta {
    final hasCat = category != null && !hideCategory;
    final hasQty = item.quantity != null && item.quantity!.trim().isNotEmpty;
    final hasDesc =
        item.description != null && item.description!.trim().isNotEmpty;
    final lc = lifecycleOf(item);
    final hasType = lc != ItemLifecycle.staple;
    return hasCat || hasQty || hasDesc || hasType || listBadge != null;
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
  final Color catColor;
  final ItemListBadge? listBadge;

  const _MetaRow({
    required this.item,
    required this.category,
    required this.catColor,
    required this.listBadge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        if (listBadge != null)
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
        if (category != null)
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
        if (item.quantity != null && item.quantity!.trim().isNotEmpty)
          _Chip(
            label: item.quantity!,
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (item.description != null && item.description!.trim().isNotEmpty)
          _Chip(
            leading: Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (lc == ItemLifecycle.once)
          _Chip(
            label: m.checklists.itemTypes.onceTime,
            textColor: cs.onSurfaceVariant,
            background: cs.onSurface.withValues(alpha: 0.06),
          ),
        if (lc == ItemLifecycle.recurring)
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

  const _Chip({
    this.leading,
    this.label,
    required this.textColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hasLabel ? 9 : 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
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
      child: CachedNetworkImage(
        imageUrl: uri.toString(),
        httpHeaders: headers,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Container(
          width: 40,
          height: 40,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_outlined, size: 18),
        ),
      ),
    );
  }
}
