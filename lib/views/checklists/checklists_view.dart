import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/widgets/auto_refresh.dart';
import 'checklist_item_list.dart';
import 'checklist_item_tile.dart';
import 'checklists_banners.dart';
import 'checklists_body_controller.dart';
import 'checklists_controller.dart';
import 'checklists_empty_states.dart';
import 'checklists_filter_bar.dart';
import 'checklists_selection_bar.dart';
import 'item_compose_bar.dart';
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

  /// Polls the server on the user-configured checklist interval (default 30s)
  /// so the list stays current without a pull-to-refresh. Paused while
  /// backgrounded (a fresh refresh fires on resume); soft views route through a
  /// silent in-place refresh so they don't flash a spinner mid-read. A `null`
  /// interval means auto-refresh is off.
  Timer? _backgroundRefreshTimer;
  Duration? _activeRefreshInterval;

  Duration? get _refreshInterval => AutoRefresh.durationFromSeconds(
    PrefsService.instance.checklistRefreshSeconds,
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
    WidgetsBinding.instance.addObserver(this);
    _activeRefreshInterval = _refreshInterval;
    _startBackgroundRefreshTimer();
    // Restart the timer when the user changes the checklist refresh interval.
    PrefsService.instance.addListener(_onPrefsChanged);
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
    final interval = _refreshInterval;
    if (interval == null) {
      _backgroundRefreshTimer = null;
      return;
    }
    _backgroundRefreshTimer = Timer.periodic(interval, (_) {
      if (_controller.isSoftView) {
        _controller.refreshSoftView();
      } else {
        _controller.refresh();
      }
    });
  }

  void _onPrefsChanged() {
    final interval = _refreshInterval;
    if (interval == _activeRefreshInterval) return;
    _activeRefreshInterval = interval;
    _startBackgroundRefreshTimer();
  }

  void _stopBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Skip the resume refresh when auto-refresh is off — "off" means no
        // automatic server calls, only manual pull-to-refresh.
        if (_refreshInterval != null) _controller.refresh();
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
    PrefsService.instance.removeListener(_onPrefsChanged);
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

class _Body extends StatefulWidget {
  final ValueNotifier<ChecklistsAppBarSpec?>? appBarSpecHolder;
  final ScrollController? scrollController;

  const _Body({this.appBarSpecHolder, this.scrollController});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final ChecklistsBodyController _body;

  @override
  void initState() {
    super.initState();
    _body = ChecklistsBodyController(
      domain: context.read<ChecklistsController>(),
      scrollController: widget.scrollController,
      appBarSpecHolder: widget.appBarSpecHolder,
    );
    _body.attach();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChecklistsBodyController>.value(
      value: _body,
      child: Builder(
        builder: (context) {
          final controller = context.watch<ChecklistsController>();
          final body = context.watch<ChecklistsBodyController>();

          if (controller.isLoading && controller.lists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.lists.isEmpty) {
            return ChecklistsErrorView(
              message: controller.error!,
              onRetry: controller.load,
            );
          }
          if (controller.lists.isEmpty) {
            return ChecklistsNoListsEmptyState(
              onCreate: () => body.openSwitcher(context),
            );
          }

          final list = controller.currentList;
          final isMeta = controller.isMetaMode;
          // The per-list filter only exists in the All-lists view. Outside it,
          // an empty set means it never narrows anything.
          final selectedListIds = isMeta
              ? PrefsService.instance.checklistListFilter
              : const <int>{};
          final filteredItems = body.applyFilters(
            controller.items,
            selectedListIds,
          );
          final activeItems = filteredItems.where((i) => !i.done).toList();
          final doneItems = filteredItems.where((i) => i.done).toList();
          final prefs = context.watch<PrefsService>();
          // Drag-to-reorder is only meaningful under custom sort, and only when
          // the active partition is the full set: reordering writes sort_order
          // across the partition, so a category/search filter (or the
          // cross-list meta view) would persist a partial, wrong order. Gate it
          // to the unfiltered case. It also requires the long-press action to
          // be the built-in multi-select/reorder behavior; any other choice
          // frees long-press for it.
          final baseReorderable =
              prefs.defaultItemLongPressAction == 'multiselect' &&
              !isMeta &&
              !controller.isSoftView &&
              !controller.selectionMode &&
              body.selectedCategoryIds.isEmpty &&
              !body.noCategorySelected &&
              body.selectedStoreIds.isEmpty &&
              !body.noStoreSelected &&
              body.selectedLabelIds.isEmpty &&
              !body.noLabelSelected &&
              !body.priceFilter.isActive &&
              body.query.isEmpty &&
              controller.isCurrentListWritable;
          final canReorder =
              controller.effectiveSortBy == 'custom' && baseReorderable;
          // Within-group drag: category/store sort, gated on the server
          // ordering within groups by sort_order. Constrained to the dragged
          // item's own category block / store column by the per-group
          // reorderables.
          final canReorderGroups =
              baseReorderable &&
              controller.canReorderWithinGroups &&
              (controller.effectiveSortBy == 'category' ||
                  controller.effectiveSortBy == 'store');
          final total = controller.items
              .where((i) => i.deletedAt == null)
              .length;
          final done = controller.items.where((i) => i.done).length;

          final isCards = prefs.checklistView == 'cards';
          final doneCollapsed = prefs.checklistDoneCollapsed;
          final isEmptyList =
              controller.items.isEmpty && !controller.isSoftView;

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
          // The "No category" chip only earns a spot when there's actually an
          // uncategorized item to filter down to.
          final hasUncategorized = controller.items.any(
            (i) => i.deletedAt == null && i.categoryId == null,
          );

          // Store filter mirrors categories, gated on the capability. Only
          // stores with at least one (non-trashed) item on this list are
          // offered.
          final storesEnabled = hasFeature('stores');
          final activeStoreIds = <int>{
            if (storesEnabled)
              for (final i in controller.items)
                if (i.deletedAt == null) ...i.storeIds,
          };
          final filterStores = storesEnabled
              ? controller.sortedStores
                    .where((s) => activeStoreIds.contains(s.id))
                    .toList()
              : const <models.Store>[];
          final hasNoStoreItems =
              storesEnabled &&
              controller.items.any(
                (i) => i.deletedAt == null && i.storeIds.isEmpty,
              );
          // Offer the store filter only when there's something to filter by.
          final showStoreFilter =
              storesEnabled && (filterStores.isNotEmpty || hasNoStoreItems);

          // Label filter mirrors stores, gated on the `labels` capability. Only
          // labels with at least one (non-trashed) item on this list are
          // offered.
          final labelsEnabled = hasFeature('labels');
          final activeLabelIds = <int>{
            if (labelsEnabled)
              for (final i in controller.items)
                if (i.deletedAt == null) ...i.labelIds,
          };
          final filterLabels = labelsEnabled
              ? controller.sortedLabels
                    .where((l) => activeLabelIds.contains(l.id))
                    .toList()
              : const <models.Label>[];
          final hasNoLabelItems =
              labelsEnabled &&
              controller.items.any(
                (i) => i.deletedAt == null && i.labelIds.isEmpty,
              );
          final showLabelFilter =
              labelsEnabled && (filterLabels.isNotEmpty || hasNoLabelItems);

          // Price filter mirrors the store gate (and the web app): shown only
          // when the server supports prices and at least one (non-trashed) item
          // actually carries one.
          final showPriceFilter =
              hasFeature('item-price') &&
              controller.items.any((i) => i.deletedAt == null && i.hasPrice);

          // The per-list filter (All-lists view only) offers every list, even
          // ones with no items in the current view — unlike categories, an
          // empty list is still a meaningful thing to focus on.
          final filterLists = isMeta
              ? controller.sortedLists
                    .where((l) => l.id != kAllListsId)
                    .toList()
              : const <ChecklistList>[];

          // Push the current AppBar contents up to the shared home AppBar slot.
          // Done in a post-frame callback so we don't mutate a listenable
          // during build, which would trigger a rebuild storm.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.appBarSpecHolder?.value = body.buildAppBarSpec(
              context,
              list,
            );
          });

          return LayoutBuilder(
            builder: (context, constraints) {
              // Compose bar is overlaid via a Stack so its expanding trays can
              // grow upward and cover the progress hero + filter row instead of
              // being squeezed by them. The ConstrainedBox ceiling (full
              // viewport) funnels down to the bar's internal Flexible+scroll
              // view, which scrolls only when even that isn't enough (tiny
              // screen + keyboard up).
              return Stack(
                children: [
                  Column(
                    children: [
                      // Live shopping trip in progress — offer a one-tap resume.
                      if (body.shoppingSession != null &&
                          hasFeature('shopping'))
                        body.buildResumeBanner(context),
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
                          child: body.searchOpen
                              ? ChecklistsSearchField(
                                  key: const ValueKey('search-open'),
                                  controller: body.searchCtrl,
                                  onChanged: body.handleSearchChanged,
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
                          // Hides the card for the current list (the All-lists
                          // view persists this locally under id 0). Bring it
                          // back from the list's overflow menu.
                          onDismissed: (_) =>
                              controller.setListHideProgressHero(true),
                          background: const SizedBox.shrink(),
                          child: ProgressHero(
                            total: total,
                            done: done,
                            // Desktop mice can't reliably swipe. Surface a tap
                            // affordance there; the Dismissible above still
                            // works for anyone who can swipe.
                            onDismiss: PlatformInfo.isDesktop
                                ? () => controller.setListHideProgressHero(true)
                                : null,
                          ),
                        ),
                      if (!isEmptyList && !controller.isSoftView)
                        ChecklistsFiltersSection(
                          categories: filterCategories,
                          selectedCategoryIds: body.selectedCategoryIds,
                          onToggleCategory: body.toggleCategory,
                          onClearCategories: body.clearCategories,
                          showNoCategory: hasUncategorized,
                          noCategorySelected: body.noCategorySelected,
                          onToggleNoCategory: body.toggleNoCategory,
                          showListFilter: isMeta,
                          lists: filterLists,
                          selectedListIds: selectedListIds,
                          onToggleList: (id) {
                            final next = {...prefs.checklistListFilter};
                            if (!next.remove(id)) next.add(id);
                            prefs.setChecklistListFilter(next);
                          },
                          onClearLists: () => prefs.setChecklistListFilter({}),
                          showStoreFilter: showStoreFilter,
                          stores: filterStores,
                          selectedStoreIds: body.selectedStoreIds,
                          onToggleStore: body.toggleStore,
                          onClearStores: body.clearStores,
                          showNoStore: hasNoStoreItems,
                          noStoreSelected: body.noStoreSelected,
                          onToggleNoStore: body.toggleNoStore,
                          showLabelFilter: showLabelFilter,
                          labels: filterLabels,
                          selectedLabelIds: body.selectedLabelIds,
                          onToggleLabel: body.toggleLabel,
                          onClearLabels: body.clearLabels,
                          showNoLabel: hasNoLabelItems,
                          noLabelSelected: body.noLabelSelected,
                          onToggleNoLabel: body.toggleNoLabel,
                          showPriceFilter: showPriceFilter,
                          priceFilter: body.priceFilter,
                          onPriceFilterChanged: body.setPriceFilter,
                          view: prefs.checklistView,
                          onViewChanged: (v) => prefs.setChecklistView(v),
                        ),
                      if (controller.isTrashMode)
                        ChecklistsTrashBanner(
                          onExit: () => controller.setTrashMode(false),
                        ),
                      if (controller.isArchiveMode)
                        ChecklistsArchiveBanner(
                          onExit: () => controller.setArchiveMode(false),
                        ),
                      Expanded(
                        // While a fresh list (no cached items yet) is loading,
                        // show a spinner rather than the empty state — the list
                        // isn't empty, it just hasn't arrived. Once items are on
                        // screen, in-place reloads (e.g. a sort change) keep
                        // them visible and overlay a thin refresh bar instead of
                        // flashing empty.
                        child: controller.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : controller.itemsUnavailable
                            // Fetch failed with nothing cached (typically
                            // offline) — show a retry affordance rather than the
                            // empty state, which otherwise reads as "my data is
                            // gone".
                            ? ChecklistsErrorView(
                                message: m.checklists.failedToLoadItems,
                                onRetry: () {
                                  final cur = controller.currentList;
                                  if (cur != null) controller.selectList(cur);
                                },
                              )
                            : isEmptyList
                            ? ChecklistsNoItemsEmptyState()
                            : (filteredItems.isEmpty
                                  ? ChecklistsNoMatchesEmptyState()
                                  : Stack(
                                      children: [
                                        // The room for the resting compose bar
                                        // and the floating shopping FAB is
                                        // reserved as trailing scroll padding
                                        // *inside* the list (not an outer gap),
                                        // so items use the full viewport and are
                                        // never clipped mid-list — the extra
                                        // space only appears once scrolled to
                                        // the bottom.
                                        ChecklistItemList(
                                          controller: controller,
                                          activeItems: activeItems,
                                          doneItems: doneItems,
                                          canReorder: canReorder,
                                          canReorderGroups: canReorderGroups,
                                          isCards: isCards,
                                          doneCollapsed: doneCollapsed,
                                          groupByCategory:
                                              controller.sortBy == 'category',
                                          groupByStore:
                                              controller.sortBy == 'store',
                                          onToggleDoneCollapsed: () =>
                                              prefs.setChecklistDoneCollapsed(
                                                !doneCollapsed,
                                              ),
                                          scrollController:
                                              widget.scrollController,
                                          bottomInset: body.listBottomInset(
                                            list,
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
                  // Scrim — fades in/out with compose-active state, always
                  // present so AnimatedOpacity has something to interpolate.
                  // IgnorePointer prevents the invisible scrim from eating taps
                  // when inactive.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !body.composeActive,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        opacity: body.composeActive ? 1.0 : 0.0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => body.composeKey.currentState
                              ?.dismissKeepingDraft(),
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
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight,
                        ),
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
                            // Heal an orphaned selection (target list was
                            // deleted since last add) by clearing it silently.
                            if (meta &&
                                body.composeTargetListId != null &&
                                !realLists!.any(
                                  (l) => l.id == body.composeTargetListId,
                                )) {
                              body.composeTargetListId = null;
                            }
                            // Existing items on the target list, surfaced as
                            // fuzzy "reuse instead of duplicate" suggestions
                            // while typing. Gated on the reuse capability and
                            // the check permission — reuse un-checks a done
                            // item.
                            final reuseTargetId = meta
                                ? body.composeTargetListId
                                : list.id;
                            final reuseActive =
                                hasFeature('reuse-existing-items') &&
                                controller.permissions.canCheckItems &&
                                reuseTargetId != null;
                            final reuseCandidates = reuseActive
                                ? [
                                    for (final i in controller.items)
                                      if (i.deletedAt == null &&
                                          i.listId == reuseTargetId)
                                        i,
                                  ]
                                : const <ListItem>[];
                            // Archived items join the reuse pool only when the
                            // user opts in and the server advertises the
                            // capability; the controller fetches them lazily and
                            // keeps them live.
                            final suggestArchived =
                                reuseActive &&
                                hasFeature('pref-suggest-archived-items') &&
                                prefs.suggestArchivedItems;
                            final archivedReuseCandidates = suggestArchived
                                ? controller.archivedReuseCandidates(
                                    reuseTargetId,
                                  )
                                : const <ListItem>[];
                            return ItemComposeBar(
                              key: body.composeKey,
                              listName: list.name,
                              houseId: controller.houseId,
                              listId: meta ? null : list.id,
                              deleteOnDoneDefault: meta
                                  ? false
                                  : list.deleteOnDoneDefault,
                              categories: controller.categoriesForList(
                                meta ? body.composeTargetListId : list.id,
                              ),
                              stores: hasFeature('stores')
                                  ? controller.sortedStores
                                  : const [],
                              labels: hasFeature('labels')
                                  ? controller.labelsForList(
                                      meta ? body.composeTargetListId : list.id,
                                    )
                                  : const [],
                              customFieldDefs: controller.customFieldDefs,
                              priceEnabled: hasFeature('item-price'),
                              perStorePriceEnabled: hasFeature(
                                kItemPricePerStoreFeature,
                              ),
                              lastCurrency: controller.lastCurrency,
                              initiallyFocused: false,
                              targetLists: realLists,
                              selectedTargetListId: meta
                                  ? body.composeTargetListId
                                  : null,
                              onTargetListChanged: body.setComposeTargetListId,
                              reuseCandidates: reuseCandidates,
                              buildReuseSuggestion: (item, onTap) =>
                                  ChecklistItemTile.suggestion(
                                    item: item,
                                    category: item.categoryId != null
                                        ? controller.categories[item.categoryId]
                                        : null,
                                    stores: controller.storesFor(item),
                                    labels: controller.labelsFor(item),
                                    houseId: controller.houseId,
                                    onTap: onTap,
                                    archived: item.archivedAt != null,
                                  ),
                              onReuseExisting: (item) =>
                                  body.reuseFromSuggestion(context, item),
                              archivedReuseCandidates: archivedReuseCandidates,
                              onArchivedSearchStarted: suggestArchived
                                  ? controller.ensureArchivedReuseLoaded
                                  : null,
                              onActiveChanged: body.setComposeActive,
                              onRequestCreateCategory:
                                  controller.permissions.canEditLists
                                  ? () => body.createCategory(
                                      context,
                                      defaultListId: meta
                                          ? body.composeTargetListId
                                          : list.id,
                                    )
                                  : null,
                              onRequestCreateStore:
                                  hasFeature('stores') &&
                                      controller.permissions.canEditLists
                                  ? () => body.createStore(context)
                                  : null,
                              onRequestCreateLabel:
                                  hasFeature('labels') &&
                                      controller.permissions.canEditLists
                                  ? () => body.createLabel(
                                      context,
                                      defaultListId: meta
                                          ? body.composeTargetListId
                                          : list.id,
                                    )
                                  : null,
                              onSubmit: (s) async {
                                final targetListId = meta
                                    ? body.composeTargetListId
                                    : list.id;
                                if (targetListId == null) return false;
                                return body.addItemHonoringReuse(
                                  context,
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
                      child: SelectionActionBar(controller: controller),
                    ),
                  // Start / resume shopping. Hidden in soft (trash/archive) and
                  // selection modes, and while the add-item sheet is active (it
                  // would float over the sheet); lifted above the resting
                  // compose bar. When the FAB is turned off it moves into the
                  // overflow menu.
                  if (hasFeature('shopping') &&
                      prefs.startShoppingFabEnabled &&
                      !controller.isSoftView &&
                      !controller.selectionMode &&
                      !body.composeActive)
                    PositionedDirectional(
                      end: 16,
                      bottom: (list != null && controller.canAddItemsHere)
                          ? 88
                          : 16,
                      child: FloatingActionButton.extended(
                        heroTag: 'shopping-fab',
                        onPressed: () => body.openShopping(context),
                        icon: Icon(
                          body.shoppingSession != null
                              ? Icons.play_arrow
                              : Icons.shopping_cart,
                        ),
                        label: Text(
                          body.shoppingSession != null
                              ? m.shopping.resumeShopping
                              : m.shopping.startShopping,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
