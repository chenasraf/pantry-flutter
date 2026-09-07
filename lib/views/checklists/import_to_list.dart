import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/markdown_import_dialog.dart';

/// Opens the "import to list" flow from anywhere (e.g. a note's action). Spins
/// up its own [ChecklistsController] so it doesn't depend on the checklists tab
/// being mounted, prefills the Markdown import dialog with [markdown], lets the
/// user pick a target list, and adds the selected items to it.
///
/// Self-contained: the dialog opens in place over the caller's screen and the
/// caller's own navigation is untouched.
Future<void> showImportToListDialog(
  BuildContext context, {
  required int houseId,
  required String markdown,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final prefs = PrefsService.instance;

  // Preserve the checklists tab's remembered selection: loading and briefly
  // selecting a list here writes the shared `selectedListId`, which would
  // otherwise change which list that tab shows next time it opens.
  final savedSelectedListId = ChecklistService.instance.selectedListId;
  final controller = ChecklistsController(houseId: houseId);
  try {
    // Spinner while lists/categories load, so the tap has immediate feedback
    // even when the fetch isn't served straight from cache.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await controller.load();
    } finally {
      if (rootNavigator.canPop()) rootNavigator.pop();
    }
    if (!context.mounted) return;

    final lists = controller.sortedLists
        .where((l) => l.id != kAllListsId && l.isWritable)
        .toList();
    if (lists.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(m.notesWall.importNoLists)),
      );
      return;
    }

    final currentId = ChecklistService.instance.selectedListId;
    final initialId = lists.any((l) => l.id == currentId)
        ? currentId!
        : lists.first.id;

    final result = await showDialog<MarkdownImportResult>(
      context: context,
      builder: (_) => MarkdownImportDialog(
        categories: controller.categoriesForList(initialId),
        reusePref: prefs.reuseExistingItems,
        reuseFeatureAvailable: hasFeature('reuse-existing-items'),
        initialText: markdown,
        pickableLists: lists,
        initialListId: initialId,
        categoriesForList: controller.categoriesForList,
      ),
    );
    if (result == null || result.listId == null) return;
    final targetListId = result.listId!;
    final target = lists.firstWhere((l) => l.id == targetListId);

    // Selecting the target loads its items, so reuse-dedup matches against
    // what's really on the list and the optimistic add caches correctly.
    await controller.selectList(target);

    final mode = result.forceReuse ? 'reuse' : prefs.reuseExistingItems;
    final canReuse = hasFeature('reuse-existing-items') && mode == 'reuse';

    var added = 0;
    for (final s in result.submissions) {
      if (canReuse) {
        final existing = controller.findExistingItem(targetListId, s.name);
        if (existing != null) {
          await controller.reuseItem(existing);
          added++;
          continue;
        }
      }
      await controller.addItemTo(
        targetListId: targetListId,
        name: s.name,
        description: s.description,
        quantity: s.quantity,
        categoryId: s.categoryId,
        rrule: s.rrule,
        repeatFromCompletion: s.repeatFromCompletion,
        deleteOnDone: s.deleteOnDone,
      );
      added++;
    }
    if (added > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(m.checklists.markdown.imported(added))),
      );
    }
  } finally {
    ChecklistService.instance.selectedListId = savedSelectedListId;
    controller.dispose();
  }
}
