part of 'checklists_body_controller.dart';

extension ChecklistsBodyDialogs on ChecklistsBodyController {
  /// Prompts the user when an item with the same name already exists in the
  /// target list (the "ask" reuse mode). Returns null if dismissed.
  Future<_ReuseChoice?> _askReuseExisting(BuildContext context, String name) {
    return showDialog<_ReuseChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.checklists.reuse.dialogTitle),
        content: Text(m.checklists.reuse.dialogBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ReuseChoice.cancel),
            child: Text(m.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ReuseChoice.addAnyway),
            child: Text(m.checklists.reuse.addAnyway),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ReuseChoice.reuse),
            child: Text(m.checklists.reuse.reuseExisting),
          ),
        ],
      ),
    );
  }

  /// Handles a tap on a live reuse suggestion: reuses the tapped item —
  /// un-checking it if it was already done — prompting first only under the
  /// "ask" reuse mode. The tap is itself an explicit request to reuse that one
  /// item, so the pref only governs whether we confirm on top of it and
  /// "never" reuses without a prompt rather than refusing. Returns true when
  /// reused so the compose bar clears its input.
  Future<bool> reuseFromSuggestion(BuildContext context, ListItem item) async {
    // Reusing an archived suggestion unarchives it, so it warns the user in the
    // prompt and takes the unarchive path over the plain done-toggle reuse.
    final archived = item.archivedAt != null;
    // A server that doesn't advertise the capability never synced a mode, so
    // the local pref reflects nothing it would honor — keep confirming there.
    final mode = hasFeature('reuse-existing-items')
        ? PrefsService.instance.reuseExistingItems
        : 'ask';
    if (mode == 'ask') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(m.checklists.reuse.dialogTitle),
          content: Text(
            archived
                ? m.checklists.reuse.archivedDialogBody(item.name)
                : m.checklists.reuse.dialogBody(item.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(m.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(m.checklists.reuse.reuseExisting),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return false;
    }
    if (archived) {
      await domain.reuseArchivedItem(item);
    } else {
      await domain.reuseItem(item);
    }
    if (context.mounted) {
      showAppToast(
        message: archived
            ? m.checklists.reuse.reusedArchivedSnack(item.name)
            : m.checklists.reuse.reusedSnack(item.name),
      );
    }
    return true;
  }

  /// Adds a single item to [targetListId], honoring the reuse-existing-items
  /// pref (reuse silently / ask per duplicate / add). [forceReuse] forces the
  /// "reuse" behavior for this add regardless of the global pref — used by the
  /// Markdown import flow. Returns true on a successful add or graceful reuse,
  /// false on cancel or error. Shared by the compose bar and the importer so a
  /// single add path honors the pref consistently.
  Future<bool> addItemHonoringReuse(
    BuildContext context, {
    required int targetListId,
    required bool meta,
    required ComposeSubmission s,
    bool forceReuse = false,
  }) async {
    final prefs = PrefsService.instance;
    // Reuse existing items: only when the server advertises the capability and
    // the effective mode isn't "never". On a name collision in the target
    // list, reuse (un-check) the existing item instead of adding a duplicate —
    // silently for "reuse", or after confirming for "ask".
    final mode = forceReuse ? 'reuse' : prefs.reuseExistingItems;
    if (hasFeature('reuse-existing-items') && mode != 'never') {
      final existing = domain.findExistingItem(targetListId, s.name);
      if (existing != null) {
        var reuse = mode == 'reuse';
        if (mode == 'ask') {
          final choice = await _askReuseExisting(context, existing.name);
          if (!context.mounted) return false;
          switch (choice) {
            case _ReuseChoice.reuse:
              reuse = true;
            case _ReuseChoice.addAnyway:
              reuse = false;
            case _ReuseChoice.cancel:
            case null:
              return false;
          }
        }
        if (reuse) {
          await domain.reuseItem(existing);
          if (context.mounted) {
            showAppToast(
              message: m.checklists.reuse.reusedSnack(existing.name),
            );
          }
          return true;
        }
        // "Add anyway" falls through to a normal add.
      }
    }

    try {
      final ListItem created;
      if (meta) {
        created = await domain.addItemTo(
          targetListId: targetListId,
          name: s.name,
          description: s.description,
          quantity: s.quantity,
          categoryId: s.categoryId,
          storeIds: s.storeIds.isEmpty ? null : s.storeIds,
          labelIds: s.labelIds.isEmpty ? null : s.labelIds,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
          barcode: s.barcode,
          prices: s.prices,
          customFields: s.customFields,
        );
      } else {
        created = await domain.addItem(
          name: s.name,
          description: s.description,
          quantity: s.quantity,
          categoryId: s.categoryId,
          storeIds: s.storeIds.isEmpty ? null : s.storeIds,
          labelIds: s.labelIds.isEmpty ? null : s.labelIds,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
          barcode: s.barcode,
          prices: s.prices,
          customFields: s.customFields,
        );
      }
      // Remember the chosen currency when the new item actually has a price:
      // the store-less price's currency, else the first per-store price's.
      final prices = s.prices;
      if (prices != null && prices.isNotEmpty) {
        final currency = (storelessPrice(prices) ?? prices.first).priceCurrency;
        if (currency != null) await domain.setLastCurrency(currency);
      }
      if (s.imageBytes != null) {
        await domain.uploadItemImage(
          created,
          bytes: s.imageBytes!,
          fileName: s.imageName ?? 'image.jpg',
          mimeType: s.imageMime ?? 'image/jpeg',
        );
      }
      return true;
    } catch (_) {
      if (!context.mounted) return false;
      showAppToast(
        message: m.checklists.itemForm.saveFailed,
        kind: ToastKind.error,
      );
      return false;
    }
  }

  /// Opens the Markdown export dialog for the current concrete list.
  Future<void> openExport(BuildContext context) async {
    final list = domain.currentList;
    if (list == null || list.id == kAllListsId) return;
    final items = domain.items.where((i) => i.deletedAt == null).toList();
    await showDialog<void>(
      context: context,
      builder: (_) => MarkdownExportDialog(
        listName: list.name,
        items: items,
        categoryFor: (id) => id == null ? null : domain.categories[id],
      ),
    );
  }

  /// Opens the Markdown import dialog, then adds each selected item through the
  /// shared reuse-aware add path. Processed sequentially so any "ask" prompts
  /// resolve one at a time and names repeated within the batch dedupe against
  /// the items added earlier in the same import.
  Future<void> openImport(BuildContext context) async {
    final prefs = PrefsService.instance;
    final list = domain.currentList;
    if (list == null || list.id == kAllListsId) return;
    final targetListId = list.id;
    // Close the dialog (it pops itself with the result) before processing so
    // any "ask" reuse prompts render over the list, not stacked on the dialog.
    final result = await showDialog<MarkdownImportResult>(
      context: context,
      builder: (_) => MarkdownImportDialog(
        categories: domain.categoriesForList(targetListId),
        reusePref: prefs.reuseExistingItems,
        reuseFeatureAvailable: hasFeature('reuse-existing-items'),
        onRequestCreateCategory: () =>
            createCategory(context, defaultListId: targetListId),
      ),
    );
    if (result == null || !context.mounted) return;
    var added = 0;
    for (final s in result.submissions) {
      final ok = await addItemHonoringReuse(
        context,
        targetListId: targetListId,
        meta: false,
        s: s,
        forceReuse: result.forceReuse,
      );
      if (!context.mounted) return;
      if (ok) added++;
    }
    if (context.mounted && added > 0) {
      showAppToast(
        message: m.checklists.markdown.imported(added),
        kind: ToastKind.success,
      );
    }
  }

  Future<void> showOverflowSheet(BuildContext context) async {
    final entries = overflowItems();
    if (entries.isEmpty) return;
    final selected = await showOverflowMenuSheet(context, entries);
    if (selected != null && context.mounted) {
      await onOverflow(context, selected);
    }
  }

  Future<void> onOverflow(BuildContext context, String value) async {
    final prefs = PrefsService.instance;
    switch (value) {
      case 'select_items':
        domain.enterSelection();
      case 'sort':
        await showSortDialog(context);
      case 'sort_newest':
        await domain.setSortBy('newest');
      case 'sort_oldest':
        await domain.setSortBy('oldest');
      case 'sort_name_asc':
        await domain.setSortBy('name_asc');
      case 'sort_name_desc':
        await domain.setSortBy('name_desc');
      case 'sort_category':
        await domain.setSortBy('category');
      case 'sort_store':
        await domain.setSortBy('store');
      case 'sort_custom':
        await domain.setSortBy('custom');
      case 'reset_order':
        await showResetOrderDialog(context);
      case 'toggle_added_by':
        await domain.setShowAddedBy(!domain.showAddedBy);
      case 'toggle_progress_hero':
        final current = domain.currentList;
        if (current != null) {
          await domain.setListHideProgressHero(!current.hideProgressHero);
        }
      case 'view_trash':
        await domain.setTrashMode(true);
      case 'exit_trash':
        await domain.setTrashMode(false);
      case 'empty_trash':
        await confirmEmptyTrash(context);
      case 'view_archive':
        await domain.setArchiveMode(true);
      case 'exit_archive':
        await domain.setArchiveMode(false);
      case 'copy_link':
        await copyListLink(context);
      case 'add_to_home':
        await addListToHomeScreen(context);
      case 'manage_categories':
        await openManageCategories(context);
      case 'manage_stores':
        await openManageStores(context);
      case 'manage_labels':
        await openManageLabels(context);
      case 'manage_custom_fields':
        await openManageCustomFields(context);
      case 'start_shopping':
        await openShopping(context);
      case 'shopping_history':
        await openShoppingHistory(context);
      case 'export_markdown':
        await openExport(context);
      case 'import_markdown':
        await openImport(context);
      case 'refresh':
        await domain.refresh();
      case 'dev_show_onboarding':
        await devShowOnboarding(context);
      case 'dev_force_all_features':
        await prefs.setDevForceAllFeatures(!prefs.devForceAllFeatures);
      case 'dev_test_notification':
        await LocalNotificationsService.instance.show(
          id: 999999,
          title: 'Pantry',
          body: 'This is a test notification.',
        );
    }
  }

  /// Presents the sort choices in a dialog — the mobile overflow menu is too
  /// long to inline all of them, so it shows a single "Sort: current" row
  /// that opens this dialog. Applies the choice immediately on selection.
  Future<void> showSortDialog(BuildContext context) async {
    final picked = await showOverflowSortDialog(
      context,
      title: m.checklists.sortTooltip,
      options: checklistSortOptions(showCustom: !domain.isMetaMode),
      selected: domain.effectiveSortBy,
    );
    if (picked != null) {
      await domain.setSortBy(picked);
    }
  }

  /// Pick a basis (Date added / Name A–Z / Name Z–A), confirm the destructive
  /// overwrite, then re-seed the custom order.
  Future<void> showResetOrderDialog(BuildContext context) async {
    final bases = <({String key, String label})>[
      (key: 'dateAdded', label: m.checklists.resetOrder.basisDateAdded),
      (key: 'name_asc', label: m.checklists.resetOrder.basisNameAsc),
      (key: 'name_desc', label: m.checklists.resetOrder.basisNameDesc),
    ];
    final basis = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.resetOrder.pickTitle),
        children: [
          for (final b in bases)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, b.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(b.label),
              ),
            ),
        ],
      ),
    );
    if (basis == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.resetOrder.confirmTitle),
        content: Text(m.checklists.resetOrder.confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.checklists.resetOrder.action),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await domain.resetOrder(basis);
    if (context.mounted) {
      showAppToast(
        message: m.checklists.resetOrder.success,
        kind: ToastKind.success,
      );
    }
  }

  /// Dev-only flow: pick a "last seen" version to seed prefs with, then push
  /// the onboarding view. Lets us preview what users with various upgrade
  /// histories will see without uninstalling the app.
  Future<void> devShowOnboarding(BuildContext context) async {
    final picked = await showDialog<ChecklistsDevLastSeenChoice>(
      context: context,
      builder: (ctx) => ChecklistsDevLastSeenPickerDialog(),
    );
    if (picked == null || !context.mounted) return;
    // The picked value is the version whose what's-new to preview; seed
    // last-seen just below it so exactly that version's pages surface. Null is
    // the "new user" option — preview the full first-run flow.
    final lastSeen = picked.value == null
        ? null
        : onboardingPreviewLastSeen(picked.value!);
    await PrefsService.instance.setLastSeenOnboardingVersion(lastSeen);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingView(
          appVersion: appVersion,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> copyListLink(BuildContext context) async {
    final list = domain.currentList;
    if (list == null) return;
    final uri = ListLink.uri(list.houseId, list.id);
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    showAppToast(message: m.common.copied, kind: ToastKind.success);
  }

  Future<void> addListToHomeScreen(BuildContext context) async {
    final list = domain.currentList;
    if (list == null) return;
    final ok = await ListLinkService.instance.pinListToHomeScreen(
      houseId: list.houseId,
      listId: list.id,
      name: list.name,
    );
    if (ok || !context.mounted) return;
    showAppToast(
      message: m.checklists.addToHomeScreenFailed,
      kind: ToastKind.error,
    );
  }

  Future<void> confirmEmptyTrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.emptyTrashConfirm),
        content: Text(m.checklists.emptyTrashConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.checklists.emptyTrash),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await domain.emptyTrash();
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          message: m.checklists.emptyTrashFailed,
          kind: ToastKind.error,
        );
      }
    }
  }

  /// Joining a housemate's trip ends the caller's own and files it to their
  /// history, so it is asked rather than assumed.
  Future<bool> confirmEndMineAndJoin(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.shopping.joinConfirmTitle),
        content: Text(m.shopping.joinConfirmBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.shopping.endMineAndJoin),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
