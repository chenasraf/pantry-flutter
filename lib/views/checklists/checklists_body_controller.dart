import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/list_link_service.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/entity_icons.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/categories/categories_view.dart';
import 'package:pantry/views/categories/category_form_view.dart';
import 'package:pantry/views/custom_fields/custom_fields_view.dart';
import 'package:pantry/views/labels/labels_view.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/onboarding_view.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';
import 'package:pantry/views/shopping/shopping_session_view.dart';
import 'package:pantry/views/shopping/shopping_start_view.dart';
import 'package:pantry/views/stores/stores_view.dart';
import 'package:pantry/widgets/create_label_dialog.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
import 'checklist_switcher_sheet.dart';
import 'checklists_controller.dart';
import 'checklists_dev_dialogs.dart';
import 'checklists_overflow_menu.dart';
import 'checklists_view.dart' show ChecklistsAppBarSpec;
import 'item_compose_bar.dart';
import 'markdown_export_dialog.dart';
import 'markdown_import_dialog.dart';

/// User's choice from the "item already exists" prompt shown when adding an
/// item whose name collides with one already on the target list.
enum _ReuseChoice { reuse, addAnyway, cancel }

/// Presentation controller for the checklists body: owns the view state
/// (search, filters, compose target, live shopping session) and drives all of
/// the screen's dialogs and navigation. Unlike [ChecklistsController] (the
/// domain controller), this one deliberately takes a [BuildContext] so the
/// widget stays a thin build method.
class ChecklistsBodyController extends ChangeNotifier
    with WidgetsBindingObserver {
  ChecklistsBodyController({
    required this.domain,
    required this.scrollController,
    required this.appBarSpecHolder,
  });

  final ChecklistsController domain;
  final ScrollController? scrollController;
  final ValueNotifier<ChecklistsAppBarSpec?>? appBarSpecHolder;

  bool searchOpen = false;
  bool composeActive = false;
  final searchCtrl = TextEditingController();
  final composeKey = GlobalKey<ItemComposeBarState>();
  // Anchors the desktop switcher popup under the AppBar title row so it
  // reads as a dropdown rather than a centered modal.
  final switcherAnchorKey = GlobalKey();
  final Set<int> selectedCategoryIds = {};
  bool noCategorySelected = false;
  final Set<int> selectedStoreIds = {};
  bool noStoreSelected = false;
  final Set<int> selectedLabelIds = {};
  bool noLabelSelected = false;
  PriceFilter priceFilter = PriceFilter.empty;

  /// In All-lists mode, the most recently chosen target list. Pre-selected on
  /// the next add so the user can rapidly file several items into the same
  /// list. Kept on the body controller (not the domain controller) so it
  /// survives re-renders without leaking into other per-list views.
  int? composeTargetListId;

  /// The caller's live shopping session (any house), polled to drive the
  /// resume banner and the Start/Resume FAB. Null when there's no live trip or
  /// the server lacks the `shopping` capability.
  ShoppingSession? shoppingSession;

  String get query => searchCtrl.text.trim().toLowerCase();

  /// Scroll offset captured the moment a text search begins. Filtering shrinks
  /// the list (and thus `maxScrollExtent`), which clamps the offset near the
  /// top; restoring this on clear/close returns the user to where they were
  /// instead of stranding them at the top.
  double? preSearchOffset;

  bool _disposed = false;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => refreshShoppingSession(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    searchCtrl.dispose();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshShoppingSession();
  }

  // --- Filter / search / compose mutators -----------------------------------

  void toggleSearch() {
    searchOpen = !searchOpen;
    if (!searchOpen) {
      searchCtrl.clear();
      selectedCategoryIds.clear();
      noCategorySelected = false;
      selectedStoreIds.clear();
      noStoreSelected = false;
      selectedLabelIds.clear();
      noLabelSelected = false;
      // Clearing the controller doesn't fire onChanged, so return the
      // list to its pre-search position here.
      restorePreSearchOffset();
    }
    _safeNotify();
  }

  void toggleCategory(int id) {
    if (selectedCategoryIds.contains(id)) {
      selectedCategoryIds.remove(id);
    } else {
      selectedCategoryIds.add(id);
    }
    _safeNotify();
  }

  void clearCategories() {
    selectedCategoryIds.clear();
    noCategorySelected = false;
    _safeNotify();
  }

  void toggleNoCategory() {
    noCategorySelected = !noCategorySelected;
    _safeNotify();
  }

  void toggleStore(int id) {
    if (!selectedStoreIds.remove(id)) selectedStoreIds.add(id);
    _safeNotify();
  }

  void clearStores() {
    selectedStoreIds.clear();
    noStoreSelected = false;
    _safeNotify();
  }

  void toggleNoStore() {
    noStoreSelected = !noStoreSelected;
    _safeNotify();
  }

  void toggleLabel(int id) {
    if (!selectedLabelIds.remove(id)) selectedLabelIds.add(id);
    _safeNotify();
  }

  void clearLabels() {
    selectedLabelIds.clear();
    noLabelSelected = false;
    _safeNotify();
  }

  void toggleNoLabel() {
    noLabelSelected = !noLabelSelected;
    _safeNotify();
  }

  void setPriceFilter(PriceFilter f) {
    priceFilter = f;
    _safeNotify();
  }

  void setComposeActive(bool v) {
    if (v == composeActive) return;
    composeActive = v;
    _safeNotify();
  }

  void setComposeTargetListId(int? id) {
    composeTargetListId = id;
    _safeNotify();
  }

  /// React to search text changes: capture the pre-filter scroll anchor on the
  /// first keystroke, or restore it once the query is cleared back to empty.
  void handleSearchChanged() {
    if (searchCtrl.text.trim().isEmpty) {
      restorePreSearchOffset();
    } else if (preSearchOffset == null) {
      // First keystroke — the list hasn't rebuilt yet, so the controller still
      // reports the full-list offset. Capture it before it gets clamped.
      final ctrl = scrollController;
      if (ctrl != null && ctrl.hasClients) preSearchOffset = ctrl.offset;
    }
    _safeNotify();
  }

  /// Jump back to the captured pre-search offset once the full list has been
  /// restored. Deferred to a post-frame callback so `maxScrollExtent` reflects
  /// the unfiltered list; clamped in case items were removed while filtered.
  void restorePreSearchOffset() {
    final target = preSearchOffset;
    preSearchOffset = null;
    final ctrl = scrollController;
    if (target == null || ctrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !ctrl.hasClients) return;
      final max = ctrl.position.maxScrollExtent;
      ctrl.jumpTo(target > max ? max : target);
    });
  }

  /// Re-fetch the caller's live session so the banner / FAB stay current.
  /// Cheap and side-effect-free (`GET /current`); gated on the capability.
  Future<void> refreshShoppingSession() async {
    if (!hasFeature('shopping')) return;
    try {
      final session = await ShoppingService.instance.getCurrentSession();
      if (_disposed) return;
      shoppingSession = (session?.live ?? false) ? session : null;
      _safeNotify();
    } catch (_) {
      /* keep the last-known state */
    }
  }

  /// Open the shopping flow: resume the live session, or run the start screen
  /// (which returns a freshly created session to navigate into). Refreshes the
  /// banner / FAB on return.
  Future<void> openShopping(BuildContext context) async {
    final existing = shoppingSession;
    if (existing != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShoppingSessionView(session: existing),
        ),
      );
    } else {
      final currentId = domain.currentList?.id;
      final created = await Navigator.of(context).push<ShoppingSession?>(
        MaterialPageRoute(
          builder: (_) => ShoppingStartView(
            houseId: domain.houseId,
            preselectListId: (currentId != null && currentId > 0)
                ? currentId
                : null,
          ),
        ),
      );
      if (created != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingSessionView(session: created),
          ),
        );
      }
    }
    await refreshShoppingSession();
  }

  /// Bottom inset reserved under the item list so neither the resting compose
  /// bar nor the floating Start/Resume-shopping FAB overlaps the last row. Takes
  /// the larger of the two reservations that apply.
  double listBottomInset(ChecklistList? list) {
    if (domain.isSoftView) return 36;
    // Clears the resting compose bar plus a little breathing room.
    const composeReserve = 112.0;
    final fabShown = hasFeature('shopping') && !domain.selectionMode;
    if (!fabShown) return composeReserve;
    // The FAB's own bottom offset (88 above a compose bar, else 16) plus the
    // extended FAB's height and a small gap.
    final fabBottom = (list != null && domain.canAddItemsHere) ? 88.0 : 16.0;
    final fabReserve = fabBottom + 56 + 8;
    return fabReserve > composeReserve ? fabReserve : composeReserve;
  }

  Future<void> openShoppingHistory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingHistoryView(houseId: domain.houseId),
      ),
    );
    await refreshShoppingSession();
  }

  /// The "you're shopping at {store} · [Resume]" banner shown atop the list
  /// while a trip is live. Resolves the active store's name from the
  /// controller's already-loaded store map.
  Widget buildResumeBanner(BuildContext context) {
    final session = shoppingSession!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activeId = session.activeStoreId;
    final store = activeId != null ? domain.stores[activeId] : null;
    final ordered = session.orderedStoreIds;
    final idx = activeId != null ? ordered.indexOf(activeId) : -1;
    final label = store != null
        ? m.shopping.bannerShoppingAt(store.name)
        : m.shopping.bannerShoppingNow;

    return Material(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: () => openShopping(context),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: cs.onPrimaryContainer, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      textDirection: detectTextDirection(store?.name),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (idx >= 0 && ordered.length > 1)
                      Text(
                        m.shopping.bannerStoreProgress(idx + 1, ordered.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => openShopping(context),
                child: Text(m.shopping.resume),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ListItem> applyFilters(List<ListItem> items, Set<int> selectedListIds) {
    final categoryFilterActive =
        selectedCategoryIds.isNotEmpty || noCategorySelected;
    final storeFilterActive = selectedStoreIds.isNotEmpty || noStoreSelected;
    final labelFilterActive = selectedLabelIds.isNotEmpty || noLabelSelected;
    final priceFilterActive = priceFilter.isActive;
    if (!categoryFilterActive &&
        !storeFilterActive &&
        !labelFilterActive &&
        !priceFilterActive &&
        selectedListIds.isEmpty &&
        query.isEmpty) {
      return items;
    }
    return items.where((item) {
      if (categoryFilterActive) {
        final matchesId = selectedCategoryIds.contains(item.categoryId);
        final matchesNone = noCategorySelected && item.categoryId == null;
        if (!matchesId && !matchesNone) return false;
      }
      if (storeFilterActive) {
        final matchesId = item.storeIds.any(selectedStoreIds.contains);
        final matchesNone = noStoreSelected && item.storeIds.isEmpty;
        if (!matchesId && !matchesNone) return false;
      }
      if (labelFilterActive) {
        // Match-ANY (OR): an item passes if it carries at least one selected
        // label; "No label" matches items with no labels.
        final matchesId = item.labelIds.any(selectedLabelIds.contains);
        final matchesNone = noLabelSelected && item.labelIds.isEmpty;
        if (!matchesId && !matchesNone) return false;
      }
      if (priceFilterActive && !matchesPriceFilter(item, priceFilter)) {
        return false;
      }
      if (selectedListIds.isNotEmpty) {
        if (!selectedListIds.contains(item.listId)) return false;
      }
      if (query.isNotEmpty) {
        final n = item.name.toLowerCase().contains(query);
        final d = item.description?.toLowerCase().contains(query) ?? false;
        if (!n && !d) return false;
      }
      return true;
    }).toList();
  }

  Future<void> openSwitcher(BuildContext context) async {
    await showChecklistSwitcher(
      context,
      controller: domain,
      anchorContext: switcherAnchorKey.currentContext,
      itemCountForList: (id) async {
        final cached = ChecklistService.instance.getCachedItems(id);
        if (cached != null) {
          return cached.where((i) => i.deletedAt == null && !i.done).length;
        }
        return -1;
      },
    );
  }

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

  /// Handles a tap on a live reuse suggestion: confirms the user
  /// wants the tapped item instead of adding a new one, then reuses it —
  /// un-checking it if it was already done. Returns true when reused so the
  /// compose bar clears its input.
  Future<bool> reuseFromSuggestion(BuildContext context, ListItem item) async {
    // An archived suggestion is unarchived on confirm, so it warns the user and
    // takes the unarchive path instead of the plain done-toggle reuse.
    final archived = item.archivedAt != null;
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
    if (archived) {
      await domain.reuseArchivedItem(item);
    } else {
      await domain.reuseItem(item);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archived
                ? m.checklists.reuse.reusedArchivedSnack(item.name)
                : m.checklists.reuse.reusedSnack(item.name),
          ),
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(m.checklists.reuse.reusedSnack(existing.name)),
              ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.itemForm.saveFailed)));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.checklists.markdown.imported(added))),
      );
    }
  }

  ChecklistsAppBarSpec buildAppBarSpec(
    BuildContext context,
    ChecklistList? list,
  ) {
    final cs = Theme.of(context).colorScheme;

    // While selecting, the shared AppBar becomes a contextual bar: close to
    // exit, and a live count. The group actions live in the bottom bar.
    if (domain.selectionMode) {
      return ChecklistsAppBarSpec(
        titleSpacing: 4,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: m.common.cancel,
          onPressed: domain.exitSelection,
        ),
        title: Text(
          m.checklists.batch.selected(domain.selectedCount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: cs.onSurface,
          ),
        ),
      );
    }

    final isMeta = list?.id == kAllListsId;
    // Meta uses the theme accent, not list.color (which is null on the
    // sentinel) — gives it a distinct neutral feel from any specific list.
    final tint = isMeta
        ? cs.primary
        : (parseHexColor(list?.color) ?? cs.primary);
    final iconData = isMeta ? allListsIcon : checklistIcon(list?.icon);

    return ChecklistsAppBarSpec(
      // titleSpacing is the gap between the leading slot and the title — set
      // to 11 to match the prior in-content header (SizedBox(width: 11)
      // between the cart tile and the list name).
      titleSpacing: 11,
      // leadingWidth = 20 (start padding) + 40 (icon tile). Combined with
      // titleSpacing:11, the layout matches the prior header exactly:
      // 20px from screen edge → 40px icon → 11px → title.
      leadingWidth: 60,
      leading: list == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 20),
              // Align + SizedBox pin the tile to 40×40 — AppBar's leading
              // slot otherwise passes tight width constraints down through
              // Padding+InkWell and stretches the Container to fill.
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: InkWell(
                    onTap: () => openSwitcher(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: tint, size: 20),
                    ),
                  ),
                ),
              ),
            ),
      title: list == null
          ? const SizedBox.shrink()
          : InkWell(
              key: switcherAnchorKey,
              onTap: () => openSwitcher(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(searchOpen ? Icons.close : Icons.search),
          tooltip: searchOpen ? m.common.cancel : m.checklists.searchHint,
          onPressed: toggleSearch,
        ),
        // Desktop has plenty of room — promote the top four actions out of
        // the overflow menu so they're a single click away. Pin is not
        // surfaced anywhere on desktop because the widget it feeds is
        // Android-only.
        if (PlatformInfo.isDesktop && !domain.isSoftView) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: m.checklists.sortTooltip,
            onSelected: (v) => onOverflow(context, v),
            itemBuilder: (_) => sortMenuItems(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: m.common.refresh,
            onPressed: () => domain.refresh(),
          ),
          if (domain.permissions.canEditLists)
            IconButton(
              icon: const Icon(EntityIcons.category),
              tooltip: m.categories.manageTitle,
              onPressed: () => openManageCategories(context),
            ),
          if (domain.permissions.canEditLists && hasFeature('stores'))
            IconButton(
              icon: const Icon(EntityIcons.store),
              tooltip: m.stores.manageTitle,
              onPressed: () => openManageStores(context),
            ),
          if (domain.permissions.canEditLists && hasFeature('labels'))
            IconButton(
              icon: const Icon(EntityIcons.label),
              tooltip: m.labels.manageTitle,
              onPressed: () => openManageLabels(context),
            ),
          if (domain.permissions.canEditFields && hasFeature('custom-fields'))
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: m.customFields.manageTitle,
              onPressed: () => openManageCustomFields(context),
            ),
          // Meta view has no trash of its own; trash stays per-list.
          if (!domain.isMetaMode &&
              domain.isCurrentListWritable &&
              domain.permissions.canDeleteItems &&
              (supportsFeature('soft-delete') || hasFeature('item-trash')))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: m.checklists.viewTrash,
              onPressed: () => domain.setTrashMode(true),
            ),
          // Archive is per-list too, gated on canEditLists and the
          // item-archive capability.
          if (!domain.isMetaMode &&
              domain.isCurrentListWritable &&
              domain.permissions.canEditLists &&
              hasFeature('item-archive'))
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: m.checklists.viewArchive,
              onPressed: () => domain.setArchiveMode(true),
            ),
        ],
        // Desktop shows the overflow as an anchored popup menu; mobile keeps
        // it in a bottom sheet, which reads and scrolls better on touch.
        if (PlatformInfo.isDesktop)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onSelected: (v) => onOverflow(context, v),
            itemBuilder: (_) => overflowMenuItems(overflowItems()),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onPressed: () => showOverflowSheet(context),
          ),
      ],
    );
  }

  /// Renders the shared overflow [entries] as anchored popup-menu rows for the
  /// desktop toolbar. The bottom-sheet variant renders the same entries as
  /// [ListTile]s in [showOverflowSheet].
  List<PopupMenuEntry<String>> overflowMenuItems(
    List<ChecklistsOverflowEntry> entries,
  ) {
    return [
      for (final entry in entries)
        switch (entry) {
          ChecklistsOverflowDivider() => const PopupMenuDivider(),
          ChecklistsOverflowAction(:final value, :final icon, :final label) =>
            menuRow(value: value, leading: Icon(icon, size: 20), label: label),
          ChecklistsOverflowCheckboxAction(
            :final value,
            :final label,
            :final checked,
          ) =>
            menuRow(
              value: value,
              leading: Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
              ),
              label: label,
            ),
        },
    ];
  }

  /// Sort radio rows lifted out of `overflowItems` so the desktop toolbar's
  /// Sort menu can show only the sort choices, not the rest of the overflow.
  ///
  /// In the meta (All-lists) view, "custom" is suppressed: the underlying
  /// sort order is per-list, so there's no coherent custom order across
  /// lists. The effective sort falls back to "newest".
  List<PopupMenuEntry<String>> sortMenuItems() {
    final effective = domain.effectiveSortBy;
    return [
      for (final o in sortOptions(showCustom: !domain.isMetaMode))
        radioRow(
          value: 'sort_${o.key}',
          label: o.label,
          selected: effective == o.key,
        ),
    ];
  }

  /// The sort choices, in display order. `custom` is suppressed in the meta
  /// (All-lists) view — there's no coherent custom order across lists, so the
  /// effective sort falls back to "newest".
  List<({String key, String label})> sortOptions({required bool showCustom}) {
    return [
      (key: 'newest', label: m.checklists.sort.newestFirst),
      (key: 'oldest', label: m.checklists.sort.oldestFirst),
      (key: 'name_asc', label: m.checklists.sort.nameAZ),
      (key: 'name_desc', label: m.checklists.sort.nameZA),
      (key: 'category', label: m.checklists.sort.category),
      if (hasFeature('store-sort'))
        (key: 'store', label: m.checklists.sort.store),
      if (showCustom) (key: 'custom', label: m.checklists.sort.custom),
    ];
  }

  /// Human label for the currently effective sort — shown on the collapsed
  /// "Sort" overflow row so the active choice is visible without opening it.
  String sortLabel(String effective) {
    for (final o in sortOptions(showCustom: true)) {
      if (o.key == effective) return o.label;
    }
    return m.checklists.sort.newestFirst;
  }

  List<ChecklistsOverflowEntry> overflowItems() {
    final prefs = PrefsService.instance;
    if (domain.isTrashMode) {
      return normalizeOverflow([
        ChecklistsOverflowAction(
          value: 'exit_trash',
          icon: Icons.arrow_back,
          label: m.checklists.exitTrash,
        ),
        // Bulk restore / permanent-delete need a selection; surface the entry
        // point here so it's reachable without a long-press (desktop).
        if (domain.canSelectItems && domain.items.isNotEmpty)
          ChecklistsOverflowAction(
            value: 'select_items',
            icon: Icons.checklist,
            label: m.checklists.selectItems,
          ),
        ChecklistsOverflowAction(
          value: 'empty_trash',
          icon: Icons.delete_forever,
          label: m.checklists.emptyTrash,
        ),
      ]);
    }
    // Archive has no "empty" action — archived items are kept indefinitely.
    if (domain.isArchiveMode) {
      return normalizeOverflow([
        ChecklistsOverflowAction(
          value: 'exit_archive',
          icon: Icons.arrow_back,
          label: m.checklists.exitArchive,
        ),
        // Bulk unarchive / permanent-delete need a selection; surface the
        // entry point here so it's reachable without a long-press (desktop).
        if (domain.canSelectItems && domain.items.isNotEmpty)
          ChecklistsOverflowAction(
            value: 'select_items',
            icon: Icons.checklist,
            label: m.checklists.selectItems,
          ),
      ]);
    }
    // Desktop has promoted refresh / sort / categories / trash to dedicated
    // toolbar buttons, and pinning lists feeds an Android-only widget, so
    // none of those need to live in the overflow menu here. Everything left
    // — the view toggles and the dev tools — stays in overflow on every
    // platform.
    final isMeta = domain.isMetaMode;
    final effective = domain.effectiveSortBy;
    return normalizeOverflow([
      if (domain.canSelectItems && domain.items.isNotEmpty) ...[
        ChecklistsOverflowAction(
          value: 'select_items',
          icon: Icons.checklist,
          label: m.checklists.selectItems,
        ),
        const ChecklistsOverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        ChecklistsOverflowAction(
          value: 'sort',
          icon: Icons.sort,
          label: '${m.checklists.sortTooltip}: ${sortLabel(effective)}',
        ),
        const ChecklistsOverflowDivider(),
        if (domain.currentList != null && !isMeta && PlatformInfo.isMobile)
          ChecklistsOverflowAction(
            value: 'copy_link',
            icon: Icons.link,
            label: m.checklists.copyLink,
          ),
        if (domain.currentList != null && !isMeta && PlatformInfo.isAndroid)
          ChecklistsOverflowAction(
            value: 'add_to_home',
            icon: Icons.add_to_home_screen,
            label: m.checklists.addToHomeScreen,
          ),
      ],
      if (hasFeature('item-authors'))
        ChecklistsOverflowCheckboxAction(
          value: 'toggle_added_by',
          label: m.checklists.showAddedBy,
          checked: domain.showAddedBy,
        ),
      if (domain.currentList != null)
        ChecklistsOverflowCheckboxAction(
          value: 'toggle_progress_hero',
          label: m.checklists.showProgressHero,
          checked: !(domain.currentList!.hideProgressHero),
        ),
      // "Reset custom order" re-seeds sort_order from a chosen basis and leaves
      // the list hand-reorderable. Per-list only (no cross-list custom order in
      // meta) and needs edit permission.
      if (domain.currentList != null &&
          !isMeta &&
          domain.permissions.canEditLists) ...[
        const ChecklistsOverflowDivider(),
        ChecklistsOverflowAction(
          value: 'reset_order',
          icon: Icons.sort_by_alpha,
          label: m.checklists.resetOrder.menuLabel,
        ),
      ],
      // Markdown import/export are per-list only — not offered in the meta
      // "All lists" view, which has no single target.
      if (domain.currentList != null && !isMeta) ...[
        const ChecklistsOverflowDivider(),
        ChecklistsOverflowAction(
          value: 'export_markdown',
          icon: Icons.file_download_outlined,
          label: m.checklists.markdown.exportTitle,
        ),
        if (domain.canAddItemsHere)
          ChecklistsOverflowAction(
            value: 'import_markdown',
            icon: Icons.file_upload_outlined,
            label: m.checklists.markdown.importTitle,
          ),
      ],
      if (hasFeature('shopping')) ...[
        const ChecklistsOverflowDivider(),
        // When the FAB is turned off, its action lives here, above history.
        if (!prefs.startShoppingFabEnabled)
          ChecklistsOverflowAction(
            value: 'start_shopping',
            icon: shoppingSession != null
                ? Icons.play_arrow
                : Icons.shopping_cart,
            label: shoppingSession != null
                ? m.shopping.resumeShopping
                : m.shopping.startShopping,
          ),
        ChecklistsOverflowAction(
          value: 'shopping_history',
          icon: Icons.history,
          label: m.shopping.shoppingHistory,
        ),
        const ChecklistsOverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        if (domain.permissions.canEditLists)
          ChecklistsOverflowAction(
            value: 'manage_categories',
            icon: EntityIcons.category,
            label: m.categories.manageTitle,
          ),
        if (domain.permissions.canEditLists && hasFeature('stores'))
          ChecklistsOverflowAction(
            value: 'manage_stores',
            icon: EntityIcons.store,
            label: m.stores.manageTitle,
          ),
        if (domain.permissions.canEditLists && hasFeature('labels'))
          ChecklistsOverflowAction(
            value: 'manage_labels',
            icon: EntityIcons.label,
            label: m.labels.manageTitle,
          ),
        if (domain.permissions.canEditFields && hasFeature('custom-fields'))
          ChecklistsOverflowAction(
            value: 'manage_custom_fields',
            icon: Icons.tune,
            label: m.customFields.manageTitle,
          ),
        // Mobile has reliable pull-to-refresh, so it doesn't need a menu row.
        // Web (the other non-desktop host here) doesn't, so keep it there.
        if (PlatformInfo.isWeb)
          ChecklistsOverflowAction(
            value: 'refresh',
            icon: Icons.refresh,
            label: m.common.refresh,
          ),
        if (!isMeta &&
            domain.isCurrentListWritable &&
            domain.permissions.canDeleteItems &&
            (supportsFeature('soft-delete') || hasFeature('item-trash'))) ...[
          const ChecklistsOverflowDivider(),
          ChecklistsOverflowAction(
            value: 'view_trash',
            icon: Icons.delete_outline,
            label: m.checklists.viewTrash,
          ),
        ],
        if (!isMeta &&
            domain.isCurrentListWritable &&
            domain.permissions.canEditLists &&
            hasFeature('item-archive'))
          ChecklistsOverflowAction(
            value: 'view_archive',
            icon: Icons.archive_outlined,
            label: m.checklists.viewArchive,
          ),
      ],
      if (kDebugMode) ...[
        const ChecklistsOverflowDivider(),
        ChecklistsOverflowAction(
          value: 'dev_show_onboarding',
          icon: Icons.bug_report_outlined,
          label: m.onboarding.dev.showOnboarding,
        ),
        ChecklistsOverflowCheckboxAction(
          value: 'dev_force_all_features',
          label: m.onboarding.dev.forceAllFeatures,
          checked: prefs.devForceAllFeatures,
        ),
        ChecklistsOverflowAction(
          value: 'dev_test_notification',
          icon: Icons.notifications_active_outlined,
          label: m.onboarding.dev.sendTestNotification,
        ),
      ],
    ]);
  }

  /// Collapses consecutive dividers and strips leading/trailing ones so the
  /// sheet never shows a stray or doubled separator — e.g. the divider below
  /// shopping history when nothing follows it.
  List<ChecklistsOverflowEntry> normalizeOverflow(
    List<ChecklistsOverflowEntry> entries,
  ) {
    final out = <ChecklistsOverflowEntry>[];
    for (final entry in entries) {
      if (entry is ChecklistsOverflowDivider &&
          (out.isEmpty || out.last is ChecklistsOverflowDivider)) {
        continue;
      }
      out.add(entry);
    }
    while (out.isNotEmpty && out.last is ChecklistsOverflowDivider) {
      out.removeLast();
    }
    return out;
  }

  /// Single source of truth for menu-row layout — guarantees that text in
  /// every row sits at the same x offset regardless of whether its leading
  /// is an icon, a radio indicator, a checkbox indicator, or nothing.
  PopupMenuItem<String> menuRow({
    required String value,
    required Widget leading,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          SizedBox(width: 20, height: 20, child: Center(child: leading)),
          const SizedBox(width: 14),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  PopupMenuItem<String> radioRow({
    required String value,
    required String label,
    required bool selected,
  }) => menuRow(
    value: value,
    leading: ChecklistsRadioIndicator(selected: selected),
    label: label,
  );

  /// The AppBar overflow lives in a bottom sheet rather than a popup menu: it
  /// carries enough entries (view toggles, per-list actions, shopping, dev
  /// tools) that a sheet reads and scrolls better than a tall anchored menu.
  Future<void> showOverflowSheet(BuildContext context) async {
    final entries = overflowItems();
    if (entries.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final media = MediaQuery.of(sheetContext);
        // Open sized to the content instead of the default ~half-height cap.
        // Estimate the natural height so a short menu stays short and a long
        // one grows (up to most of the screen) before it needs to scroll.
        const rowHeight = 56.0;
        const handleHeight = 30.0;
        final contentHeight =
            handleHeight +
            media.padding.bottom +
            entries.fold<double>(
              0,
              (h, e) => h + (e is ChecklistsOverflowDivider ? 1.0 : rowHeight),
            );
        final available = media.size.height - media.padding.top;
        final fraction = (contentHeight / available).clamp(0.25, 0.9);
        // DraggableScrollableSheet ties the inner scroll to the sheet's own
        // drag: at the top of the list, a downward swipe drags the whole
        // sheet down (and dismisses it) rather than just overscrolling.
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: fraction,
          maxChildSize: fraction,
          minChildSize: (fraction - 0.2).clamp(0.15, fraction),
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                for (final entry in entries)
                  switch (entry) {
                    ChecklistsOverflowDivider() => const Divider(height: 1),
                    ChecklistsOverflowAction(
                      :final value,
                      :final icon,
                      :final label,
                    ) =>
                      ListTile(
                        leading: Icon(icon),
                        title: Text(label),
                        onTap: () => Navigator.of(sheetContext).pop(value),
                      ),
                    ChecklistsOverflowCheckboxAction(
                      :final value,
                      :final label,
                      :final checked,
                    ) =>
                      ListTile(
                        leading: Icon(
                          checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        title: Text(label),
                        onTap: () => Navigator.of(sheetContext).pop(value),
                      ),
                  },
                SizedBox(height: media.padding.bottom),
              ],
            ),
          ),
        );
      },
    );
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
    final effective = domain.effectiveSortBy;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.sortTooltip),
        children: [
          for (final o in sortOptions(showCustom: !domain.isMetaMode))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.key),
              child: Row(
                children: [
                  ChecklistsRadioIndicator(selected: effective == o.key),
                  const SizedBox(width: 14),
                  Expanded(child: Text(o.label)),
                ],
              ),
            ),
        ],
      ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.resetOrder.success)));
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

  Future<void> openManageCategories(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesView(houseId: domain.houseId),
      ),
    );
    await domain.onCategoriesChanged();
  }

  Future<void> openManageCustomFields(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFieldsView(houseId: domain.houseId),
      ),
    );
  }

  /// Opens the create-category dialog inline from the compose bar's category
  /// tray. On success, refreshes the controller's category list (so the new
  /// option shows up in the tray) and returns the new Category so compose bar
  /// can auto-select it on the draft.
  Future<models.Category?> createCategory(
    BuildContext context, {
    int? defaultListId,
  }) async {
    final created = await Navigator.of(context).push<models.Category>(
      itemModalRoute(
        CategoryFormView(houseId: domain.houseId, defaultListId: defaultListId),
      ),
    );
    if (created != null) {
      await domain.onCategoriesChanged();
    }
    return created;
  }

  Future<void> openManageStores(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoresView(houseId: domain.houseId)),
    );
    await domain.onStoresChanged();
  }

  Future<void> openManageLabels(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LabelsView(houseId: domain.houseId)),
    );
    await domain.onLabelsChanged();
  }

  /// Opens the create-store dialog inline from the compose bar's store tray. On
  /// success, refreshes the controller's store list (so the new option shows up
  /// in the tray) and returns the new Store so compose bar can auto-select it.
  Future<models.Store?> createStore(BuildContext context) async {
    final created = await showDialog<models.Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: domain.houseId),
    );
    if (created != null) {
      await domain.onStoresChanged();
    }
    return created;
  }

  /// Opens the create-label dialog inline from the compose bar's label tray. On
  /// success, refreshes the controller's label list (so the new option shows up
  /// in the tray) and returns the new Label so compose bar can auto-select it.
  Future<models.Label?> createLabel(
    BuildContext context, {
    int? defaultListId,
  }) async {
    final created = await showDialog<models.Label>(
      context: context,
      builder: (_) => CreateLabelDialog(
        houseId: domain.houseId,
        defaultListId: defaultListId,
      ),
    );
    if (created != null) {
      await domain.onLabelsChanged();
    }
    return created;
  }

  Future<void> copyListLink(BuildContext context) async {
    final list = domain.currentList;
    if (list == null) return;
    final uri = ListLink.uri(list.houseId, list.id);
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m.common.copied)));
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m.checklists.addToHomeScreenFailed)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.emptyTrashFailed)));
      }
    }
  }
}
