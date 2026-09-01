import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'checklist_item_tile.dart';
import 'checklists_controller.dart';
import 'checklists_sliver_headers.dart';
import 'item_detail_view.dart';
import 'item_form_view.dart';
import 'item_picker_dialogs.dart';

/// Overflow-menu actions in the Done section header.
enum _DoneAction { uncheckAll, removeAll }

class ChecklistItemList extends StatefulWidget {
  final ChecklistsController controller;
  final List<ListItem> activeItems;
  final List<ListItem> doneItems;
  final bool canReorder;

  /// When true (category / store sort with the within-group ordering
  /// capability), each active category block / store column is independently
  /// drag-reorderable — a drag is confined to its own group.
  final bool canReorderGroups;
  final bool isCards;
  final bool doneCollapsed;

  /// When true (category sort), items render grouped under category headers.
  final bool groupByCategory;

  /// When true (store sort), items render grouped under store headers. An item
  /// linked to multiple stores appears once under each; items with no store
  /// fall under a trailing "No store" group.
  final bool groupByStore;
  final VoidCallback onToggleDoneCollapsed;
  final ScrollController? scrollController;

  /// Extra scrollable space appended below the last item so the resting
  /// compose bar / floating shopping FAB don't cover it once scrolled to the
  /// bottom. Applied as trailing scroll padding (not an outer gap), so items
  /// use the full viewport and are never clipped mid-list.
  final double bottomInset;

  const ChecklistItemList({
    super.key,
    required this.controller,
    required this.activeItems,
    required this.doneItems,
    required this.canReorder,
    required this.canReorderGroups,
    required this.isCards,
    required this.doneCollapsed,
    required this.groupByCategory,
    required this.groupByStore,
    required this.onToggleDoneCollapsed,
    this.scrollController,
    this.bottomInset = 0,
  });

  @override
  State<ChecklistItemList> createState() => _ChecklistItemListState();
}

class _ChecklistItemListState extends State<ChecklistItemList> {
  // Fallback when no external controller is supplied (e.g. in tests). When
  // the host provides one (the normal path from home_view) we use that so
  // iOS status-bar-tap can scroll this list to the top.
  ScrollController? _ownedScrollController;
  ScrollController get _scrollController =>
      widget.scrollController ??
      (_ownedScrollController ??= ScrollController());
  final Map<int, GlobalKey> _tileKeys = {};

  GlobalKey _keyFor(int id) => _tileKeys.putIfAbsent(id, () => GlobalKey());

  /// Stable (non-global) key for an active tile. A [ValueKey] keeps tile state
  /// within its list without the cross-sliver reparenting a [GlobalKey] incurs.
  ValueKey<String> _activeKey(int id) => ValueKey('active-$id');

  // A long-press on a reorderable row lifts the item (a drag session starts at
  // the long-press timeout). If it's released without moving far enough to
  // change its slot, the drop lands at the start index — we read that as
  // "select this item" and enter multi-select instead of reordering. The id is
  // captured at drag start so a mid-drag rebuild can't shift the index lookup.
  int? _dragStartIndex;
  int? _dragStartItemId;

  void _onReorderStart(List<ListItem> scope, int index) {
    _dragStartIndex = index;
    _dragStartItemId = (index >= 0 && index < scope.length)
        ? scope[index].id
        : null;
  }

  void _onReorderEnd(int endIndex) {
    final start = _dragStartIndex;
    final id = _dragStartItemId;
    _dragStartIndex = null;
    _dragStartItemId = null;
    // Moved to a new slot → a real reorder (handled by onReorder), not a select.
    if (start == null || id == null || endIndex != start) return;
    if (!widget.controller.canSelectItems) return;
    // The drop is still settling inside the list's setState; defer the
    // selection (which rebuilds this subtree, tearing down the reorderable) to
    // after the frame so we don't mutate the tree mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.enterSelection(id);
    });
  }

  @override
  void didUpdateWidget(ChecklistItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = <int>{
      for (final i in widget.activeItems) i.id,
      for (final i in widget.doneItems) i.id,
    };
    _tileKeys.removeWhere((id, _) => !live.contains(id));
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // An item deep link (e.g. the checklist widget) asks to open a specific
    // item once its list has loaded and rendered here.
    if (ChecklistService.instance.pendingOpenItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _maybeOpenPendingItem(),
      );
    }

    final showDone = widget.doneItems.isNotEmpty;
    final showDoneItems = showDone && !widget.doneCollapsed;

    final slivers = <Widget>[
      const SliverPadding(padding: EdgeInsets.only(top: 4)),
    ];

    if (widget.canReorder) {
      // Reordering is custom-sort only, which never groups by category.
      slivers.add(
        SliverReorderableList(
          itemCount: widget.activeItems.length,
          onReorderStart: (index) => _onReorderStart(widget.activeItems, index),
          onReorderEnd: _onReorderEnd,
          onReorderItem: (oldIndex, newIndex) {
            widget.controller.reorderItems(
              widget.activeItems,
              oldIndex,
              newIndex,
            );
          },
          itemBuilder: (context, i) {
            final item = widget.activeItems[i];
            // Long-press to drag: an immediate listener would fight the
            // horizontal swipe-reveal gesture and vertical scrolling.
            return ReorderableDelayedDragStartListener(
              key: ValueKey(item.id),
              index: i,
              child: _buildTile(context, item),
            );
          },
        ),
      );
    } else if (widget.groupByCategory) {
      slivers.addAll(
        _groupedSlivers(
          widget.activeItems,
          reorderable: widget.canReorderGroups,
        ),
      );
    } else if (widget.groupByStore) {
      slivers.addAll(
        _groupedByStoreSlivers(
          widget.activeItems,
          reorderable: widget.canReorderGroups,
        ),
      );
    } else {
      slivers.add(
        SliverList.builder(
          itemCount: widget.activeItems.length,
          itemBuilder: (context, i) =>
              _buildTile(context, widget.activeItems[i]),
        ),
      );
    }

    if (showDone) slivers.add(_doneHeader(context));

    if (showDoneItems) {
      if (widget.groupByCategory) {
        slivers.addAll(_groupedSlivers(widget.doneItems, reorderable: false));
      } else if (widget.groupByStore) {
        slivers.addAll(
          _groupedByStoreSlivers(widget.doneItems, reorderable: false),
        );
      } else {
        slivers.add(
          SliverList.builder(
            itemCount: widget.doneItems.length,
            itemBuilder: (context, i) =>
                _buildTile(context, widget.doneItems[i]),
          ),
        );
      }
    }

    slivers.add(
      SliverPadding(
        padding: EdgeInsets.only(
          bottom: widget.bottomInset > 36 ? widget.bottomInset : 36,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  Widget _doneHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: InkWell(
        onTap: widget.onToggleDoneCollapsed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check, color: const Color(0xFF5FBF8A), size: 18),
              const SizedBox(width: 11),
              Text(
                m.checklists.doneCount(widget.doneItems.length),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (widget.controller.canUncheckAll ||
                  widget.controller.canRemoveAllDone) ...[
                PopupMenuButton<_DoneAction>(
                  tooltip: m.checklists.moreActions,
                  icon: Icon(
                    Icons.more_vert,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                  onSelected: (action) {
                    switch (action) {
                      case _DoneAction.uncheckAll:
                        _confirmUncheckAll(context);
                      case _DoneAction.removeAll:
                        _confirmRemoveAllDone(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (widget.controller.canUncheckAll)
                      PopupMenuItem(
                        value: _DoneAction.uncheckAll,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.remove_done, size: 20),
                          title: Text(m.checklists.uncheckAll),
                        ),
                      ),
                    if (widget.controller.canRemoveAllDone)
                      PopupMenuItem(
                        value: _DoneAction.removeAll,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.delete_outline, size: 20),
                          title: Text(m.checklists.removeAll),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: widget.doneCollapsed ? 0 : 0.5,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirm, then clear the done-state on every checked item in the list. The
  /// count is captured before the call since the Done section empties
  /// immediately.
  Future<void> _confirmUncheckAll(BuildContext context) async {
    final count = widget.doneItems.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.uncheckAllConfirm),
        content: Text(m.checklists.uncheckAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.checklists.uncheckAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.controller.uncheckAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.checklists.uncheckedCount(count))),
      );
    }
  }

  /// Confirm, then soft-delete every done item in the list, offering an Undo
  /// snackbar that restores them. The removed snapshots are captured from the
  /// controller so undo can re-add exactly what left.
  Future<void> _confirmRemoveAllDone(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.removeAllConfirm),
        content: Text(m.checklists.removeAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.checklists.removeAll),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = widget.controller.removeAllDone();
    if (removed.isEmpty) return;
    showUndoSnackBar(
      message: m.checklists.removedCount(removed.length),
      undoLabel: m.checklists.undo,
      onUndo: () async => widget.controller.undoBatchDelete(removed),
      undoFailedMessage: m.checklists.restoreFailed,
    );
  }

  /// One [SliverMainAxisGroup] per category run: a pinned category header
  /// followed by that group's tiles. Grouping each header with its own items
  /// makes the header stick to the top while its group is on screen and
  /// release as the next group scrolls up to take its place.
  Iterable<Widget> _groupedSlivers(
    List<ListItem> items, {
    required bool reorderable,
  }) {
    return groupItemsByCategory(items).map((group) {
      final category = group.categoryId != null
          ? widget.controller.categories[group.categoryId]
          : null;
      return SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ChecklistsCategoryHeaderDelegate(category: category),
          ),
          if (reorderable)
            // A drag is confined to this category's own SliverReorderableList,
            // so it can never cross into another category. The scope handed to
            // the controller is exactly this group's items.
            SliverReorderableList(
              key: ValueKey('cat-reorder-${group.categoryId}'),
              itemCount: group.items.length,
              onReorderStart: (index) => _onReorderStart(group.items, index),
              onReorderEnd: _onReorderEnd,
              onReorderItem: (oldIndex, newIndex) {
                widget.controller.reorderItems(group.items, oldIndex, newIndex);
              },
              itemBuilder: (context, i) {
                final item = group.items[i];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('cat-${group.categoryId}-${item.id}'),
                  index: i,
                  child: _buildTile(context, item),
                );
              },
            )
          else
            SliverList.builder(
              itemCount: group.items.length,
              itemBuilder: (context, i) => _buildTile(context, group.items[i]),
            ),
        ],
      );
    });
  }

  /// Store-sorted counterpart to [_groupedSlivers]: one pinned header per store
  /// (in `sortedStores` order) plus a trailing "No store" group. An item linked
  /// to several stores is emitted under each, so each rendered copy needs a key
  /// unique to its (store, item) pair — the item's own id alone would collide.
  Iterable<Widget> _groupedByStoreSlivers(
    List<ListItem> items, {
    required bool reorderable,
  }) {
    final sortedStores = widget.controller.sortedStores;
    return groupItemsByStore(items, sortedStores).map((group) {
      final store = group.storeId != null
          ? widget.controller.stores[group.storeId]
          : null;
      return SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: ChecklistsStoreHeaderDelegate(store: store),
          ),
          if (reorderable)
            // The drag is confined to this store column. A multi-store item
            // shares one sort_order, so re-slotting it here also moves it in its
            // other columns — the intended "one order, many lenses" coupling.
            SliverReorderableList(
              key: ValueKey('store-reorder-${group.storeId}'),
              itemCount: group.items.length,
              onReorderStart: (index) => _onReorderStart(group.items, index),
              onReorderEnd: _onReorderEnd,
              onReorderItem: (oldIndex, newIndex) {
                widget.controller.reorderItems(group.items, oldIndex, newIndex);
              },
              itemBuilder: (context, i) {
                final item = group.items[i];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('store-${group.storeId}-${item.id}'),
                  index: i,
                  child: _buildTile(
                    context,
                    item,
                    keyOverride: ValueKey(
                      'store-tile-${group.storeId}-${item.id}',
                    ),
                    priceStoreContext: group.storeId,
                  ),
                );
              },
            )
          else
            SliverList.builder(
              itemCount: group.items.length,
              itemBuilder: (context, i) {
                final item = group.items[i];
                return _buildTile(
                  context,
                  item,
                  keyOverride: ValueKey('store-${group.storeId}-${item.id}'),
                  priceStoreContext: group.storeId,
                );
              },
            ),
        ],
      );
    });
  }

  /// [keyOverride] is supplied by the store-grouped path, where one item can
  /// appear under several store headers: the per-item [GlobalKey] would then be
  /// mounted twice (a duplicate-key crash), so those rows key off a unique
  /// (store, item) [ValueKey] instead. Toggles/edits still target `item.id`, so
  /// checking one copy updates every copy on the next rebuild.
  Widget _buildTile(
    BuildContext context,
    ListItem item, {
    Key? keyOverride,
    int? priceStoreContext,
  }) {
    final controller = widget.controller;
    // A view-only shared list disables every item write; the granular house
    // caps still apply on top. Resolved per-item so the All-lists view (whose
    // items span lists with different share levels) gates each item correctly.
    final writable = controller.isItemWritable(item);
    final addedByUserId =
        controller.showAddedBy &&
            item.addedBy != null &&
            item.addedBy!.isNotEmpty
        ? item.addedBy
        : null;
    final addedByDisplayName = addedByUserId != null
        ? controller.members[addedByUserId]?.displayName
        : null;
    // The list-name chip only appears in the All-lists view, where each item
    // belongs to a different underlying list. In per-list views the badge
    // would be noise.
    ItemListBadge? listBadge;
    if (controller.isMetaMode) {
      final owner = controller.lists.cast<ChecklistList?>().firstWhere(
        (l) => l!.id == item.listId,
        orElse: () => null,
      );
      if (owner != null) {
        listBadge = ItemListBadge(
          name: owner.name,
          icon: owner.icon,
          color: owner.color,
        );
      }
    }
    return ChecklistItemTile(
      // Only done tiles carry the per-id GlobalKey — [_onToggle] measures their
      // height for scroll compensation. Active tiles use a plain ValueKey so the
      // GlobalKey never reparents between slivers (active↔done on toggle, or the
      // reorderable↔plain swap when entering selection), which would mutate a
      // RenderObject mid-layout and crash a lazily-built sliver.
      key: keyOverride ?? (item.done ? _keyFor(item.id) : _activeKey(item.id)),
      item: item,
      category: item.categoryId != null
          ? controller.categories[item.categoryId]
          : null,
      stores: controller.storesFor(item),
      labels: controller.labelsFor(item),
      houseId: controller.houseId,
      isCardsView: widget.isCards,
      trashMode: controller.isTrashMode,
      archiveMode: controller.isArchiveMode,
      addedByUserId: addedByUserId,
      addedByDisplayName: addedByDisplayName,
      listBadge: listBadge,
      hideCategory: widget.groupByCategory,
      priceStoreContext: priceStoreContext,
      onToggle: (i) => _onToggle(context, controller, i),
      canCheck: writable && controller.permissions.canCheckItems,
      onView: (i) => _openView(context, controller, i),
      onEdit: writable && controller.permissions.canEditLists
          ? (i) => _openEdit(context, controller, i)
          : null,
      onMove:
          writable &&
              controller.lists.length > 1 &&
              !controller.isSoftView &&
              controller.permissions.canMoveItems
          ? (i) => _onMove(context, controller, i)
          : null,
      onCopy:
          writable &&
              controller.lists.length > 1 &&
              !controller.isSoftView &&
              hasFeature('copy-items') &&
              controller.permissions.canCopyItems
          ? (i) => _onCopy(context, controller, i)
          : null,
      onDelete: writable && controller.permissions.canDeleteItems
          ? (i) => _onDelete(context, controller, i)
          : null,
      onArchive:
          writable &&
              !controller.isSoftView &&
              controller.permissions.canEditLists &&
              hasFeature('item-archive')
          ? (i) => _onArchive(context, controller, i)
          : null,
      onRestore:
          writable &&
              controller.isTrashMode &&
              controller.permissions.canDeleteItems
          ? (i) => _onRestore(context, controller, i)
          : null,
      onUnarchive:
          writable &&
              controller.isArchiveMode &&
              controller.permissions.canEditLists
          ? (i) => _onUnarchive(context, controller, i)
          : null,
      onPermanentDelete:
          writable &&
              controller.isSoftView &&
              controller.permissions.canDeleteItems
          ? (i) => _onPermanentDelete(context, controller, i)
          : null,
      selectionMode: controller.selectionMode,
      selected: controller.isSelected(item.id),
      onSelectToggle: (i) => controller.toggleSelected(i.id),
      // Long-press enters selection only where it won't fight the reorder
      // drag (custom sort uses ReorderableDelayedDragStartListener). The
      // overflow "Select items" action covers the reorderable case.
      onLongPressSelect:
          controller.canSelectItems &&
              !widget.canReorder &&
              !widget.canReorderGroups
          ? (i) => controller.enterSelection(i.id)
          : null,
    );
  }

  Future<void> _onMove(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    // In meta mode the "current list" is the synthetic sentinel — exclude the
    // item's actual home list instead so we don't offer a no-op move.
    final excludeId = controller.isMetaMode
        ? item.listId
        : controller.currentList?.id;
    final others = controller.lists
        .where((l) => l.id != excludeId && l.id != kAllListsId)
        .toList();
    if (others.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.moveItem,
      lists: others,
    );
    if (targetId == null) return;
    try {
      await controller.moveItem(item, targetId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.moveFailed)));
      }
    }
  }

  Future<void> _onCopy(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    // In meta mode the "current list" is the synthetic sentinel — exclude the
    // item's actual home list instead so we don't offer a no-op copy.
    final excludeId = controller.isMetaMode
        ? item.listId
        : controller.currentList?.id;
    final others = controller.lists
        .where((l) => l.id != excludeId && l.id != kAllListsId)
        .toList();
    if (others.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.copyItem,
      lists: others,
    );
    if (targetId == null) return;
    try {
      await controller.copyItem(item, targetId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.copyFailed)));
      }
    }
  }

  void _onToggle(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    final wasDone = item.done;
    final wasDeleteOnDone = item.deleteOnDone;

    // Unchecking promotes the tile to the active section, which sits above the
    // done section. That growth pushes everything below it — including the
    // viewport content the user is looking at — down by the tile's height.
    // Capture that height pre-toggle so we can cancel the shift post-frame.
    double? shiftCompensation;
    if (wasDone) {
      final ctx = _tileKeys[item.id]?.currentContext;
      final box = ctx?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        shiftCompensation = box.size.height;
      }
    }

    controller.toggleItem(item);

    if (shiftCompensation != null) {
      final delta = shiftCompensation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final pos = _scrollController.position;
        final target = (pos.pixels + delta).clamp(
          pos.minScrollExtent,
          pos.maxScrollExtent,
        );
        if (target != pos.pixels) pos.jumpTo(target);
      });
    }

    if (wasDone) return;
    showUndoSnackBar(
      message: m.checklists.itemMarkedDone,
      undoLabel: m.checklists.undo,
      onUndo: () async {
        final stillPresent = controller.items.any((i) => i.id == item.id);
        if (wasDeleteOnDone || !stillPresent) {
          await controller.restoreItem(item);
        }
        final current = controller.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item.copyWith(done: true),
        );
        if (current.done) {
          await controller.toggleItem(current);
        }
      },
      undoFailedMessage: m.checklists.restoreFailed,
    );
  }

  /// Consume a pending item deep link: once the target list's items are loaded,
  /// open that item's detail. Cleared whether or not the item is found (so a
  /// stale request can't reopen on later rebuilds).
  void _maybeOpenPendingItem() {
    final id = ChecklistService.instance.pendingOpenItemId;
    if (id == null || !mounted || widget.controller.isLoading) return;
    ChecklistService.instance.pendingOpenItemId = null;
    for (final item in [...widget.activeItems, ...widget.doneItems]) {
      if (item.id == id) {
        _openView(context, widget.controller, item);
        return;
      }
    }
  }

  void _openView(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    Navigator.of(context).push(
      itemModalRoute(
        ItemDetailView(
          item: item,
          category: item.categoryId != null
              ? controller.categories[item.categoryId]
              : null,
          stores: controller.storesFor(item),
          labels: controller.labelsFor(item),
          houseId: controller.houseId,
          controller: controller,
        ),
      ),
    );
  }

  void _openEdit(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    Navigator.of(
      context,
    ).push(itemModalRoute(ItemFormView(controller: controller, item: item)));
  }

  Future<void> _onDelete(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.deleteItem(item);
    } catch (_) {
      showAppSnackBar(message: m.checklists.itemForm.deleteFailed);
      return;
    }
    showUndoSnackBar(
      message: m.checklists.itemRemoved,
      undoLabel: m.checklists.undo,
      onUndo: () => controller.restoreItem(item),
      undoFailedMessage: m.checklists.restoreFailed,
    );
  }

  Future<void> _onRestore(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.restoreItem(item);
      showAppSnackBar(message: m.checklists.itemRestored);
    } catch (_) {
      showAppSnackBar(message: m.checklists.restoreFailed);
    }
  }

  Future<void> _onArchive(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.archiveItem(item);
    } catch (_) {
      showAppSnackBar(message: m.checklists.archiveFailed);
      return;
    }
    showUndoSnackBar(
      message: m.checklists.itemArchived,
      undoLabel: m.checklists.undo,
      onUndo: () => controller.unarchiveItem(item),
      undoFailedMessage: m.checklists.unarchiveFailed,
    );
  }

  Future<void> _onUnarchive(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.unarchiveItem(item);
      showAppSnackBar(message: m.checklists.itemUnarchived);
    } catch (_) {
      showAppSnackBar(message: m.checklists.unarchiveFailed);
    }
  }

  Future<void> _onPermanentDelete(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.permanentlyDeleteConfirm),
        content: Text(m.checklists.permanentlyDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.permanentlyDeleteItem(item);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.checklists.permanentlyDeleteFailed)),
        );
      }
    }
  }
}

/// Partition category-sorted items into consecutive same-category runs, each
/// carrying its shared `categoryId` (null = uncategorised). Items are assumed
/// already sorted by category, so a run captures a whole category group.
List<({int? categoryId, List<ListItem> items})> groupItemsByCategory(
  List<ListItem> items,
) {
  final groups = <({int? categoryId, List<ListItem> items})>[];
  for (final item in items) {
    if (groups.isEmpty || groups.last.categoryId != item.categoryId) {
      groups.add((categoryId: item.categoryId, items: [item]));
    } else {
      groups.last.items.add(item);
    }
  }
  return groups;
}

/// Group store-sorted items under one entry per store, in [sortedStores] order,
/// with a trailing `storeId: null` "No store" group. An item's store link is
/// many-valued, so it's emitted once under *each* store it belongs to; items
/// with no (resolvable) store land in "No store". Within a group items are
/// ordered by `sortOrder` (tie-break name), so a multi-store item's single
/// sort_order positions it across all its columns. Only non-empty groups
/// returned.
List<({int? storeId, List<ListItem> items})> groupItemsByStore(
  List<ListItem> items,
  List<models.Store> sortedStores,
) {
  int bySortOrder(ListItem a, ListItem b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  final validIds = {for (final s in sortedStores) s.id};
  final groups = <({int? storeId, List<ListItem> items})>[];

  for (final store in sortedStores) {
    final inStore = [
      for (final item in items)
        if (item.storeIds.contains(store.id)) item,
    ]..sort(bySortOrder);
    if (inStore.isNotEmpty) {
      groups.add((storeId: store.id, items: inStore));
    }
  }

  final noStore = [
    for (final item in items)
      if (!item.storeIds.any(validIds.contains)) item,
  ]..sort(bySortOrder);
  if (noStore.isNotEmpty) {
    groups.add((storeId: null, items: noStore));
  }

  return groups;
}
