import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import 'switcher_widgets.dart';

class ListStage extends StatelessWidget {
  final ChecklistsController controller;
  final Future<int> Function(int listId) itemCountForList;
  final VoidCallback onCreateNew;
  final ValueChanged<ChecklistList> onEdit;
  final VoidCallback onOpenTrash;
  final VoidCallback onOpenArchive;

  const ListStage({
    super.key,
    required this.controller,
    required this.itemCountForList,
    required this.onCreateNew,
    required this.onEdit,
    required this.onOpenTrash,
    required this.onOpenArchive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final realLists = hasFeature('checklist-sort')
        ? controller.sortedLists
        : controller.lists;
    final current = controller.currentList;
    // The synthetic "All lists" entry only earns its spot when there's more
    // than one real list to aggregate. With zero lists the index renders the
    // empty state; with one list, "All lists" would just duplicate that list.
    final showAllLists =
        hasFeature('checklist-all-view') && realLists.length >= 2;
    final perms = controller.permissions;
    final canEditLists = perms.canEditLists;
    final canDeleteLists = perms.canDeleteLists;
    final canArchiveLists = hasFeature('checklist-archive') && canEditLists;
    final canReorder =
        hasFeature('checklist-sort') &&
        controller.listSort == 'custom' &&
        canEditLists;
    final showMenu = hasFeature('checklist-trash');
    final allListsTile = showAllLists
        ? AllListsTile(
            selected: current?.id == kAllListsId,
            onTap: () async {
              Navigator.pop(context);
              if (current?.id != kAllListsId) {
                await controller.selectList(
                  allListsSentinel(controller.houseId),
                );
              }
            },
          )
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 0,
            bottom: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.checklists.yourChecklists,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: [
                  Text(
                    m.checklists.listsCount(realLists.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (hasFeature('checklist-sort'))
                    _SortMenuButton(controller: controller),
                ],
              ),
            ],
          ),
        ),
        if (allListsTile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: allListsTile,
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: canReorder
              ? ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: realLists.length,
                  onReorderItem: controller.reorderLists,
                  proxyDecorator: (child, _, _) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (_, i) {
                    final list = realLists[i];
                    final selected = list.id == current?.id;
                    return Padding(
                      key: ValueKey(list.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ListTile(
                        list: list,
                        selected: selected,
                        itemCountFuture: itemCountForList(list.id),
                        dragIndex: i,
                        showOverflow: true,
                        onTap: () async {
                          Navigator.pop(context);
                          if (!selected) await controller.selectList(list);
                        },
                        onEdit: list.canEditSettingsWith(canEditLists)
                            ? () => onEdit(list)
                            : null,
                        onRemove: showMenu && canDeleteLists
                            ? () => _confirmRemove(context, list)
                            : null,
                        onArchive: canArchiveLists
                            ? () => _archiveList(context, list)
                            : null,
                      ),
                    );
                  },
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: realLists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final list = realLists[i];
                    final selected = list.id == current?.id;
                    return _ListTile(
                      list: list,
                      selected: selected,
                      itemCountFuture: itemCountForList(list.id),
                      showOverflow: true,
                      onTap: () async {
                        Navigator.pop(context);
                        if (!selected) await controller.selectList(list);
                      },
                      onEdit: list.canEditSettingsWith(canEditLists)
                          ? () => onEdit(list)
                          : null,
                      onRemove: showMenu && canDeleteLists
                          ? () => _confirmRemove(context, list)
                          : null,
                      onArchive: canArchiveLists
                          ? () => _archiveList(context, list)
                          : null,
                    );
                  },
                ),
        ),
        if (perms.canCreateLists) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onCreateNew,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.6),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Text(
                    m.checklists.newChecklist,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (hasFeature('checklist-trash') && canDeleteLists) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onOpenTrash,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m.checklists.viewListsTrash,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (hasFeature('checklist-archive')) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: onOpenArchive,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m.checklists.archivedLists,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, ChecklistList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.removeListConfirm),
        content: Text(m.checklists.removeListConfirmBody(list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteList(list);
      if (!context.mounted) return;
      Navigator.pop(context);
      // Snackbar runs against the host scaffold, not the dismissed sheet.
      showUndoSnackBar(
        message: m.checklists.listRemoved,
        undoLabel: m.checklists.undo,
        onUndo: () => controller.restoreList(list),
        undoFailedMessage: m.checklists.restoreFailed,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.removeListFailed)));
      }
    }
  }

  Future<void> _archiveList(BuildContext context, ChecklistList list) async {
    try {
      await controller.archiveList(list);
      if (!context.mounted) return;
      Navigator.pop(context);
      // Snackbar runs against the host scaffold, not the dismissed sheet.
      showUndoSnackBar(
        message: m.checklists.listArchived,
        undoLabel: m.checklists.undo,
        onUndo: () => controller.unarchiveList(list),
        undoFailedMessage: m.checklists.unarchiveListFailed,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.archiveListFailed)));
      }
    }
  }
}

class _ListTile extends StatelessWidget {
  final ChecklistList list;
  final bool selected;
  final Future<int> itemCountFuture;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onArchive;
  final int? dragIndex;
  final bool showOverflow;

  const _ListTile({
    required this.list,
    required this.selected,
    required this.itemCountFuture,
    required this.onTap,
    this.onEdit,
    this.onRemove,
    this.onArchive,
    this.dragIndex,
    this.showOverflow = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = parseHexColor(list.color) ?? cs.primary;
    final tile = Container(
      padding: EdgeInsetsDirectional.only(
        start: 13,
        end: dragIndex != null ? 4 : 8,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.1)
            : cs.surfaceContainer,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(checklistIcon(list.icon), color: tint, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: itemCountFuture,
                  builder: (_, snap) {
                    final count = snap.data ?? -1;
                    final label = count < 0
                        ? ''
                        : (count == 0
                              ? m.checklists.allDoneSummary
                              : m.checklists.itemsSummary(count));
                    return Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          if (showOverflow &&
              (onEdit != null || onRemove != null || onArchive != null))
            SizedBox(
              width: 36,
              height: 36,
              child: PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'archive') onArchive?.call();
                  if (v == 'remove') onRemove?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(m.checklists.editList),
                        ],
                      ),
                    ),
                  if (onArchive != null)
                    PopupMenuItem<String>(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(Icons.archive_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(m.checklists.archiveList),
                        ],
                      ),
                    ),
                  if (onRemove != null)
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(m.checklists.removeList),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex!,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 2, end: 6),
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );

    final interactive = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: tile,
    );

    if (!PlatformInfo.isDesktop ||
        (onEdit == null && onRemove == null && onArchive == null)) {
      return interactive;
    }

    return ContextMenuRegion(
      onEdit: onEdit,
      onRemove: onRemove,
      onArchive: onArchive,
      editLabel: m.checklists.editList,
      removeLabel: m.checklists.removeList,
      archiveLabel: m.checklists.archiveList,
      child: interactive,
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final ChecklistsController controller;

  const _SortMenuButton({required this.controller});

  String _label(String key) => switch (key) {
    'newest' => m.checklists.sort.newestFirst,
    'oldest' => m.checklists.sort.oldestFirst,
    'name_asc' => m.checklists.sort.nameAZ,
    'name_desc' => m.checklists.sort.nameZA,
    _ => m.checklists.sort.custom,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const keys = ['custom', 'name_asc', 'name_desc', 'newest', 'oldest'];
    return PopupMenuButton<String>(
      tooltip: m.checklists.sortTooltip,
      icon: Icon(Icons.sort, size: 20, color: cs.onSurfaceVariant),
      padding: EdgeInsets.zero,
      onSelected: controller.setListSort,
      itemBuilder: (_) => [
        for (final k in keys)
          PopupMenuItem<String>(
            value: k,
            child: Row(
              children: [
                Icon(
                  k == controller.listSort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: k == controller.listSort ? cs.primary : null,
                ),
                const SizedBox(width: 10),
                Text(_label(k)),
              ],
            ),
          ),
      ],
    );
  }
}
