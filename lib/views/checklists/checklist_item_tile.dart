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
  final ValueChanged<ListItem> onToggle;
  final ValueChanged<ListItem> onView;
  final ValueChanged<ListItem> onEdit;
  final ValueChanged<ListItem>? onMove;
  final ValueChanged<ListItem>? onCopy;
  final ValueChanged<ListItem> onDelete;
  final ValueChanged<ListItem>? onRestore;
  final ValueChanged<ListItem>? onPermanentDelete;

  /// When non-null, render the author's avatar at the trailing end of the
  /// row. Controlled by the user's "Show who added each item" preference and
  /// gated on the item actually having an `addedBy` value.
  final String? addedByUserId;
  final String? addedByDisplayName;

  /// When non-null (the All-lists view), render a chip identifying the list
  /// this item belongs to. Suppressed in per-list views where it would be
  /// redundant.
  final ItemListBadge? listBadge;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.category,
    required this.houseId,
    required this.isCardsView,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.onMove,
    this.onCopy,
    this.trashMode = false,
    this.onRestore,
    this.onPermanentDelete,
    this.addedByUserId,
    this.addedByDisplayName,
    this.listBadge,
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
    final tapAction = context.watch<PrefsService>().defaultItemTapAction;

    final catColor = cat != null
        ? (_parseColor(cat.color) ?? cs.primary)
        : cs.onSurfaceVariant;

    // Action buttons overlay the row's foreground in SwipeRevealRow, so a
    // translucent background lets chips and text bleed through. Pre-blend
    // each tint onto cs.surface (the foreground row's Material color) to get
    // the same visual tone with no transparency.
    Color tintedSurface(Color tint, double alpha) =>
        Color.alphaBlend(tint.withValues(alpha: alpha), cs.surface);

    final actions = <SwipeAction>[];
    if (widget.trashMode) {
      if (widget.onRestore != null) {
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
      if (tapAction != 'view') {
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
      if (tapAction != 'edit') {
        actions.add(
          SwipeAction(
            icon: Icons.edit_outlined,
            label: m.checklists.swipeEdit,
            tint: cs.onSurfaceVariant,
            background: tintedSurface(cs.onSurface, 0.07),
            onPressed: () => widget.onEdit(item),
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
      actions.add(
        SwipeAction(
          icon: Icons.delete_outline,
          label: m.checklists.swipeDelete,
          tint: const Color(0xFFEF7878),
          background: tintedSurface(const Color(0xFFEF7878), 0.2),
          onPressed: () => widget.onDelete(item),
        ),
      );
    }

    final VoidCallback? rowTap;
    if (widget.trashMode) {
      rowTap = () => widget.onView(item);
    } else {
      rowTap = switch (tapAction) {
        'done' => _toggleAndCloseSwipe,
        'edit' => () => widget.onEdit(item),
        'none' => null,
        _ => () => widget.onView(item),
      };
    }

    final content = _RowContent(
      item: item,
      category: cat,
      catColor: catColor,
      houseId: widget.houseId,
      isCardsView: widget.isCardsView,
      trashMode: widget.trashMode,
      addedByUserId: widget.addedByUserId,
      addedByDisplayName: widget.addedByDisplayName,
      listBadge: widget.listBadge,
      onCheckboxTap: _toggleAndCloseSwipe,
      onRowTap: rowTap,
    );

    final swipe = SwipeRevealRow(
      key: _swipeKey,
      actions: actions,
      child: content,
    );

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
        child: swipe,
      );
    }
    return swipe;
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}

class _RowContent extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final Color catColor;
  final int houseId;
  final bool isCardsView;
  final bool trashMode;
  final String? addedByUserId;
  final String? addedByDisplayName;
  final ItemListBadge? listBadge;
  final VoidCallback onCheckboxTap;
  final VoidCallback? onRowTap;

  const _RowContent({
    required this.item,
    required this.category,
    required this.catColor,
    required this.houseId,
    required this.isCardsView,
    required this.trashMode,
    required this.addedByUserId,
    required this.addedByDisplayName,
    required this.listBadge,
    required this.onCheckboxTap,
    required this.onRowTap,
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
    final checkbox = _Checkbox(
      checked: checked,
      trashMode: trashMode,
      accent: cs.primary,
      onTap: onCheckboxTap,
      padding: checkboxAtEnd
          ? const EdgeInsetsDirectional.only(start: 14, end: 16)
          : const EdgeInsetsDirectional.only(start: 18, end: 14),
    );

    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onRowTap,
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
                13,
                checkboxAtEnd ? 0 : 16,
                13,
              ),
              child: Row(
                children: [
                  if (!checkboxAtEnd) checkbox,
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
                          const SizedBox(height: 5),
                          _MetaRow(
                            item: item,
                            category: category,
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
                  if (checkboxAtEnd) checkbox,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasMeta {
    final hasCat = category != null;
    final hasQty = item.quantity != null && item.quantity!.trim().isNotEmpty;
    final lc = lifecycleOf(item);
    final hasType = lc != ItemLifecycle.staple;
    return hasCat || hasQty || hasType || listBadge != null;
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final bool trashMode;
  final Color accent;
  final VoidCallback onTap;

  /// Padding folded into the tap target. The opaque hit area covers the box,
  /// this padding, and the full 48px height, so taps around the box still
  /// toggle the item.
  final EdgeInsetsDirectional padding;

  /// Material's minimum touch target. The 24px box is centered within it.
  static const double _hitHeight = 48;

  const _Checkbox({
    required this.checked,
    required this.trashMode,
    required this.accent,
    required this.onTap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Widget visual = trashMode
        ? Icon(Icons.delete_outline, color: cs.onSurfaceVariant, size: 22)
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: checked ? accent : Colors.transparent,
              border: checked
                  ? Border.all(color: accent, width: 2)
                  : Border.all(color: cs.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: checked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          );
    return GestureDetector(
      onTap: trashMode ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: padding,
        // Fixed height (not a flex/stretch fill) so the tap target stays
        // valid even where the row's own height is unbounded (e.g. cards
        // view). widthFactor keeps the cell only as wide as the box.
        child: SizedBox(
          height: _hitHeight,
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
  final String label;
  final Color textColor;
  final Color background;

  const _Chip({
    this.leading,
    required this.label,
    required this.textColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
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
