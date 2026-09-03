import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/views/custom_fields/item_custom_fields_display.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'checklists_controller.dart';
import 'item_detail_facts.dart';
import 'item_detail_headers.dart';
import 'item_detail_meta.dart';
import 'item_form_view.dart';
import 'item_picker_dialogs.dart';

class ItemDetailView extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final int houseId;
  final ChecklistsController controller;

  const ItemDetailView({
    super.key,
    required this.item,
    this.category,
    this.stores = const [],
    this.labels = const [],
    required this.houseId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasImage = item.imageFileId != null;
    final lifecycle = lifecycleOf(item);
    final perms = controller.permissions;
    // A view-only shared list makes the whole item read-only.
    final writable = controller.isItemWritable(item);
    final canEdit = writable && perms.canEditLists;
    // The overflow menu only exists if at least one of its actions is allowed.
    final hasOverflow = _hasOverflowActions();
    final onMore = hasOverflow
        ? (BuildContext ctx) => _showOverflow(context, anchorContext: ctx)
        : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: hasImage
                      ? PhotoHeader(
                          item: item,
                          houseId: houseId,
                          category: category,
                          stores: stores,
                          labels: labels,
                          onBack: () => Navigator.of(context).maybePop(),
                          onMore: onMore,
                        )
                      : FallbackHeader(
                          item: item,
                          category: category,
                          stores: stores,
                          labels: labels,
                          onBack: () => Navigator.of(context).maybePop(),
                          onMore: onMore,
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  sliver: SliverList.list(
                    children: [
                      FactTiles(item: item, lifecycle: lifecycle),
                      if (hasFeature('item-price') && item.hasPrice) ...[
                        const SizedBox(height: 12),
                        PriceTile(item: item),
                      ],
                      if (hasFeature('custom-fields') &&
                          item.customFields.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ItemCustomFieldsDisplay(
                          houseId: houseId,
                          values: item.customFields,
                        ),
                      ],
                      const SizedBox(height: 12),
                      DescriptionCard(
                        item: item,
                        controller: controller,
                        canToggle: canEdit,
                      ),
                      const SizedBox(height: 12),
                      MetaRow(item: item, controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (canEdit) DockedEditBar(onTap: () => _openEdit(context)),
        ],
      ),
    );
  }

  /// Whether any overflow action is available — drives whether the ⋮ button shows.
  bool _hasOverflowActions() {
    final writable = controller.isItemWritable(item);
    if (!writable) return false;
    final hasOtherLists = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .isNotEmpty;
    final perms = controller.permissions;
    final canMove = hasOtherLists && perms.canMoveItems;
    final canCopy =
        hasOtherLists && hasFeature('copy-items') && perms.canCopyItems;
    final canArchive =
        !controller.isSoftView &&
        perms.canEditLists &&
        hasFeature('item-archive');
    return canMove || canCopy || canArchive || perms.canDeleteItems;
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).pushReplacement(
      itemModalRoute(ItemFormView(controller: controller, item: item)),
    );
  }

  Future<void> _showOverflow(
    BuildContext context, {
    BuildContext? anchorContext,
  }) async {
    final perms = controller.permissions;
    final hasOtherLists = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .isNotEmpty;
    final canMove = hasOtherLists && perms.canMoveItems;
    final canCopy =
        hasOtherLists && hasFeature('copy-items') && perms.canCopyItems;
    final canArchive =
        !controller.isSoftView &&
        perms.canEditLists &&
        hasFeature('item-archive');
    final actions = <OverflowAction>[
      if (canMove)
        OverflowAction(
          value: 'move',
          icon: Icons.drive_file_move_outlined,
          label: m.checklists.moveItem,
        ),
      if (canCopy)
        OverflowAction(
          value: 'copy',
          icon: Icons.copy_outlined,
          label: m.checklists.copyItem,
        ),
      if (canArchive)
        OverflowAction(
          value: 'archive',
          icon: Icons.archive_outlined,
          label: m.checklists.archiveItem,
        ),
      if (perms.canDeleteItems)
        OverflowAction(
          value: 'delete',
          icon: Icons.delete_outline,
          label: m.checklists.removeItem,
        ),
    ];
    if (actions.isEmpty) return;
    String? selected;
    if (PlatformInfo.isDesktop && anchorContext != null) {
      // Desktop: anchor a regular PopupMenu under the more button. Reads as
      // a native menu instead of an out-of-place bottom sheet.
      final box = anchorContext.findRenderObject() as RenderBox?;
      final overlay =
          Navigator.of(context).overlay?.context.findRenderObject()
              as RenderBox?;
      if (box == null || overlay == null || !box.attached) return;
      final btnTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      final btnSize = box.size;
      final position = RelativeRect.fromLTRB(
        btnTopLeft.dx,
        btnTopLeft.dy + btnSize.height,
        overlay.size.width - (btnTopLeft.dx + btnSize.width),
        0,
      );
      selected = await showMenu<String>(
        context: context,
        position: position,
        items: [
          for (final a in actions)
            PopupMenuItem<String>(
              value: a.value,
              child: Row(
                children: [
                  Icon(a.icon, size: 18),
                  const SizedBox(width: 12),
                  Text(a.label),
                ],
              ),
            ),
        ],
      );
    } else {
      selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                ListTile(
                  leading: Icon(a.icon),
                  title: Text(a.label),
                  onTap: () => Navigator.pop(ctx, a.value),
                ),
            ],
          ),
        ),
      );
    }
    if (!context.mounted) return;
    switch (selected) {
      case 'move':
        await _onMove(context);
      case 'copy':
        await _onCopy(context);
      case 'archive':
        await _onArchive(context);
      case 'delete':
        await _confirmDelete(context);
    }
  }

  Future<void> _onArchive(BuildContext context) async {
    try {
      await controller.archiveItem(item);
      // The item left the active list for the archive; close the detail view.
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.archiveFailed)));
      }
    }
  }

  Future<void> _onMove(BuildContext context) async {
    final others = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .toList();
    if (others.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.moveItem,
      lists: others,
    );
    if (targetId == null || !context.mounted) return;
    try {
      await controller.moveItem(item, targetId);
      // Item left the current list; close the detail view.
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.moveFailed)));
      }
    }
  }

  Future<void> _onCopy(BuildContext context) async {
    final others = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .toList();
    if (others.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.copyItem,
      lists: others,
    );
    if (targetId == null || !context.mounted) return;
    try {
      await controller.copyItem(item, targetId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.itemCopied)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.copyFailed)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final f = m.checklists.itemForm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteItem(item);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.deleteFailed)));
      }
    }
  }
}
