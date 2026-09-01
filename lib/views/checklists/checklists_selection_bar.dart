import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/entity_icons.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'checklists_controller.dart';
import 'item_picker_dialogs.dart';

/// Bottom bar shown while items are multi-selected. Surfaces the four group
/// actions, each enabled per the controller's permission/writability gating,
/// and drives the batch endpoints with a target/category picker + result
/// snackbar (including the skipped count).
class SelectionActionBar extends StatelessWidget {
  final ChecklistsController controller;

  const SelectionActionBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: cs.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          // Trash offers restore + permanent delete; archive offers unarchive +
          // permanent delete; the active view offers the full
          // move/copy/category/archive/delete set.
          child: controller.isTrashMode
              ? Row(
                  children: [
                    _action(
                      context,
                      icon: Icons.restore_from_trash,
                      label: m.checklists.restoreItem,
                      enabled: controller.canBatchRestore,
                      onTap: () => _restore(context),
                    ),
                    _action(
                      context,
                      icon: Icons.delete_forever,
                      label: m.checklists.batch.delete,
                      enabled: controller.canBatchDelete,
                      onTap: () => _delete(context, permanent: true),
                    ),
                  ],
                )
              : controller.isArchiveMode
              ? Row(
                  children: [
                    _action(
                      context,
                      icon: Icons.unarchive_outlined,
                      label: m.checklists.batch.unarchive,
                      enabled: controller.canBatchArchive,
                      onTap: () => _unarchive(context),
                    ),
                    _action(
                      context,
                      icon: Icons.delete_forever,
                      label: m.checklists.batch.delete,
                      enabled: controller.canBatchDelete,
                      onTap: () => _delete(context, permanent: true),
                    ),
                  ],
                )
              : Row(
                  children: [
                    _action(
                      context,
                      icon: Icons.drive_file_move_outlined,
                      label: m.checklists.batch.move,
                      enabled: controller.canBatchMove,
                      onTap: () => _move(context),
                    ),
                    _action(
                      context,
                      icon: Icons.copy_outlined,
                      label: m.checklists.batch.copy,
                      enabled: controller.canBatchCopy,
                      onTap: () => _copy(context),
                    ),
                    _action(
                      context,
                      icon: EntityIcons.category,
                      label: m.checklists.batch.category,
                      enabled: controller.canBatchCategory,
                      onTap: () => _category(context),
                    ),
                    if (controller.hasStoresFeature)
                      _action(
                        context,
                        icon: EntityIcons.store,
                        label: m.checklists.batch.stores,
                        enabled: controller.canBatchStores,
                        onTap: () => _stores(context),
                      ),
                    if (controller.hasLabelsFeature)
                      _action(
                        context,
                        icon: EntityIcons.label,
                        label: m.checklists.batch.labels,
                        enabled: controller.canBatchLabels,
                        onTap: () => _labels(context),
                      ),
                    _action(
                      context,
                      icon: Icons.archive_outlined,
                      label: m.checklists.batch.archive,
                      enabled: controller.canBatchArchive,
                      onTap: () => _archive(context),
                    ),
                    _action(
                      context,
                      icon: Icons.delete_outline,
                      label: m.checklists.batch.delete,
                      enabled: controller.canBatchDelete,
                      onTap: () => _delete(context),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38);
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The batch actions are optimistic and go through the offline sync queue, so
  // the outcome is reconciled later rather than awaited here. Each shows an
  // immediate snackbar; move / delete / set-category also offer Undo, driven
  // from the pre-action item snapshots captured before the selection clears.

  /// Valid move/copy targets: every list except the synthetic All-lists entry
  /// and the current list (a no-op target).
  List<ChecklistList> _targetLists() {
    final currentId = controller.isMetaMode ? null : controller.currentList?.id;
    return controller.lists
        .where((l) => l.id != kAllListsId && l.id != currentId)
        .toList();
  }

  Future<void> _move(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    final targets = _targetLists();
    if (targets.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.batch.moveTitle,
      lists: targets,
    );
    if (targetId == null) return;
    controller.batchMove(targetId);
    _showUndo(
      m.checklists.batch.moved(affected.length),
      () => controller.undoBatchMove(affected),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final count = controller.selectedCount;
    final targets = _targetLists();
    if (targets.isEmpty) return;
    final targetId = await pickTargetList(
      context,
      title: m.checklists.batch.copyTitle,
      lists: targets,
    );
    if (targetId == null) return;
    controller.batchCopy(targetId);
    // Copy is additive and non-destructive — no undo, just a confirmation.
    showAppSnackBar(message: m.checklists.batch.copied(count));
  }

  Future<void> _category(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    // Selected items may span lists (meta view), so only globals are safe there;
    // in a per-list view the current list's scope applies.
    final cats = controller.categoriesForList(
      controller.isMetaMode ? null : controller.currentList?.id,
    );
    final choice = await pickCategory(context, categories: cats);
    if (choice == null) return;
    final categoryId = choice == kBatchClearCategory ? null : choice;
    controller.batchSetCategory(categoryId);
    _showUndo(
      m.checklists.batch.categorySet(affected.length),
      () => controller.undoBatchSetCategory(affected),
    );
  }

  Future<void> _stores(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    final choice = await pickStores(context, stores: controller.sortedStores);
    if (choice == null) return;
    controller.batchSetStores(choice);
    _showUndo(
      m.checklists.batch.storesSet(affected.length),
      () => controller.undoBatchSetStores(affected),
    );
  }

  Future<void> _labels(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    final choice = await pickLabels(context, labels: controller.sortedLabels);
    if (choice == null) return;
    controller.batchSetLabels(choice);
    _showUndo(
      m.checklists.batch.labelsSet(affected.length),
      () => controller.undoBatchSetLabels(affected),
    );
  }

  Future<void> _delete(BuildContext context, {bool permanent = false}) async {
    final affected = List.of(controller.selectedItems);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.batch.deleteConfirmTitle),
        // A permanent delete (from trash/archive) can't be undone, so its
        // confirmation says so instead of offering the "restore from trash"
        // reassurance the soft delete gives.
        content: Text(
          permanent
              ? m.checklists.permanentlyDeleteConfirmBody
              : m.checklists.batch.deleteConfirmBody(affected.length),
        ),
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
    if (ok != true) return;
    controller.batchDelete(permanent: permanent);
    // A permanent delete has no undo path.
    if (permanent) {
      showAppSnackBar(message: m.checklists.batch.deleted(affected.length));
      return;
    }
    _showUndo(
      m.checklists.batch.deleted(affected.length),
      () => controller.undoBatchDelete(affected),
    );
  }

  Future<void> _archive(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    controller.batchArchive();
    _showUndo(
      m.checklists.batch.archived(affected.length),
      () => controller.undoBatchArchive(affected),
    );
  }

  Future<void> _unarchive(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    controller.batchUnarchive();
    _showUndo(
      m.checklists.batch.unarchived(affected.length),
      () => controller.undoBatchUnarchive(affected),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    controller.batchRestore();
    _showUndo(
      m.checklists.batch.restored(affected.length),
      () => controller.undoBatchRestore(affected),
    );
  }

  /// Shows a confirmation snackbar with an Undo action for a batch operation.
  void _showUndo(String message, VoidCallback onUndo) {
    showUndoSnackBar(
      message: message,
      undoLabel: m.checklists.undo,
      onUndo: () async => onUndo(),
    );
  }
}
