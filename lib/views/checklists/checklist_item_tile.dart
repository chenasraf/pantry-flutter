import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/views/checklists/checklist_density.dart';
import 'checklist_item_tile_parts.dart';
import 'swipe_reveal_row.dart';

class ChecklistItemTile extends StatefulWidget {
  final ListItem item;
  final models.Category? category;

  /// Stores attached to this item, resolved and name-ordered by the caller.
  /// Rendered as one chip each in the meta row.
  final List<models.Store> stores;

  /// Labels attached to this item, resolved and sort-ordered by the caller.
  /// Rendered as one chip each in the meta row (store-chip styling).
  final List<models.Label> labels;
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

  /// Store context for the price chip. When non-null (store-grouped views), the
  /// chip resolves this store's price, falling back to the store-less price;
  /// null (flat/category views) shows the store-less price. See
  /// `resolveItemPrice`.
  final int? priceStoreContext;

  /// Multi-select state. When true, tapping the row toggles [selected] via
  /// [onSelectToggle], swipe actions are suppressed, and the leading control
  /// becomes a selection circle. When false, a non-null [onLongPressSelect]
  /// lets a long-press enter selection.
  final bool selectionMode;
  final bool selected;
  final ValueChanged<ListItem>? onSelectToggle;
  final ValueChanged<ListItem>? onLongPressSelect;

  /// Suggestion flavor: the row is rendered without a checkbox, swipe actions,
  /// or selection affordance — just the name + meta chips as a single tap
  /// target. Backs the compose bar's "reuse an existing item" suggestions.
  final bool suggestion;
  final VoidCallback? onSuggestionTap;

  /// Marks a reuse suggestion as coming from the archive: the row shows an
  /// "Archived" badge, and reusing it unarchives the item. Only meaningful when
  /// [suggestion] is true.
  final bool archived;

  const ChecklistItemTile({
    super.key,
    required this.item,
    required this.category,
    this.stores = const [],
    this.labels = const [],
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
    this.priceStoreContext,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
    this.suggestion = false,
    this.onSuggestionTap,
    this.archived = false,
  });

  /// A read-only tile used as a reuse suggestion in the compose bar: name and
  /// meta chips only, no checkbox/swipe/selection. Tapping it runs [onTap].
  const ChecklistItemTile.suggestion({
    super.key,
    required this.item,
    required this.category,
    this.stores = const [],
    this.labels = const [],
    required this.houseId,
    required VoidCallback onTap,
    this.archived = false,
  }) : isCardsView = false,
       onToggle = _noop,
       onView = _noop,
       onDelete = null,
       onEdit = null,
       canCheck = false,
       onMove = null,
       onCopy = null,
       trashMode = false,
       archiveMode = false,
       onRestore = null,
       onPermanentDelete = null,
       onArchive = null,
       onUnarchive = null,
       addedByUserId = null,
       addedByDisplayName = null,
       listBadge = null,
       hideCategory = false,
       priceStoreContext = null,
       selectionMode = false,
       selected = false,
       onSelectToggle = null,
       onLongPressSelect = null,
       suggestion = true,
       onSuggestionTap = onTap;

  static void _noop(ListItem _) {}

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
    final longPressAction = prefs.defaultItemLongPressAction;
    final density = ChecklistDensity.fromPref(prefs.checklistDensity);
    final swipeEnabled = prefs.swipeActionsEnabled;

    final catColor = cat != null
        ? (_parseColor(cat.color) ?? cs.primary)
        : cs.onSurfaceVariant;

    // Suggestion flavor short-circuits the swipe/selection machinery — a plain
    // tappable row that mirrors the normal layout minus the checkbox.
    if (widget.suggestion) {
      return ChecklistTileRowContent(
        item: item,
        category: cat,
        stores: widget.stores,
        labels: widget.labels,
        catColor: catColor,
        houseId: widget.houseId,
        isCardsView: false,
        trashMode: false,
        archiveMode: false,
        density: density,
        addedByUserId: null,
        addedByDisplayName: null,
        listBadge: null,
        hideCategory: false,
        onCheckboxTap: null,
        onRowTap: widget.onSuggestionTap,
        onRowLongPress: null,
        selectionMode: false,
        selected: false,
        suggestion: true,
        archived: widget.archived,
      );
    }

    // Pre-blend each tint onto cs.surface for an opaque background: a
    // translucent one would let the foreground row's chips and text bleed
    // through the revealed action.
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

    // Long-press honors the user's chosen action. The default `multiselect`
    // preserves the built-in behavior: enter selection here, or (under custom
    // sort) let the view's drag-start listener own long-press by passing a null
    // `onLongPressSelect`. Any other action mirrors the tap-action switch.
    final VoidCallback? rowLongPress;
    if (selecting) {
      rowLongPress = null;
    } else if (longPressAction == 'multiselect') {
      rowLongPress = widget.onLongPressSelect != null
          ? () => widget.onLongPressSelect!(item)
          : null;
    } else if (widget.trashMode || widget.archiveMode) {
      rowLongPress = () => widget.onView(item);
    } else {
      rowLongPress = switch (longPressAction) {
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

    final content = ChecklistTileRowContent(
      item: item,
      category: cat,
      stores: widget.stores,
      labels: widget.labels,
      catColor: catColor,
      houseId: widget.houseId,
      isCardsView: widget.isCardsView,
      trashMode: widget.trashMode,
      archiveMode: widget.archiveMode,
      density: density,
      addedByUserId: widget.addedByUserId,
      addedByDisplayName: widget.addedByDisplayName,
      listBadge: widget.listBadge,
      hideCategory: widget.hideCategory,
      priceStoreContext: widget.priceStoreContext,
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
      body = ChecklistTileOverflowMenuRow(
        actions: actions,
        density: density,
        child: content,
      );
    } else {
      body = SwipeRevealRow(
        key: _swipeKey,
        actions: actions,
        density: density,
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
