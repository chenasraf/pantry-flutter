import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/onboarding_view.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/categories/categories_view.dart';
import 'package:pantry/widgets/create_category_dialog.dart';
import 'checklist_item_tile.dart';
import 'checklist_switcher_sheet.dart';
import 'checklists_controller.dart';
import 'item_compose_bar.dart';
import 'item_detail_view.dart';
import 'item_form_view.dart';
import 'markdown_export_dialog.dart';
import 'markdown_import_dialog.dart';
import 'progress_hero.dart';

/// What ChecklistsView wants the shared home AppBar to show while the
/// checklists tab is active. Home owns the actual `AppBar` widget so the
/// Scaffold's AppBar stays the same instance across tab switches; we just
/// hand it the leading / title / actions to display.
class ChecklistsAppBarSpec {
  final Widget? leading;
  final double? leadingWidth;
  final Widget? title;
  final double? titleSpacing;

  /// Checklist-specific actions (search toggle + overflow). Home appends its
  /// own home-level actions (notifications, user menu) after these.
  final List<Widget> actions;

  const ChecklistsAppBarSpec({
    this.leading,
    this.leadingWidth,
    this.title,
    this.titleSpacing,
    this.actions = const [],
  });
}

class ChecklistsView extends StatefulWidget {
  final int houseId;
  final ValueNotifier<Future<void> Function()?>? refreshHolder;

  /// Slot the shared home AppBar reads from while the checklists tab is
  /// active. ChecklistsView writes a fresh spec whenever any state that
  /// affects the AppBar changes (list switched, search toggled, sort changed,
  /// etc.).
  final ValueNotifier<ChecklistsAppBarSpec?>? appBarSpecHolder;

  /// Vertical scroll controller for the items list. Owned by the host so iOS
  /// status-bar-tap can scroll this tab to the top via the host's
  /// [WidgetsBindingObserver.handleStatusBarTap].
  final ScrollController? scrollController;

  const ChecklistsView({
    super.key,
    required this.houseId,
    this.refreshHolder,
    this.appBarSpecHolder,
    this.scrollController,
  });

  @override
  State<ChecklistsView> createState() => _ChecklistsViewState();
}

class _ChecklistsViewState extends State<ChecklistsView>
    with WidgetsBindingObserver {
  late final _controller = ChecklistsController(houseId: widget.houseId);

  /// Polls the server every 30s so the list stays current without the
  /// user pulling-to-refresh. `refresh()` shows cached items immediately and
  /// updates silently in the background once the lists cache is populated.
  /// Paused while the app is hidden/backgrounded so we don't waste a request
  /// the user can't see — and a fresh refresh fires on resume regardless.
  static const _backgroundRefreshInterval = Duration(seconds: 30);
  Timer? _backgroundRefreshTimer;

  @override
  void initState() {
    super.initState();
    _controller.load();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundRefreshTimer();
    final holder = widget.refreshHolder;
    if (holder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        holder.value = _controller.refresh;
      });
    }
  }

  void _startBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(
      _backgroundRefreshInterval,
      (_) => _controller.refresh(),
    );
  }

  void _stopBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.refresh();
        _startBackgroundRefreshTimer();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopBackgroundRefreshTimer();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _stopBackgroundRefreshTimer();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.refreshHolder?.value == _controller.refresh) {
      widget.refreshHolder?.value = null;
    }
    // NOTE: we intentionally do NOT clear `appBarSpecHolder.value` here.
    // Mutating a listenable during dispose triggers ValueListenableBuilder to
    // call setState while the framework's element tree is locked (during
    // unmount), which throws. The spec gets overwritten the next time a
    // ChecklistsView mounts, and home_view's `isChecklistsTab` guard makes
    // any stale spec value irrelevant when we're not on tab 0.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller's view of house capabilities fresh; descendants
    // (sheets, item tiles, the compose bar) gate off `controller.permissions`.
    _controller.permissions = context.watch<HousePermissions>();
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _Body(
        appBarSpecHolder: widget.appBarSpecHolder,
        scrollController: widget.scrollController,
      ),
    );
  }
}

/// User's choice from the "item already exists" prompt shown when adding an
/// item whose name collides with one already on the target list.
enum _ReuseChoice { reuse, addAnyway, cancel }

class _Body extends StatefulWidget {
  final ValueNotifier<ChecklistsAppBarSpec?>? appBarSpecHolder;
  final ScrollController? scrollController;

  const _Body({this.appBarSpecHolder, this.scrollController});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _searchOpen = false;
  bool _composeActive = false;
  final _searchCtrl = TextEditingController();
  final _composeKey = GlobalKey<ItemComposeBarState>();
  // Anchors the desktop switcher popup under the AppBar title row so it
  // reads as a dropdown rather than a centered modal.
  final _switcherAnchorKey = GlobalKey();
  final Set<int> _selectedCategoryIds = {};

  /// In All-lists mode, the most recently chosen target list. Pre-selected on
  /// the next add so the user can rapidly file several items into the same
  /// list. Kept on the body state (not in the controller) so it survives
  /// re-renders without leaking into other per-list views.
  int? _composeTargetListId;

  String get _query => _searchCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ListItem> _applyFilters(List<ListItem> items, Set<int> selectedListIds) {
    if (_selectedCategoryIds.isEmpty &&
        selectedListIds.isEmpty &&
        _query.isEmpty) {
      return items;
    }
    return items.where((item) {
      if (_selectedCategoryIds.isNotEmpty) {
        if (!_selectedCategoryIds.contains(item.categoryId)) return false;
      }
      if (selectedListIds.isNotEmpty) {
        if (!selectedListIds.contains(item.listId)) return false;
      }
      if (_query.isNotEmpty) {
        final n = item.name.toLowerCase().contains(_query);
        final d = item.description?.toLowerCase().contains(_query) ?? false;
        if (!n && !d) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openSwitcher(ChecklistsController c) async {
    await showChecklistSwitcher(
      context,
      controller: c,
      anchorContext: _switcherAnchorKey.currentContext,
      itemCountForList: (id) async {
        final cached = ChecklistService.instance.getCachedItems(id);
        if (cached != null) {
          return cached.where((i) => i.deletedAt == null && !i.done).length;
        }
        return -1;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChecklistsController>();

    if (controller.isLoading && controller.lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null && controller.lists.isEmpty) {
      return _ErrorView(message: controller.error!, onRetry: controller.load);
    }
    if (controller.lists.isEmpty) {
      return _NoListsEmptyState(onCreate: () => _openSwitcher(controller));
    }

    final list = controller.currentList;
    final isMeta = controller.isMetaMode;
    // The per-list filter only exists in the All-lists view. Outside it, an
    // empty set means it never narrows anything.
    final selectedListIds = isMeta
        ? PrefsService.instance.checklistListFilter
        : const <int>{};
    final filteredItems = _applyFilters(controller.items, selectedListIds);
    final activeItems = filteredItems.where((i) => !i.done).toList();
    final doneItems = filteredItems.where((i) => i.done).toList();
    // Drag-to-reorder is only meaningful under custom sort, and only when the
    // active partition is the full set: reordering writes sort_order across the
    // partition, so a category/search filter (or the cross-list meta view)
    // would persist a partial, wrong order. Gate it to the unfiltered case.
    final canReorder =
        controller.effectiveSortBy == 'custom' &&
        !isMeta &&
        !controller.isSoftView &&
        !controller.selectionMode &&
        _selectedCategoryIds.isEmpty &&
        _query.isEmpty &&
        controller.isCurrentListWritable;
    final total = controller.items.where((i) => i.deletedAt == null).length;
    final done = controller.items.where((i) => i.done).length;

    final prefs = context.watch<PrefsService>();
    final isCards = prefs.checklistView == 'cards';
    final doneCollapsed = prefs.checklistDoneCollapsed;
    final isEmptyList = controller.items.isEmpty && !controller.isSoftView;

    // Only categories that have at least one item on this list (excluding
    // trashed items) belong in the filter row — there's no value in
    // letting the user filter by a category that produces zero results.
    // Sort order is preserved from `controller.sortedCategories`.
    final activeCategoryIds = <int>{
      for (final i in controller.items)
        if (i.deletedAt == null && i.categoryId != null) i.categoryId!,
    };
    final filterCategories = controller.sortedCategories
        .where((c) => activeCategoryIds.contains(c.id))
        .toList();

    // The per-list filter (All-lists view only) offers every list, even ones
    // with no items in the current view — unlike categories, an empty list is
    // still a meaningful thing to focus on.
    final filterLists = isMeta
        ? controller.sortedLists.where((l) => l.id != kAllListsId).toList()
        : const <ChecklistList>[];

    // Push the current AppBar contents up to the shared home AppBar slot.
    // Done in a post-frame callback so we don't mutate a listenable during
    // build, which would trigger a rebuild storm.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.appBarSpecHolder?.value = _buildAppBarSpec(
        context,
        controller,
        list,
        prefs,
      );
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compose bar is overlaid on top of the screen content via a Stack
        // so it can grow upward and visually cover the progress hero +
        // filter row when its trays expand, instead of being squeezed by
        // the headers' footprint. ConstrainedBox(maxHeight: full viewport)
        // funnels a finite ceiling down to ItemComposeBar's internal
        // Flexible+SCV, which still scrolls only when even the full
        // viewport isn't enough (e.g. tiny screen + keyboard up).
        return Stack(
          children: [
            Column(
              children: [
                // Animate the search row sliding/fading in and out below
                // the AppBar instead of popping in instantly.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _searchOpen
                        ? _SearchField(
                            key: const ValueKey('search-open'),
                            controller: _searchCtrl,
                            onChanged: () => setState(() {}),
                          )
                        : const SizedBox(
                            key: ValueKey('search-closed'),
                            width: double.infinity,
                          ),
                  ),
                ),
                if (!isEmptyList &&
                    !controller.isSoftView &&
                    !(list?.hideProgressHero ?? false))
                  Dismissible(
                    key: const ValueKey('progress-hero'),
                    direction: DismissDirection.horizontal,
                    // Hides the card for the current list (the All-lists view
                    // persists this locally under id 0). Bring it back from the
                    // list's overflow menu.
                    onDismissed: (_) =>
                        controller.setListHideProgressHero(true),
                    background: const SizedBox.shrink(),
                    child: ProgressHero(
                      total: total,
                      done: done,
                      // Desktop mice can't reliably swipe. Surface a tap
                      // affordance there; the Dismissible above still works
                      // for anyone who can swipe.
                      onDismiss: PlatformInfo.isDesktop
                          ? () => controller.setListHideProgressHero(true)
                          : null,
                    ),
                  ),
                if (!isEmptyList && !controller.isSoftView)
                  _FiltersSection(
                    categories: filterCategories,
                    selectedCategoryIds: _selectedCategoryIds,
                    onToggleCategory: (id) {
                      setState(() {
                        if (_selectedCategoryIds.contains(id)) {
                          _selectedCategoryIds.remove(id);
                        } else {
                          _selectedCategoryIds.add(id);
                        }
                      });
                    },
                    onClearCategories: () =>
                        setState(() => _selectedCategoryIds.clear()),
                    showListFilter: isMeta,
                    lists: filterLists,
                    selectedListIds: selectedListIds,
                    onToggleList: (id) {
                      final next = {...prefs.checklistListFilter};
                      if (!next.remove(id)) next.add(id);
                      prefs.setChecklistListFilter(next);
                    },
                    onClearLists: () => prefs.setChecklistListFilter({}),
                    view: prefs.checklistView,
                    onViewChanged: (v) => prefs.setChecklistView(v),
                  ),
                if (controller.isTrashMode)
                  _TrashBanner(onExit: () => controller.setTrashMode(false)),
                if (controller.isArchiveMode)
                  _ArchiveBanner(
                    onExit: () => controller.setArchiveMode(false),
                  ),
                Expanded(
                  // While a fresh list (no cached items yet) is loading, show a
                  // spinner rather than the empty state — the list isn't empty,
                  // it just hasn't arrived. Once items are on screen, in-place
                  // reloads (e.g. a sort change) keep them visible and overlay
                  // a thin refresh bar instead of flashing empty.
                  child: controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : controller.itemsUnavailable
                      // Fetch failed with nothing cached (typically offline) —
                      // show a retry affordance rather than the empty state,
                      // which otherwise reads as "my data is gone" (issue #92).
                      ? _ErrorView(
                          message: m.checklists.failedToLoadItems,
                          onRetry: () {
                            final cur = controller.currentList;
                            if (cur != null) controller.selectList(cur);
                          },
                        )
                      : isEmptyList
                      ? _NoItemsEmptyState()
                      : (filteredItems.isEmpty
                            ? _NoMatchesEmptyState()
                            : Stack(
                                children: [
                                  Padding(
                                    // Reserve enough room for the resting
                                    // compose bar so the last item is always
                                    // reachable without the bar overlapping it.
                                    padding: const EdgeInsets.only(bottom: 76),
                                    child: _ItemList(
                                      controller: controller,
                                      activeItems: activeItems,
                                      doneItems: doneItems,
                                      canReorder: canReorder,
                                      isCards: isCards,
                                      doneCollapsed: doneCollapsed,
                                      groupByCategory:
                                          controller.sortBy == 'category',
                                      onToggleDoneCollapsed: () =>
                                          prefs.setChecklistDoneCollapsed(
                                            !doneCollapsed,
                                          ),
                                      scrollController: widget.scrollController,
                                    ),
                                  ),
                                  if (controller.isRefreshing)
                                    const PositionedDirectional(
                                      top: 0,
                                      start: 0,
                                      end: 0,
                                      child: LinearProgressIndicator(
                                        minHeight: 2,
                                      ),
                                    ),
                                ],
                              )),
                ),
              ],
            ),
            // Scrim — fades in/out with compose-active state, always present
            // so AnimatedOpacity has something to interpolate. IgnorePointer
            // prevents the invisible scrim from eating taps when inactive.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_composeActive,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _composeActive ? 1.0 : 0.0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        _composeKey.currentState?.dismissKeepingDraft(),
                    child: const ColoredBox(color: Colors.black54),
                  ),
                ),
              ),
            ),
            if (!controller.isSoftView &&
                !controller.selectionMode &&
                list != null &&
                controller.canAddItemsHere)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  child: Builder(
                    builder: (context) {
                      final meta = controller.isMetaMode;
                      // In meta mode, drop the synthetic from the picker —
                      // it's not a real target.
                      final realLists = meta
                          ? controller.lists
                                .where((l) => l.id != kAllListsId)
                                .toList()
                          : null;
                      // Heal an orphaned selection (target list was deleted
                      // since last add) by clearing it silently.
                      if (meta &&
                          _composeTargetListId != null &&
                          !realLists!.any(
                            (l) => l.id == _composeTargetListId,
                          )) {
                        _composeTargetListId = null;
                      }
                      return ItemComposeBar(
                        key: _composeKey,
                        listName: list.name,
                        deleteOnDoneDefault: meta
                            ? false
                            : list.deleteOnDoneDefault,
                        categories: controller.sortedCategories,
                        initiallyFocused: false,
                        targetLists: realLists,
                        selectedTargetListId: meta
                            ? _composeTargetListId
                            : null,
                        onTargetListChanged: (id) {
                          setState(() => _composeTargetListId = id);
                        },
                        onActiveChanged: (active) {
                          if (active != _composeActive) {
                            setState(() => _composeActive = active);
                          }
                        },
                        onRequestCreateCategory:
                            controller.permissions.canEditLists
                            ? () => _createCategory(context, controller)
                            : null,
                        onSubmit: (s) async {
                          final targetListId = meta
                              ? _composeTargetListId
                              : list.id;
                          if (targetListId == null) return false;
                          return _addItemHonoringReuse(
                            context,
                            controller,
                            prefs,
                            targetListId: targetListId,
                            meta: meta,
                            s: s,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            if (controller.selectionMode)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: _SelectionActionBar(controller: controller),
              ),
          ],
        );
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

  /// Adds a single item to [targetListId], honoring the reuse-existing-items
  /// pref (reuse silently / ask per duplicate / add). [forceReuse] forces the
  /// "reuse" behavior for this add regardless of the global pref — used by the
  /// Markdown import flow. Returns true on a successful add or graceful reuse,
  /// false on cancel or error. Shared by the compose bar and the importer so a
  /// single add path honors the pref consistently.
  Future<bool> _addItemHonoringReuse(
    BuildContext context,
    ChecklistsController controller,
    PrefsService prefs, {
    required int targetListId,
    required bool meta,
    required ComposeSubmission s,
    bool forceReuse = false,
  }) async {
    // Reuse existing items: only when the server advertises the capability and
    // the effective mode isn't "never". On a name collision in the target
    // list, reuse (un-check) the existing item instead of adding a duplicate —
    // silently for "reuse", or after confirming for "ask".
    final mode = forceReuse ? 'reuse' : prefs.reuseExistingItems;
    if (hasFeature('reuse-existing-items') && mode != 'never') {
      final existing = controller.findExistingItem(targetListId, s.name);
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
          await controller.reuseItem(existing);
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
        created = await controller.addItemTo(
          targetListId: targetListId,
          name: s.name,
          description: s.description,
          quantity: s.quantity,
          categoryId: s.categoryId,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
        );
      } else {
        created = await controller.addItem(
          name: s.name,
          description: s.description,
          quantity: s.quantity,
          categoryId: s.categoryId,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
        );
      }
      if (s.imageBytes != null) {
        await controller.uploadItemImage(
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
  Future<void> _openExport(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final list = controller.currentList;
    if (list == null || list.id == kAllListsId) return;
    final items = controller.items.where((i) => i.deletedAt == null).toList();
    await showDialog<void>(
      context: context,
      builder: (_) => MarkdownExportDialog(
        listName: list.name,
        items: items,
        categoryFor: (id) => id == null ? null : controller.categories[id],
      ),
    );
  }

  /// Opens the Markdown import dialog, then adds each selected item through the
  /// shared reuse-aware add path. Processed sequentially so any "ask" prompts
  /// resolve one at a time and names repeated within the batch dedupe against
  /// the items added earlier in the same import.
  Future<void> _openImport(
    BuildContext context,
    ChecklistsController controller,
    PrefsService prefs,
  ) async {
    final list = controller.currentList;
    if (list == null || list.id == kAllListsId) return;
    final targetListId = list.id;
    // Close the dialog (it pops itself with the result) before processing so
    // any "ask" reuse prompts render over the list, not stacked on the dialog.
    final result = await showDialog<MarkdownImportResult>(
      context: context,
      builder: (_) => MarkdownImportDialog(
        categories: controller.sortedCategories,
        reusePref: prefs.reuseExistingItems,
        reuseFeatureAvailable: hasFeature('reuse-existing-items'),
        onRequestCreateCategory: () => _createCategory(context, controller),
      ),
    );
    if (result == null || !context.mounted) return;
    var added = 0;
    for (final s in result.submissions) {
      final ok = await _addItemHonoringReuse(
        context,
        controller,
        prefs,
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

  ChecklistsAppBarSpec _buildAppBarSpec(
    BuildContext context,
    ChecklistsController controller,
    ChecklistList? list,
    PrefsService prefs,
  ) {
    final cs = Theme.of(context).colorScheme;

    // While selecting, the shared AppBar becomes a contextual bar: close to
    // exit, and a live count. The group actions live in the bottom bar.
    if (controller.selectionMode) {
      return ChecklistsAppBarSpec(
        titleSpacing: 4,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: m.common.cancel,
          onPressed: controller.exitSelection,
        ),
        title: Text(
          m.checklists.batch.selected(controller.selectedCount),
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
    final isPinned =
        list != null && !isMeta && PrefsService.instance.isListPinned(list.id);

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
                    onTap: () => _openSwitcher(controller),
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
              key: _switcherAnchorKey,
              onTap: () => _openSwitcher(controller),
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
          icon: Icon(_searchOpen ? Icons.close : Icons.search),
          tooltip: _searchOpen ? m.common.cancel : m.checklists.searchHint,
          onPressed: () {
            setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) {
                _searchCtrl.clear();
                _selectedCategoryIds.clear();
              }
            });
          },
        ),
        // Desktop has plenty of room — promote the top four actions out of
        // the overflow menu so they're a single click away. Pin is not
        // surfaced anywhere on desktop because the widget it feeds is
        // Android-only.
        if (PlatformInfo.isDesktop && !controller.isSoftView) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: m.checklists.sortTooltip,
            onSelected: (v) => _onOverflow(context, controller, v),
            itemBuilder: (_) => _sortMenuItems(controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: m.common.refresh,
            onPressed: () => controller.refresh(),
          ),
          if (controller.permissions.canEditLists)
            IconButton(
              icon: const Icon(Icons.sell_outlined),
              tooltip: m.categories.manageTitle,
              onPressed: () => _openManageCategories(context, controller),
            ),
          // Meta view has no trash of its own; trash stays per-list.
          if (!controller.isMetaMode &&
              controller.isCurrentListWritable &&
              controller.permissions.canDeleteItems &&
              (supportsFeature('soft-delete') || hasFeature('item-trash')))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: m.checklists.viewTrash,
              onPressed: () => controller.setTrashMode(true),
            ),
          // Archive is per-list too, gated on canEditLists and the
          // item-archive capability.
          if (!controller.isMetaMode &&
              controller.isCurrentListWritable &&
              controller.permissions.canEditLists &&
              hasFeature('item-archive'))
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: m.checklists.viewArchive,
              onPressed: () => controller.setArchiveMode(true),
            ),
        ],
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) => _onOverflow(context, controller, v),
          itemBuilder: (_) =>
              _overflowItems(controller, prefs, isPinned: isPinned),
        ),
      ],
    );
  }

  /// Sort radio rows lifted out of `_overflowItems` so the desktop toolbar's
  /// Sort menu can show only the sort choices, not the rest of the overflow.
  ///
  /// In the meta (All-lists) view, "custom" is suppressed: the underlying
  /// sort order is per-list, so there's no coherent custom order across
  /// lists. The effective sort falls back to "newest".
  List<PopupMenuEntry<String>> _sortMenuItems(ChecklistsController controller) {
    final showCustom = !controller.isMetaMode;
    final effective = controller.effectiveSortBy;
    return [
      _radioRow(
        value: 'sort_newest',
        label: m.checklists.sort.newestFirst,
        selected: effective == 'newest',
      ),
      _radioRow(
        value: 'sort_oldest',
        label: m.checklists.sort.oldestFirst,
        selected: effective == 'oldest',
      ),
      _radioRow(
        value: 'sort_name_asc',
        label: m.checklists.sort.nameAZ,
        selected: effective == 'name_asc',
      ),
      _radioRow(
        value: 'sort_name_desc',
        label: m.checklists.sort.nameZA,
        selected: effective == 'name_desc',
      ),
      _radioRow(
        value: 'sort_category',
        label: m.checklists.sort.category,
        selected: effective == 'category',
      ),
      if (showCustom)
        _radioRow(
          value: 'sort_custom',
          label: m.checklists.sort.custom,
          selected: effective == 'custom',
        ),
    ];
  }

  List<PopupMenuEntry<String>> _overflowItems(
    ChecklistsController controller,
    PrefsService prefs, {
    required bool isPinned,
  }) {
    if (controller.isTrashMode) {
      return [
        _menuRow(
          value: 'exit_trash',
          leading: const Icon(Icons.arrow_back, size: 18),
          label: m.checklists.exitTrash,
        ),
        // Bulk restore / permanent-delete need a selection; surface the entry
        // point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
          _menuRow(
            value: 'select_items',
            leading: const Icon(Icons.checklist, size: 18),
            label: m.checklists.selectItems,
          ),
        _menuRow(
          value: 'empty_trash',
          leading: const Icon(Icons.delete_forever, size: 18),
          label: m.checklists.emptyTrash,
        ),
      ];
    }
    // Archive has no "empty" action — archived items are kept indefinitely.
    if (controller.isArchiveMode) {
      return [
        _menuRow(
          value: 'exit_archive',
          leading: const Icon(Icons.arrow_back, size: 18),
          label: m.checklists.exitArchive,
        ),
        // Bulk unarchive / permanent-delete need a selection; surface the
        // entry point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
          _menuRow(
            value: 'select_items',
            leading: const Icon(Icons.checklist, size: 18),
            label: m.checklists.selectItems,
          ),
      ];
    }
    // Desktop has promoted refresh / sort / categories / trash to dedicated
    // toolbar buttons, and pinning lists feeds an Android-only widget, so
    // none of those need to live in the overflow menu here. Everything left
    // — the view toggles and the dev tools — stays in overflow on every
    // platform.
    final isMeta = controller.isMetaMode;
    final effective = controller.effectiveSortBy;
    return <PopupMenuEntry<String>>[
      if (controller.canSelectItems && controller.items.isNotEmpty) ...[
        _menuRow(
          value: 'select_items',
          leading: const Icon(Icons.checklist, size: 18),
          label: m.checklists.selectItems,
        ),
        const PopupMenuDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        _radioRow(
          value: 'sort_newest',
          label: m.checklists.sort.newestFirst,
          selected: effective == 'newest',
        ),
        _radioRow(
          value: 'sort_oldest',
          label: m.checklists.sort.oldestFirst,
          selected: effective == 'oldest',
        ),
        _radioRow(
          value: 'sort_name_asc',
          label: m.checklists.sort.nameAZ,
          selected: effective == 'name_asc',
        ),
        _radioRow(
          value: 'sort_name_desc',
          label: m.checklists.sort.nameZA,
          selected: effective == 'name_desc',
        ),
        _radioRow(
          value: 'sort_category',
          label: m.checklists.sort.category,
          selected: effective == 'category',
        ),
        if (!isMeta)
          _radioRow(
            value: 'sort_custom',
            label: m.checklists.sort.custom,
            selected: effective == 'custom',
          ),
        const PopupMenuDivider(),
        if (controller.currentList != null && !isMeta)
          _menuRow(
            value: 'toggle_pin',
            leading: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
            ),
            label: isPinned ? m.checklists.unpinList : m.checklists.pinList,
          ),
      ],
      if (hasFeature('item-authors'))
        _checkboxRow(
          value: 'toggle_added_by',
          label: m.checklists.showAddedBy,
          selected: controller.showAddedBy,
        ),
      if (controller.currentList != null)
        _checkboxRow(
          value: 'toggle_progress_hero',
          label: m.checklists.showProgressHero,
          selected: !(controller.currentList!.hideProgressHero),
        ),
      // Markdown import/export are per-list only — not offered in the meta
      // "All lists" view, which has no single target.
      if (controller.currentList != null && !isMeta) ...[
        const PopupMenuDivider(),
        _menuRow(
          value: 'export_markdown',
          leading: const Icon(Icons.file_download_outlined, size: 18),
          label: m.checklists.markdown.exportTitle,
        ),
        if (controller.canAddItemsHere)
          _menuRow(
            value: 'import_markdown',
            leading: const Icon(Icons.file_upload_outlined, size: 18),
            label: m.checklists.markdown.importTitle,
          ),
      ],
      if (!PlatformInfo.isDesktop) ...[
        if (controller.permissions.canEditLists)
          _menuRow(
            value: 'manage_categories',
            leading: const Icon(Icons.sell_outlined, size: 18),
            label: m.categories.manageTitle,
          ),
        _menuRow(
          value: 'refresh',
          leading: const Icon(Icons.refresh, size: 18),
          label: m.common.refresh,
        ),
        if (!isMeta &&
            controller.isCurrentListWritable &&
            controller.permissions.canDeleteItems &&
            (supportsFeature('soft-delete') || hasFeature('item-trash'))) ...[
          const PopupMenuDivider(),
          _menuRow(
            value: 'view_trash',
            leading: const Icon(Icons.delete_outline, size: 18),
            label: m.checklists.viewTrash,
          ),
        ],
        if (!isMeta &&
            controller.isCurrentListWritable &&
            controller.permissions.canEditLists &&
            hasFeature('item-archive'))
          _menuRow(
            value: 'view_archive',
            leading: const Icon(Icons.archive_outlined, size: 18),
            label: m.checklists.viewArchive,
          ),
      ],
      if (kDebugMode) ...[
        const PopupMenuDivider(),
        _menuRow(
          value: 'dev_show_onboarding',
          leading: const Icon(Icons.bug_report_outlined, size: 18),
          label: m.onboarding.dev.showOnboarding,
        ),
        _checkboxRow(
          value: 'dev_force_all_features',
          label: m.onboarding.dev.forceAllFeatures,
          selected: prefs.devForceAllFeatures,
        ),
        _menuRow(
          value: 'dev_test_notification',
          leading: const Icon(Icons.notifications_active_outlined, size: 18),
          label: m.onboarding.dev.sendTestNotification,
        ),
      ],
    ];
  }

  /// Single source of truth for menu-row layout — guarantees that text in
  /// every row sits at the same x offset regardless of whether its leading
  /// is an icon, a radio indicator, a checkbox indicator, or nothing.
  PopupMenuItem<String> _menuRow({
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

  PopupMenuItem<String> _radioRow({
    required String value,
    required String label,
    required bool selected,
  }) => _menuRow(
    value: value,
    leading: _RadioIndicator(selected: selected),
    label: label,
  );

  PopupMenuItem<String> _checkboxRow({
    required String value,
    required String label,
    required bool selected,
  }) => _menuRow(
    value: value,
    leading: _CheckboxIndicator(selected: selected),
    label: label,
  );

  Future<void> _onOverflow(
    BuildContext context,
    ChecklistsController controller,
    String value,
  ) async {
    final prefs = PrefsService.instance;
    switch (value) {
      case 'select_items':
        controller.enterSelection();
      case 'sort_newest':
        await controller.setSortBy('newest');
      case 'sort_oldest':
        await controller.setSortBy('oldest');
      case 'sort_name_asc':
        await controller.setSortBy('name_asc');
      case 'sort_name_desc':
        await controller.setSortBy('name_desc');
      case 'sort_category':
        await controller.setSortBy('category');
      case 'sort_custom':
        await controller.setSortBy('custom');
      case 'toggle_added_by':
        await controller.setShowAddedBy(!controller.showAddedBy);
      case 'toggle_progress_hero':
        final current = controller.currentList;
        if (current != null) {
          await controller.setListHideProgressHero(!current.hideProgressHero);
        }
      case 'view_trash':
        await controller.setTrashMode(true);
      case 'exit_trash':
        await controller.setTrashMode(false);
      case 'empty_trash':
        await _confirmEmptyTrash(context, controller);
      case 'view_archive':
        await controller.setArchiveMode(true);
      case 'exit_archive':
        await controller.setArchiveMode(false);
      case 'toggle_pin':
        await _togglePin(context, controller);
      case 'manage_categories':
        await _openManageCategories(context, controller);
      case 'export_markdown':
        await _openExport(context, controller);
      case 'import_markdown':
        await _openImport(context, controller, prefs);
      case 'refresh':
        await controller.refresh();
      case 'dev_show_onboarding':
        await _devShowOnboarding(context);
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

  /// Dev-only flow: pick a "last seen" version to seed prefs with, then push
  /// the onboarding view. Lets us preview what users with various upgrade
  /// histories will see without uninstalling the app.
  Future<void> _devShowOnboarding(BuildContext context) async {
    final picked = await showDialog<_DevLastSeenChoice>(
      context: context,
      builder: (ctx) => _DevLastSeenPickerDialog(),
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

  Future<void> _openManageCategories(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesView(houseId: controller.houseId),
      ),
    );
    await controller.onCategoriesChanged();
  }

  /// Opens the create-category dialog inline from the compose bar's category
  /// tray. On success, refreshes the controller's category list (so the new
  /// option shows up in the tray) and returns the new Category so compose bar
  /// can auto-select it on the draft.
  Future<models.Category?> _createCategory(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final created = await showDialog<models.Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(houseId: controller.houseId),
    );
    if (created != null) {
      await controller.onCategoriesChanged();
    }
    return created;
  }

  Future<void> _togglePin(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final list = controller.currentList;
    if (list == null) return;
    final prefs = PrefsService.instance;
    final willBePinned = !prefs.isListPinned(list.id);
    final nextPinnedIds = Set<int>.from(prefs.pinnedListIds);
    if (willBePinned) {
      nextPinnedIds.add(list.id);
    } else {
      nextPinnedIds.remove(list.id);
    }
    final cs = ChecklistService.instance;
    final housesById = {
      for (final h in HouseService.instance.getCached() ?? []) h.id: h.name,
    };
    final allPinned = controller.lists
        .where((l) => nextPinnedIds.contains(l.id))
        .map((l) {
          final cached = cs.getCachedItems(l.id) ?? [];
          final active = cached.where((i) => i.deletedAt == null).toList();
          final unchecked = active.where((i) => !i.done).length;
          return {
            'id': l.id,
            'name': l.name,
            'houseId': l.houseId,
            'houseName': housesById[l.houseId],
            'icon': l.icon,
            'unchecked': unchecked,
            'total': active.length,
          };
        })
        .toList();
    await prefs.togglePinnedList(list.id, allPinned);
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    ChecklistsController controller,
  ) async {
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
      await controller.emptyTrash();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.emptyTrashFailed)));
      }
    }
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: m.checklists.searchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

/// The filter header above the item list: a category filter, plus — in the
/// All-lists view — a parallel per-list filter. Desktop stacks both filters
/// in their own rows; mobile shows one at a time and lets the user swap which
/// fills the row via a pair of icon buttons, keeping the header compact.
class _FiltersSection extends StatefulWidget {
  final List<models.Category> categories;
  final Set<int> selectedCategoryIds;
  final ValueChanged<int> onToggleCategory;
  final VoidCallback onClearCategories;

  /// All-lists view only — when false, no list filter is shown at all.
  final bool showListFilter;
  final List<ChecklistList> lists;
  final Set<int> selectedListIds;
  final ValueChanged<int> onToggleList;
  final VoidCallback onClearLists;

  final String view;
  final ValueChanged<String> onViewChanged;

  const _FiltersSection({
    required this.categories,
    required this.selectedCategoryIds,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.showListFilter,
    required this.lists,
    required this.selectedListIds,
    required this.onToggleList,
    required this.onClearLists,
    required this.view,
    required this.onViewChanged,
  });

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  /// Which filter fills the expanded strip in the mobile All-lists layout —
  /// `'list'` or `'category'`. Ephemeral (resets when leaving the view); the
  /// selections themselves persist via prefs / state, not this toggle.
  String _mobileActive = 'list';

  List<Widget> _categoryChips(ColorScheme cs) {
    return [
      _Chip(
        label: m.checklists.allCategories,
        selected: widget.selectedCategoryIds.isEmpty,
        color: cs.primary,
        onTap: widget.onClearCategories,
      ),
      for (final c in widget.categories) ...[
        const SizedBox(width: 8),
        _Chip(
          label: c.name,
          selected: widget.selectedCategoryIds.contains(c.id),
          color: parseHexColor(c.color) ?? cs.primary,
          onTap: () => widget.onToggleCategory(c.id),
        ),
      ],
    ];
  }

  List<Widget> _listChips(ColorScheme cs) {
    return [
      _Chip(
        label: m.checklists.allListsChip,
        selected: widget.selectedListIds.isEmpty,
        color: cs.primary,
        icon: allListsIcon,
        onTap: widget.onClearLists,
      ),
      for (final l in widget.lists) ...[
        const SizedBox(width: 8),
        _Chip(
          label: l.name,
          selected: widget.selectedListIds.contains(l.id),
          color: parseHexColor(l.color) ?? cs.primary,
          icon: checklistIcon(l.icon),
          onTap: () => widget.onToggleList(l.id),
        ),
      ],
    ];
  }

  /// Transition for the mobile chip-strip swap: the list filter lives at the
  /// leading edge and the category filter at the trailing edge, so each strip
  /// slides in from (and out toward) its own side while cross-fading. The
  /// incoming and outgoing strips travel opposite directions, reading as the
  /// two filters trading places.
  Widget _swapTransition(Widget child, Animation<double> animation) {
    final key = child.key;
    final fromLeading = key is ValueKey<String> && key.value.endsWith('list');
    final begin = fromLeading ? const Offset(-1, 0) : const Offset(1, 0);
    return ClipRect(
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          textDirection: Directionality.of(context),
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final toggle = _ViewToggle(
      view: widget.view,
      onChanged: widget.onViewChanged,
    );

    // No list filter (single list), or desktop where there's room to stack
    // both filters: render the strip(s) at full width with the view toggle
    // pinned to the trailing edge.
    if (!widget.showListFilter || PlatformInfo.isDesktop) {
      final Widget strips;
      if (widget.showListFilter) {
        strips = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChipStrip(children: _listChips(cs)),
            const SizedBox(height: 8),
            _ChipStrip(children: _categoryChips(cs)),
          ],
        );
      } else {
        strips = _ChipStrip(children: _categoryChips(cs));
      }
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 4),
        child: Row(
          children: [
            Expanded(child: strips),
            const SizedBox(width: 10),
            toggle,
          ],
        ),
      );
    }

    // Mobile All-lists: one filter fills the row; the other parks as an icon
    // button next to the view toggle. The two buttons keep their identity and
    // physically slide between the leading and trailing slots when swapped —
    // tapping the parked button glides it into the leading slot as its filter
    // expands, and the previously-active button slides out to park.
    final isList = _mobileActive == 'list';
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                const btn = 40.0;
                const gap = 8.0;
                final rtl = Directionality.of(context) == TextDirection.rtl;
                // Positioned.left is always measured from the physical left
                // edge, so flip the slots by hand for RTL.
                final leadingX = rtl ? c.maxWidth - btn : 0.0;
                final trailingX = rtl ? 0.0 : c.maxWidth - btn;
                const dur = Duration(milliseconds: 280);
                const curve = Curves.easeInOutCubic;
                return SizedBox(
                  height: 36,
                  child: Stack(
                    children: [
                      // Strip sits in the fixed gap between the two button
                      // slots; only its chips swap as the active filter
                      // changes.
                      PositionedDirectional(
                        start: btn + gap,
                        end: btn + gap,
                        top: 0,
                        bottom: 0,
                        child: AnimatedSwitcher(
                          duration: dur,
                          transitionBuilder: _swapTransition,
                          child: _ChipStrip(
                            key: ValueKey('strip-$_mobileActive'),
                            children: isList
                                ? _listChips(cs)
                                : _categoryChips(cs),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: dur,
                        curve: curve,
                        left: isList ? leadingX : trailingX,
                        width: btn,
                        top: 0,
                        bottom: 0,
                        child: _FilterModeIcon(
                          icon: allListsIcon,
                          active: isList,
                          tooltip: m.checklists.filterByList,
                          onTap: () => setState(() => _mobileActive = 'list'),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: dur,
                        curve: curve,
                        left: isList ? trailingX : leadingX,
                        width: btn,
                        top: 0,
                        bottom: 0,
                        child: _FilterModeIcon(
                          icon: Icons.label_outline,
                          active: !isList,
                          tooltip: m.checklists.filterByCategory,
                          onTap: () =>
                              setState(() => _mobileActive = 'category'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          toggle,
        ],
      ),
    );
  }
}

/// A single horizontally-scrollable strip of filter chips with a trailing
/// fade that signals "more content past the edge". Used for both the category
/// and the list filters.
class _ChipStrip extends StatefulWidget {
  final List<Widget> children;

  const _ChipStrip({required this.children, super.key});

  @override
  State<_ChipStrip> createState() => _ChipStripState();
}

class _ChipStripState extends State<_ChipStrip> {
  final _scrollCtrl = ScrollController();

  /// 0 = no trailing fade (content fits, or scrolled to the end); 1 = full
  /// fade (more content beyond the visible trailing edge). Tweens through
  /// intermediate values as the user scrolls past the last [_fadeWidth] px so
  /// the fade eases off into "you're at the end".
  double _trailingFade = 0;

  /// Width over which the trailing fade transitions from full to none as the
  /// user scrolls toward the end. Roughly matches the visual fade band.
  static const double _fadeWidth = 36;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_recompute);
    // First-frame recompute — the controller isn't attached to a viewport
    // until after the first layout pass.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  @override
  void didUpdateWidget(_ChipStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chip count can change (filter set grows/shrinks), which shifts
    // maxScrollExtent without firing a scroll event. Re-check after the
    // post-layout pass.
    if (oldWidget.children.length != widget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_recompute);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _recompute() {
    if (!mounted || !_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    double fade;
    if (pos.maxScrollExtent <= 0) {
      fade = 0;
    } else {
      final remaining = pos.maxScrollExtent - pos.pixels;
      fade = (remaining / _fadeWidth).clamp(0.0, 1.0);
    }
    if (fade != _trailingFade) {
      setState(() => _trailingFade = fade);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      // ShaderMask fades the trailing edge of the chip row to signal more
      // content exists past the cutoff. The mask uses dstIn so the gradient's
      // alpha becomes the row's alpha; the gradient direction flips for RTL so
      // the fade always sits at the visual trailing edge. The trailing color's
      // alpha tracks `_trailingFade` so it eases off to zero (i.e. opaque, no
      // fade) as the user reaches the end or when the chips fit.
      child: NotificationListener<ScrollMetricsNotification>(
        // Fires when maxScrollExtent changes (e.g. content reflow) without a
        // scroll event — needed to catch "now everything fits" transitions.
        onNotification: (_) {
          _recompute();
          return false;
        },
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            final isRtl = Directionality.of(context) == TextDirection.rtl;
            return LinearGradient(
              begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
              stops: const [0.0, 0.88, 1.0],
              colors: [
                Colors.black,
                Colors.black,
                Colors.black.withValues(alpha: 1 - _trailingFade),
              ],
            ).createShader(bounds);
          },
          child: ListView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}

/// Square icon button that toggles which filter fills the mobile All-lists
/// strip. Mirrors the chip styling — filled with the accent when its filter
/// is the active (expanded) one.
class _FilterModeIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _FilterModeIcon({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          width: 40,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surfaceContainerHighest,
            border: Border.all(color: active ? cs.primary : cs.outlineVariant),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  /// When set, the chip leads with this icon (tinted by [color]) instead of
  /// the plain color dot — used by the list filter to surface each list's
  /// icon, mirroring how lists read elsewhere in the app.
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : cs.surfaceContainerHighest,
          border: Border.all(color: selected ? color : cs.outlineVariant),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 15, color: selected ? cs.surface : color)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? cs.surface : color,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? cs.surface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final String view;
  final ValueChanged<String> onChanged;

  const _ViewToggle({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _ViewToggleBtn(
            icon: Icons.format_list_bulleted,
            active: view == 'list',
            onTap: () => onChanged('list'),
            tooltip: m.checklists.viewList,
          ),
          _ViewToggleBtn(
            icon: Icons.grid_view,
            active: view == 'cards',
            onTap: () => onChanged('cards'),
            tooltip: m.checklists.viewCards,
          ),
        ],
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  const _ViewToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _ItemList extends StatefulWidget {
  final ChecklistsController controller;
  final List<ListItem> activeItems;
  final List<ListItem> doneItems;
  final bool canReorder;
  final bool isCards;
  final bool doneCollapsed;

  /// When true (category sort), items render grouped under category headers.
  final bool groupByCategory;
  final VoidCallback onToggleDoneCollapsed;
  final ScrollController? scrollController;

  const _ItemList({
    required this.controller,
    required this.activeItems,
    required this.doneItems,
    required this.canReorder,
    required this.isCards,
    required this.doneCollapsed,
    required this.groupByCategory,
    required this.onToggleDoneCollapsed,
    this.scrollController,
  });

  @override
  State<_ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<_ItemList> {
  // Fallback when no external controller is supplied (e.g. in tests). When
  // the host provides one (the normal path from home_view) we use that so
  // iOS status-bar-tap can scroll this list to the top.
  ScrollController? _ownedScrollController;
  ScrollController get _scrollController =>
      widget.scrollController ??
      (_ownedScrollController ??= ScrollController());
  final Map<int, GlobalKey> _tileKeys = {};
  Timer? _markedDoneSnackBarTimer;

  GlobalKey _keyFor(int id) => _tileKeys.putIfAbsent(id, () => GlobalKey());

  @override
  void didUpdateWidget(_ItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final live = <int>{
      for (final i in widget.activeItems) i.id,
      for (final i in widget.doneItems) i.id,
    };
    _tileKeys.removeWhere((id, _) => !live.contains(id));
  }

  @override
  void dispose() {
    _markedDoneSnackBarTimer?.cancel();
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showDone = widget.doneItems.isNotEmpty;
    final showDoneItems = showDone && !widget.doneCollapsed;
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 4)),
          if (widget.canReorder)
            SliverReorderableList(
              itemCount: widget.activeItems.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
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
            )
          else
            SliverList.builder(
              itemCount: widget.activeItems.length,
              itemBuilder: (context, i) =>
                  _buildTileWithHeader(context, widget.activeItems, i),
            ),
          if (showDone)
            SliverToBoxAdapter(
              child: InkWell(
                onTap: widget.onToggleDoneCollapsed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: const Color(0xFF5FBF8A),
                        size: 18,
                      ),
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
            ),
          if (showDoneItems)
            SliverList.builder(
              itemCount: widget.doneItems.length,
              itemBuilder: (context, i) =>
                  _buildTileWithHeader(context, widget.doneItems, i),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 36)),
        ],
      ),
    );
  }

  Widget _buildTileWithHeader(
    BuildContext context,
    List<ListItem> items,
    int index,
  ) {
    final item = items[index];
    final tile = _buildTile(context, item);
    if (!widget.groupByCategory) return tile;
    // A header leads every category group — before the first item and again
    // whenever the category changes from the row above.
    final startsGroup =
        index == 0 || items[index - 1].categoryId != item.categoryId;
    if (!startsGroup) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryHeader(
          category: item.categoryId != null
              ? widget.controller.categories[item.categoryId]
              : null,
        ),
        tile,
      ],
    );
  }

  Widget _buildTile(BuildContext context, ListItem item) {
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
      key: _keyFor(item.id),
      item: item,
      category: item.categoryId != null
          ? controller.categories[item.categoryId]
          : null,
      houseId: controller.houseId,
      isCardsView: widget.isCards,
      trashMode: controller.isTrashMode,
      archiveMode: controller.isArchiveMode,
      addedByUserId: addedByUserId,
      addedByDisplayName: addedByDisplayName,
      listBadge: listBadge,
      hideCategory: widget.groupByCategory,
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
      onLongPressSelect: controller.canSelectItems && !widget.canReorder
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
    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.moveItem),
        children: [
          for (final list in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                ],
              ),
            ),
        ],
      ),
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
    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.copyItem),
        children: [
          for (final list in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                ],
              ),
            ),
        ],
      ),
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
    final messenger = ScaffoldMessenger.of(context);
    // Drop any prior snackbar instantly so the new one isn't delayed by the
    // ~250ms exit animation `clearSnackBars()` would run.
    messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    // Drive dismissal ourselves: SnackBar's internal timer gets reset
    // whenever the snackbar's MediaQuery dependency rebuilds, and this view
    // triggers a lot of those — toggleItem fires two notifyListeners (the
    // optimistic update + the server-confirmed update), the 30s background
    // refresh fires more, and the appBarSpecHolder post-frame ripples up to
    // home_view's AppBar. Net effect: relying on `duration:` alone leaves
    // the snackbar pinned until the user dismisses it. The explicit timer
    // here closes it 6s after it's shown, regardless of how many rebuilds
    // happen in the meantime.
    _markedDoneSnackBarTimer?.cancel();
    final entry = messenger.showSnackBar(
      SnackBar(
        content: Text(m.checklists.itemMarkedDone),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: m.checklists.undo,
          onPressed: () async {
            try {
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
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(m.checklists.restoreFailed)),
                );
              }
            }
          },
        ),
      ),
    );
    // Start the 6s clock once the snackbar's enter animation has finished,
    // so the user actually sees it for the full 6s rather than 6s minus
    // the ~250ms slide-in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markedDoneSnackBarTimer = Timer(const Duration(seconds: 6), entry.close);
    });
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.checklists.itemForm.deleteFailed)),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m.checklists.itemRemoved),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: m.checklists.undo,
          onPressed: () async {
            try {
              await controller.restoreItem(item);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(m.checklists.restoreFailed)),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _onRestore(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.restoreItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.itemRestored)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.restoreFailed)));
      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.archiveFailed)));
      }
      return;
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m.checklists.itemArchived),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: m.checklists.undo,
          onPressed: () async {
            try {
              await controller.unarchiveItem(item);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(m.checklists.unarchiveFailed)),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _onUnarchive(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    try {
      await controller.unarchiveItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.itemUnarchived)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.unarchiveFailed)));
      }
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }
}

class _TrashBanner extends StatelessWidget {
  final VoidCallback onExit;

  const _TrashBanner({required this.onExit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.checklists.trashTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.checklists.exitTrash),
          ),
        ],
      ),
    );
  }
}

class _ArchiveBanner extends StatelessWidget {
  final VoidCallback onExit;

  const _ArchiveBanner({required this.onExit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.archive_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.checklists.archiveTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.checklists.exitArchive),
          ),
        ],
      ),
    );
  }
}

/// Grouped-list header shown above each category run when sorting by category.
/// Real categories render their icon + name in the category color; the
/// uncategorised group falls back to muted default text and label.
class _CategoryHeader extends StatelessWidget {
  final models.Category? category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category != null
        ? (parseHexColor(category!.color) ?? cs.onSurfaceVariant)
        : cs.onSurfaceVariant;
    final name = category?.name ?? m.checklists.noCategory;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 20, 8),
      child: Row(
        children: [
          Icon(categoryIcon(category?.icon), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          m.checklists.noSearchResults,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NoItemsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const success = Color(0xFF5FBF8A);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          success.withValues(alpha: 0.18),
                          success.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_box_outlined,
                      color: success,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    m.checklists.noItemsTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    m.checklists.noItemsBody,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Icon(
            Icons.keyboard_double_arrow_down,
            color: cs.primary,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _NoListsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoListsEmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.primary.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: cs.primary,
                size: 46,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              m.checklists.noListsTitle,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 9),
            Text(
              m.checklists.noListsBody,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      m.checklists.createFirstList,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio-style indicator used by the sort options in the AppBar overflow.
/// Hollow circle when unselected; filled accent circle with a white check
/// when selected. Reads as a radio but matches the language of the list-item
/// checkbox.
class _RadioIndicator extends StatelessWidget {
  final bool selected;

  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

/// Checkbox-style indicator used by the boolean toggles in the AppBar
/// overflow. Rounded-rect outline when unselected, filled accent rounded
/// rect with a white check when selected — mirrors the list-item checkbox.
class _CheckboxIndicator extends StatelessWidget {
  final bool selected;

  const _CheckboxIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

/// Result type for [_DevLastSeenPickerDialog]. Carrying a wrapper instead of a
/// raw `String?` lets the dialog return "never seen" (null) distinctly from
/// dismissal.
class _DevLastSeenChoice {
  /// `null` means simulate a brand-new user (no version seen yet).
  final String? value;

  const _DevLastSeenChoice(this.value);
}

class _DevLastSeenPickerDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dev = m.onboarding.dev;
    final options = <_DevLastSeenChoice>[
      const _DevLastSeenChoice(null),
      for (final v in kDevOnboardingPickableVersions) _DevLastSeenChoice(v),
    ];
    return SimpleDialog(
      title: Text(dev.pickLastSeenTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            dev.pickLastSeenBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final opt in options)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(opt),
            child: Text(opt.value ?? dev.neverSeen),
          ),
      ],
    );
  }
}

/// Sentinel returned by the category picker to mean "clear the category"
/// (distinct from a null dismissal and from a real positive category id).
const int _kBatchClearCategory = -1;

/// Bottom bar shown while items are multi-selected. Surfaces the four group
/// actions, each enabled per the controller's permission/writability gating,
/// and drives the batch endpoints with a target/category picker + result
/// snackbar (including the skipped count).
class _SelectionActionBar extends StatelessWidget {
  final ChecklistsController controller;

  const _SelectionActionBar({required this.controller});

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
                      icon: Icons.sell_outlined,
                      label: m.checklists.batch.category,
                      enabled: controller.canBatchCategory,
                      onTap: () => _category(context),
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

  Future<void> _move(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final affected = List.of(controller.selectedItems);
    final targetId = await _pickTargetList(
      context,
      title: m.checklists.batch.moveTitle,
    );
    if (targetId == null) return;
    controller.batchMove(targetId);
    _showUndo(
      messenger,
      m.checklists.batch.moved(affected.length),
      () => controller.undoBatchMove(affected),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = controller.selectedCount;
    final targetId = await _pickTargetList(
      context,
      title: m.checklists.batch.copyTitle,
    );
    if (targetId == null) return;
    controller.batchCopy(targetId);
    // Copy is additive and non-destructive — no undo, just a confirmation.
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m.checklists.batch.copied(count))));
  }

  Future<void> _category(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final affected = List.of(controller.selectedItems);
    final choice = await _pickCategory(context);
    if (choice == null) return;
    final categoryId = choice == _kBatchClearCategory ? null : choice;
    controller.batchSetCategory(categoryId);
    _showUndo(
      messenger,
      m.checklists.batch.categorySet(affected.length),
      () => controller.undoBatchSetCategory(affected),
    );
  }

  Future<void> _delete(BuildContext context, {bool permanent = false}) async {
    final messenger = ScaffoldMessenger.of(context);
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
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(m.checklists.batch.deleted(affected.length))),
        );
      return;
    }
    _showUndo(
      messenger,
      m.checklists.batch.deleted(affected.length),
      () => controller.undoBatchDelete(affected),
    );
  }

  Future<void> _archive(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final affected = List.of(controller.selectedItems);
    controller.batchArchive();
    _showUndo(
      messenger,
      m.checklists.batch.archived(affected.length),
      () => controller.undoBatchArchive(affected),
    );
  }

  Future<void> _unarchive(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final affected = List.of(controller.selectedItems);
    controller.batchUnarchive();
    _showUndo(
      messenger,
      m.checklists.batch.unarchived(affected.length),
      () => controller.undoBatchUnarchive(affected),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final affected = List.of(controller.selectedItems);
    controller.batchRestore();
    _showUndo(
      messenger,
      m.checklists.batch.restored(affected.length),
      () => controller.undoBatchRestore(affected),
    );
  }

  /// Shows a confirmation snackbar with an Undo action for a batch operation.
  void _showUndo(
    ScaffoldMessengerState messenger,
    String message,
    VoidCallback onUndo,
  ) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: m.checklists.undo, onPressed: onUndo),
        ),
      );
  }

  /// Target-list picker for move/copy. Excludes the synthetic All-lists entry
  /// and, in a per-list view, the current list (a no-op target).
  Future<int?> _pickTargetList(BuildContext context, {required String title}) {
    final currentId = controller.isMetaMode ? null : controller.currentList?.id;
    final others = controller.lists
        .where((l) => l.id != kAllListsId && l.id != currentId)
        .toList();
    if (others.isEmpty) return Future.value(null);
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          for (final list in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Category picker for set-category. Returns null on dismiss,
  /// [_kBatchClearCategory] for "No category", or a positive category id.
  Future<int?> _pickCategory(BuildContext context) {
    final cats = controller.sortedCategories;
    final cs = Theme.of(context).colorScheme;
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.batch.categoryTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, _kBatchClearCategory),
            child: Row(
              children: [
                const Icon(Icons.block, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(m.checklists.batch.clearCategory)),
              ],
            ),
          ),
          for (final cat in cats)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, cat.id),
              child: Row(
                children: [
                  Icon(
                    categoryIcon(cat.icon),
                    size: 20,
                    color: parseHexColor(cat.color) ?? cs.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cat.name)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
