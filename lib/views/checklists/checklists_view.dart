import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/onboarding_view.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/categories/categories_view.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';
import 'package:pantry/views/shopping/shopping_session_view.dart';
import 'package:pantry/views/shopping/shopping_start_view.dart';
import 'package:pantry/views/stores/stores_view.dart';
import 'package:pantry/widgets/auto_refresh.dart';
import 'package:pantry/widgets/create_category_dialog.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
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

class _BodyState extends State<_Body> with WidgetsBindingObserver {
  bool _searchOpen = false;
  bool _composeActive = false;
  final _searchCtrl = TextEditingController();
  final _composeKey = GlobalKey<ItemComposeBarState>();
  // Anchors the desktop switcher popup under the AppBar title row so it
  // reads as a dropdown rather than a centered modal.
  final _switcherAnchorKey = GlobalKey();
  final Set<int> _selectedCategoryIds = {};
  bool _noCategorySelected = false;
  final Set<int> _selectedStoreIds = {};
  bool _noStoreSelected = false;
  PriceFilter _priceFilter = PriceFilter.empty;

  /// In All-lists mode, the most recently chosen target list. Pre-selected on
  /// the next add so the user can rapidly file several items into the same
  /// list. Kept on the body state (not in the controller) so it survives
  /// re-renders without leaking into other per-list views.
  int? _composeTargetListId;

  /// The caller's live shopping session (any house), polled to drive the
  /// resume banner and the Start/Resume FAB. Null when there's no live trip or
  /// the server lacks the `shopping` capability.
  ShoppingSession? _shoppingSession;

  String get _query => _searchCtrl.text.trim().toLowerCase();

  /// Scroll offset captured the moment a text search begins. Filtering shrinks
  /// the list (and thus `maxScrollExtent`), which clamps the offset near the
  /// top; restoring this on clear/close returns the user to where they were
  /// instead of stranding them at the top.
  double? _preSearchOffset;

  /// React to search text changes: capture the pre-filter scroll anchor on the
  /// first keystroke, or restore it once the query is cleared back to empty.
  void _handleSearchChanged() {
    if (_searchCtrl.text.trim().isEmpty) {
      _restorePreSearchOffset();
    } else if (_preSearchOffset == null) {
      // First keystroke — the list hasn't rebuilt yet, so the controller still
      // reports the full-list offset. Capture it before it gets clamped.
      final ctrl = widget.scrollController;
      if (ctrl != null && ctrl.hasClients) _preSearchOffset = ctrl.offset;
    }
    setState(() {});
  }

  /// Jump back to the captured pre-search offset once the full list has been
  /// restored. Deferred to a post-frame callback so `maxScrollExtent` reflects
  /// the unfiltered list; clamped in case items were removed while filtered.
  void _restorePreSearchOffset() {
    final target = _preSearchOffset;
    _preSearchOffset = null;
    final ctrl = widget.scrollController;
    if (target == null || ctrl == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ctrl.hasClients) return;
      final max = ctrl.position.maxScrollExtent;
      ctrl.jumpTo(target > max ? max : target);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshShoppingSession(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshShoppingSession();
  }

  /// Re-fetch the caller's live session so the banner / FAB stay current.
  /// Cheap and side-effect-free (`GET /current`); gated on the capability.
  Future<void> _refreshShoppingSession() async {
    if (!hasFeature('shopping')) return;
    try {
      final session = await ShoppingService.instance.getCurrentSession();
      if (!mounted) return;
      setState(
        () => _shoppingSession = (session?.live ?? false) ? session : null,
      );
    } catch (_) {
      /* keep the last-known state */
    }
  }

  /// Open the shopping flow: resume the live session, or run the start screen
  /// (which returns a freshly created session to navigate into). Refreshes the
  /// banner / FAB on return.
  Future<void> _openShopping(ChecklistsController controller) async {
    final existing = _shoppingSession;
    if (existing != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShoppingSessionView(session: existing),
        ),
      );
    } else {
      final currentId = controller.currentList?.id;
      final created = await Navigator.of(context).push<ShoppingSession?>(
        MaterialPageRoute(
          builder: (_) => ShoppingStartView(
            houseId: controller.houseId,
            preselectListId: (currentId != null && currentId > 0)
                ? currentId
                : null,
          ),
        ),
      );
      if (created != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingSessionView(session: created),
          ),
        );
      }
    }
    await _refreshShoppingSession();
  }

  /// Bottom inset reserved under the item list so neither the resting compose
  /// bar nor the floating Start/Resume-shopping FAB overlaps the last row. Takes
  /// the larger of the two reservations that apply.
  double _listBottomInset(
    ChecklistsController controller,
    ChecklistList? list,
  ) {
    if (controller.isSoftView) return 36;
    // Clears the resting compose bar plus a little breathing room.
    const composeReserve = 112.0;
    final fabShown = hasFeature('shopping') && !controller.selectionMode;
    if (!fabShown) return composeReserve;
    // The FAB's own bottom offset (88 above a compose bar, else 16) plus the
    // extended FAB's height and a small gap.
    final fabBottom = (list != null && controller.canAddItemsHere)
        ? 88.0
        : 16.0;
    final fabReserve = fabBottom + 56 + 8;
    return fabReserve > composeReserve ? fabReserve : composeReserve;
  }

  Future<void> _openShoppingHistory(ChecklistsController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingHistoryView(houseId: controller.houseId),
      ),
    );
    await _refreshShoppingSession();
  }

  /// The "you're shopping at {store} · [Resume]" banner shown atop the list
  /// while a trip is live. Resolves the active store's name from the
  /// controller's already-loaded store map.
  Widget _buildResumeBanner(ChecklistsController controller) {
    final session = _shoppingSession!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activeId = session.activeStoreId;
    final store = activeId != null ? controller.stores[activeId] : null;
    final ordered = session.orderedStoreIds;
    final idx = activeId != null ? ordered.indexOf(activeId) : -1;
    final label = store != null
        ? m.shopping.bannerShoppingAt(store.name)
        : m.shopping.bannerShoppingNow;

    return Material(
      color: cs.primaryContainer,
      child: InkWell(
        onTap: () => _openShopping(controller),
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
                onPressed: () => _openShopping(controller),
                child: Text(m.shopping.resume),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ListItem> _applyFilters(List<ListItem> items, Set<int> selectedListIds) {
    final categoryFilterActive =
        _selectedCategoryIds.isNotEmpty || _noCategorySelected;
    final storeFilterActive = _selectedStoreIds.isNotEmpty || _noStoreSelected;
    final priceFilterActive = _priceFilter.isActive;
    if (!categoryFilterActive &&
        !storeFilterActive &&
        !priceFilterActive &&
        selectedListIds.isEmpty &&
        _query.isEmpty) {
      return items;
    }
    return items.where((item) {
      if (categoryFilterActive) {
        final matchesId = _selectedCategoryIds.contains(item.categoryId);
        final matchesNone = _noCategorySelected && item.categoryId == null;
        if (!matchesId && !matchesNone) return false;
      }
      if (storeFilterActive) {
        final matchesId = item.storeIds.any(_selectedStoreIds.contains);
        final matchesNone = _noStoreSelected && item.storeIds.isEmpty;
        if (!matchesId && !matchesNone) return false;
      }
      if (priceFilterActive && !matchesPriceFilter(item, _priceFilter)) {
        return false;
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
    final prefs = context.watch<PrefsService>();
    // Drag-to-reorder is only meaningful under custom sort, and only when the
    // active partition is the full set: reordering writes sort_order across the
    // partition, so a category/search filter (or the cross-list meta view)
    // would persist a partial, wrong order. Gate it to the unfiltered case.
    // It also requires the long-press action to be the built-in
    // multi-select/reorder behavior; any other choice frees long-press for it.
    final baseReorderable =
        prefs.defaultItemLongPressAction == 'multiselect' &&
        !isMeta &&
        !controller.isSoftView &&
        !controller.selectionMode &&
        _selectedCategoryIds.isEmpty &&
        !_noCategorySelected &&
        _selectedStoreIds.isEmpty &&
        !_noStoreSelected &&
        !_priceFilter.isActive &&
        _query.isEmpty &&
        controller.isCurrentListWritable;
    final canReorder =
        controller.effectiveSortBy == 'custom' && baseReorderable;
    // Within-group drag: category/store sort, gated on the server ordering
    // within groups by sort_order. Constrained to the dragged item's own
    // category block / store column by the per-group reorderables.
    final canReorderGroups =
        baseReorderable &&
        controller.canReorderWithinGroups &&
        (controller.effectiveSortBy == 'category' ||
            controller.effectiveSortBy == 'store');
    final total = controller.items.where((i) => i.deletedAt == null).length;
    final done = controller.items.where((i) => i.done).length;

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
    // The "No category" chip only earns a spot when there's actually an
    // uncategorized item to filter down to.
    final hasUncategorized = controller.items.any(
      (i) => i.deletedAt == null && i.categoryId == null,
    );

    // Store filter mirrors categories, gated on the capability. Only stores
    // with at least one (non-trashed) item on this list are offered.
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
        controller.items.any((i) => i.deletedAt == null && i.storeIds.isEmpty);
    // Offer the store filter only when there's something to filter by.
    final showStoreFilter =
        storesEnabled && (filterStores.isNotEmpty || hasNoStoreItems);

    // Price filter mirrors the store gate (and the web app): shown only when
    // the server supports prices and at least one (non-trashed) item actually
    // carries one.
    final showPriceFilter =
        hasFeature('item-price') &&
        controller.items.any((i) => i.deletedAt == null && i.hasPrice);

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
        // Compose bar is overlaid via a Stack so its expanding trays can grow
        // upward and cover the progress hero + filter row instead of being
        // squeezed by them. The ConstrainedBox ceiling (full viewport) funnels
        // down to the bar's internal Flexible+scroll view, which scrolls only
        // when even that isn't enough (tiny screen + keyboard up).
        return Stack(
          children: [
            Column(
              children: [
                // Live shopping trip in progress — offer a one-tap resume.
                if (_shoppingSession != null && hasFeature('shopping'))
                  _buildResumeBanner(controller),
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
                            onChanged: _handleSearchChanged,
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
                    onClearCategories: () => setState(() {
                      _selectedCategoryIds.clear();
                      _noCategorySelected = false;
                    }),
                    showNoCategory: hasUncategorized,
                    noCategorySelected: _noCategorySelected,
                    onToggleNoCategory: () => setState(
                      () => _noCategorySelected = !_noCategorySelected,
                    ),
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
                    selectedStoreIds: _selectedStoreIds,
                    onToggleStore: (id) {
                      setState(() {
                        if (!_selectedStoreIds.remove(id)) {
                          _selectedStoreIds.add(id);
                        }
                      });
                    },
                    onClearStores: () => setState(() {
                      _selectedStoreIds.clear();
                      _noStoreSelected = false;
                    }),
                    showNoStore: hasNoStoreItems,
                    noStoreSelected: _noStoreSelected,
                    onToggleNoStore: () =>
                        setState(() => _noStoreSelected = !_noStoreSelected),
                    showPriceFilter: showPriceFilter,
                    priceFilter: _priceFilter,
                    onPriceFilterChanged: (f) =>
                        setState(() => _priceFilter = f),
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
                      // which otherwise reads as "my data is gone".
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
                                  // The room for the resting compose bar and the
                                  // floating shopping FAB is reserved as trailing
                                  // scroll padding *inside* the list (not an outer
                                  // gap), so items use the full viewport and are
                                  // never clipped mid-list — the extra space only
                                  // appears once scrolled to the bottom.
                                  _ItemList(
                                    controller: controller,
                                    activeItems: activeItems,
                                    doneItems: doneItems,
                                    canReorder: canReorder,
                                    canReorderGroups: canReorderGroups,
                                    isCards: isCards,
                                    doneCollapsed: doneCollapsed,
                                    groupByCategory:
                                        controller.sortBy == 'category',
                                    groupByStore: controller.sortBy == 'store',
                                    onToggleDoneCollapsed: () =>
                                        prefs.setChecklistDoneCollapsed(
                                          !doneCollapsed,
                                        ),
                                    scrollController: widget.scrollController,
                                    bottomInset: _listBottomInset(
                                      controller,
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
                      // Existing items on the target list, surfaced as fuzzy
                      // "reuse instead of duplicate" suggestions while typing.
                      // Gated on the reuse capability and the
                      // check permission — reuse un-checks a done item.
                      final reuseTargetId = meta
                          ? _composeTargetListId
                          : list.id;
                      final reuseCandidates =
                          hasFeature('reuse-existing-items') &&
                              controller.permissions.canCheckItems &&
                              reuseTargetId != null
                          ? [
                              for (final i in controller.items)
                                if (i.deletedAt == null &&
                                    i.listId == reuseTargetId)
                                  i,
                            ]
                          : const <ListItem>[];
                      return ItemComposeBar(
                        key: _composeKey,
                        listName: list.name,
                        deleteOnDoneDefault: meta
                            ? false
                            : list.deleteOnDoneDefault,
                        categories: controller.categoriesForList(
                          meta ? _composeTargetListId : list.id,
                        ),
                        stores: hasFeature('stores')
                            ? controller.sortedStores
                            : const [],
                        priceEnabled: hasFeature('item-price'),
                        perStorePriceEnabled: hasFeature(
                          kItemPricePerStoreFeature,
                        ),
                        lastCurrency: controller.lastCurrency,
                        initiallyFocused: false,
                        targetLists: realLists,
                        selectedTargetListId: meta
                            ? _composeTargetListId
                            : null,
                        onTargetListChanged: (id) {
                          setState(() => _composeTargetListId = id);
                        },
                        reuseCandidates: reuseCandidates,
                        buildReuseSuggestion: (item, onTap) =>
                            ChecklistItemTile.suggestion(
                              item: item,
                              category: item.categoryId != null
                                  ? controller.categories[item.categoryId]
                                  : null,
                              stores: controller.storesFor(item),
                              houseId: controller.houseId,
                              onTap: onTap,
                            ),
                        onReuseExisting: (item) =>
                            _reuseFromSuggestion(context, controller, item),
                        onActiveChanged: (active) {
                          if (active != _composeActive) {
                            setState(() => _composeActive = active);
                          }
                        },
                        onRequestCreateCategory:
                            controller.permissions.canEditLists
                            ? () => _createCategory(
                                context,
                                controller,
                                defaultListId: meta
                                    ? _composeTargetListId
                                    : list.id,
                              )
                            : null,
                        onRequestCreateStore:
                            hasFeature('stores') &&
                                controller.permissions.canEditLists
                            ? () => _createStore(context, controller)
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
            // Start / resume shopping. Hidden in soft (trash/archive) and
            // selection modes, and while the add-item sheet is active (it would
            // float over the sheet); lifted above the resting compose bar.
            // When the FAB is turned off it moves into the overflow menu.
            if (hasFeature('shopping') &&
                prefs.startShoppingFabEnabled &&
                !controller.isSoftView &&
                !controller.selectionMode &&
                !_composeActive)
              PositionedDirectional(
                end: 16,
                bottom: (list != null && controller.canAddItemsHere) ? 88 : 16,
                child: FloatingActionButton.extended(
                  heroTag: 'shopping-fab',
                  onPressed: () => _openShopping(controller),
                  icon: Icon(
                    _shoppingSession != null
                        ? Icons.play_arrow
                        : Icons.shopping_cart,
                  ),
                  label: Text(
                    _shoppingSession != null
                        ? m.shopping.resumeShopping
                        : m.shopping.startShopping,
                  ),
                ),
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

  /// Handles a tap on a live reuse suggestion: confirms the user
  /// wants the tapped item instead of adding a new one, then reuses it —
  /// un-checking it if it was already done. Returns true when reused so the
  /// compose bar clears its input.
  Future<bool> _reuseFromSuggestion(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.reuse.dialogTitle),
        content: Text(m.checklists.reuse.dialogBody(item.name)),
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
    await controller.reuseItem(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.checklists.reuse.reusedSnack(item.name))),
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
          storeIds: s.storeIds.isEmpty ? null : s.storeIds,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
          barcode: s.barcode,
          prices: s.prices,
        );
      } else {
        created = await controller.addItem(
          name: s.name,
          description: s.description,
          quantity: s.quantity,
          categoryId: s.categoryId,
          storeIds: s.storeIds.isEmpty ? null : s.storeIds,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
          barcode: s.barcode,
          prices: s.prices,
        );
      }
      // Remember the chosen currency when the new item actually has a price:
      // the store-less price's currency, else the first per-store price's.
      final prices = s.prices;
      if (prices != null && prices.isNotEmpty) {
        final currency = (storelessPrice(prices) ?? prices.first).priceCurrency;
        if (currency != null) await controller.setLastCurrency(currency);
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
        categories: controller.categoriesForList(targetListId),
        reusePref: prefs.reuseExistingItems,
        reuseFeatureAvailable: hasFeature('reuse-existing-items'),
        onRequestCreateCategory: () =>
            _createCategory(context, controller, defaultListId: targetListId),
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
                _noCategorySelected = false;
                _selectedStoreIds.clear();
                _noStoreSelected = false;
                // Clearing the controller doesn't fire onChanged, so return the
                // list to its pre-search position here.
                _restorePreSearchOffset();
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
          if (controller.permissions.canEditLists && hasFeature('stores'))
            IconButton(
              icon: const Icon(Icons.storefront_outlined),
              tooltip: m.stores.manageTitle,
              onPressed: () => _openManageStores(context, controller),
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
        // Desktop shows the overflow as an anchored popup menu; mobile keeps
        // it in a bottom sheet, which reads and scrolls better on touch.
        if (PlatformInfo.isDesktop)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onSelected: (v) => _onOverflow(context, controller, v),
            itemBuilder: (_) => _overflowMenuItems(
              _overflowItems(controller, prefs, isPinned: isPinned),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onPressed: () => _showOverflowSheet(
              context,
              controller,
              prefs,
              isPinned: isPinned,
            ),
          ),
      ],
    );
  }

  /// Renders the shared overflow [entries] as anchored popup-menu rows for the
  /// desktop toolbar. The bottom-sheet variant renders the same entries as
  /// [ListTile]s in [_showOverflowSheet].
  List<PopupMenuEntry<String>> _overflowMenuItems(
    List<_OverflowEntry> entries,
  ) {
    return [
      for (final entry in entries)
        switch (entry) {
          _OverflowDivider() => const PopupMenuDivider(),
          _OverflowAction(:final value, :final icon, :final label) => _menuRow(
            value: value,
            leading: Icon(icon, size: 20),
            label: label,
          ),
          _OverflowCheckboxAction(:final value, :final label, :final checked) =>
            _menuRow(
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

  /// Sort radio rows lifted out of `_overflowItems` so the desktop toolbar's
  /// Sort menu can show only the sort choices, not the rest of the overflow.
  ///
  /// In the meta (All-lists) view, "custom" is suppressed: the underlying
  /// sort order is per-list, so there's no coherent custom order across
  /// lists. The effective sort falls back to "newest".
  List<PopupMenuEntry<String>> _sortMenuItems(ChecklistsController controller) {
    final effective = controller.effectiveSortBy;
    return [
      for (final o in _sortOptions(showCustom: !controller.isMetaMode))
        _radioRow(
          value: 'sort_${o.key}',
          label: o.label,
          selected: effective == o.key,
        ),
    ];
  }

  /// The sort choices, in display order. `custom` is suppressed in the meta
  /// (All-lists) view — there's no coherent custom order across lists, so the
  /// effective sort falls back to "newest".
  List<({String key, String label})> _sortOptions({required bool showCustom}) {
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
  String _sortLabel(String effective) {
    for (final o in _sortOptions(showCustom: true)) {
      if (o.key == effective) return o.label;
    }
    return m.checklists.sort.newestFirst;
  }

  List<_OverflowEntry> _overflowItems(
    ChecklistsController controller,
    PrefsService prefs, {
    required bool isPinned,
  }) {
    if (controller.isTrashMode) {
      return _normalizeOverflow([
        _OverflowAction(
          value: 'exit_trash',
          icon: Icons.arrow_back,
          label: m.checklists.exitTrash,
        ),
        // Bulk restore / permanent-delete need a selection; surface the entry
        // point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
          _OverflowAction(
            value: 'select_items',
            icon: Icons.checklist,
            label: m.checklists.selectItems,
          ),
        _OverflowAction(
          value: 'empty_trash',
          icon: Icons.delete_forever,
          label: m.checklists.emptyTrash,
        ),
      ]);
    }
    // Archive has no "empty" action — archived items are kept indefinitely.
    if (controller.isArchiveMode) {
      return _normalizeOverflow([
        _OverflowAction(
          value: 'exit_archive',
          icon: Icons.arrow_back,
          label: m.checklists.exitArchive,
        ),
        // Bulk unarchive / permanent-delete need a selection; surface the
        // entry point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
          _OverflowAction(
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
    final isMeta = controller.isMetaMode;
    final effective = controller.effectiveSortBy;
    return _normalizeOverflow([
      if (controller.canSelectItems && controller.items.isNotEmpty) ...[
        _OverflowAction(
          value: 'select_items',
          icon: Icons.checklist,
          label: m.checklists.selectItems,
        ),
        const _OverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        _OverflowAction(
          value: 'sort',
          icon: Icons.sort,
          label: '${m.checklists.sortTooltip}: ${_sortLabel(effective)}',
        ),
        const _OverflowDivider(),
        if (controller.currentList != null && !isMeta)
          _OverflowAction(
            value: 'toggle_pin',
            icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: isPinned ? m.checklists.unpinList : m.checklists.pinList,
          ),
      ],
      if (hasFeature('item-authors'))
        _OverflowCheckboxAction(
          value: 'toggle_added_by',
          label: m.checklists.showAddedBy,
          checked: controller.showAddedBy,
        ),
      if (controller.currentList != null)
        _OverflowCheckboxAction(
          value: 'toggle_progress_hero',
          label: m.checklists.showProgressHero,
          checked: !(controller.currentList!.hideProgressHero),
        ),
      // "Reset custom order" re-seeds sort_order from a chosen basis and leaves
      // the list hand-reorderable. Per-list only (no cross-list custom order in
      // meta) and needs edit permission.
      if (controller.currentList != null &&
          !isMeta &&
          controller.permissions.canEditLists) ...[
        const _OverflowDivider(),
        _OverflowAction(
          value: 'reset_order',
          icon: Icons.sort_by_alpha,
          label: m.checklists.resetOrder.menuLabel,
        ),
      ],
      // Markdown import/export are per-list only — not offered in the meta
      // "All lists" view, which has no single target.
      if (controller.currentList != null && !isMeta) ...[
        const _OverflowDivider(),
        _OverflowAction(
          value: 'export_markdown',
          icon: Icons.file_download_outlined,
          label: m.checklists.markdown.exportTitle,
        ),
        if (controller.canAddItemsHere)
          _OverflowAction(
            value: 'import_markdown',
            icon: Icons.file_upload_outlined,
            label: m.checklists.markdown.importTitle,
          ),
      ],
      if (hasFeature('shopping')) ...[
        const _OverflowDivider(),
        // When the FAB is turned off, its action lives here, above history.
        if (!prefs.startShoppingFabEnabled)
          _OverflowAction(
            value: 'start_shopping',
            icon: _shoppingSession != null
                ? Icons.play_arrow
                : Icons.shopping_cart,
            label: _shoppingSession != null
                ? m.shopping.resumeShopping
                : m.shopping.startShopping,
          ),
        _OverflowAction(
          value: 'shopping_history',
          icon: Icons.history,
          label: m.shopping.shoppingHistory,
        ),
        const _OverflowDivider(),
      ],
      if (!PlatformInfo.isDesktop) ...[
        if (controller.permissions.canEditLists)
          _OverflowAction(
            value: 'manage_categories',
            icon: Icons.sell_outlined,
            label: m.categories.manageTitle,
          ),
        if (controller.permissions.canEditLists && hasFeature('stores'))
          _OverflowAction(
            value: 'manage_stores',
            icon: Icons.storefront_outlined,
            label: m.stores.manageTitle,
          ),
        // Mobile has reliable pull-to-refresh, so it doesn't need a menu row.
        // Web (the other non-desktop host here) doesn't, so keep it there.
        if (PlatformInfo.isWeb)
          _OverflowAction(
            value: 'refresh',
            icon: Icons.refresh,
            label: m.common.refresh,
          ),
        if (!isMeta &&
            controller.isCurrentListWritable &&
            controller.permissions.canDeleteItems &&
            (supportsFeature('soft-delete') || hasFeature('item-trash'))) ...[
          const _OverflowDivider(),
          _OverflowAction(
            value: 'view_trash',
            icon: Icons.delete_outline,
            label: m.checklists.viewTrash,
          ),
        ],
        if (!isMeta &&
            controller.isCurrentListWritable &&
            controller.permissions.canEditLists &&
            hasFeature('item-archive'))
          _OverflowAction(
            value: 'view_archive',
            icon: Icons.archive_outlined,
            label: m.checklists.viewArchive,
          ),
      ],
      if (kDebugMode) ...[
        const _OverflowDivider(),
        _OverflowAction(
          value: 'dev_show_onboarding',
          icon: Icons.bug_report_outlined,
          label: m.onboarding.dev.showOnboarding,
        ),
        _OverflowCheckboxAction(
          value: 'dev_force_all_features',
          label: m.onboarding.dev.forceAllFeatures,
          checked: prefs.devForceAllFeatures,
        ),
        _OverflowAction(
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
  List<_OverflowEntry> _normalizeOverflow(List<_OverflowEntry> entries) {
    final out = <_OverflowEntry>[];
    for (final entry in entries) {
      if (entry is _OverflowDivider &&
          (out.isEmpty || out.last is _OverflowDivider)) {
        continue;
      }
      out.add(entry);
    }
    while (out.isNotEmpty && out.last is _OverflowDivider) {
      out.removeLast();
    }
    return out;
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

  /// The AppBar overflow lives in a bottom sheet rather than a popup menu: it
  /// carries enough entries (view toggles, per-list actions, shopping, dev
  /// tools) that a sheet reads and scrolls better than a tall anchored menu.
  Future<void> _showOverflowSheet(
    BuildContext context,
    ChecklistsController controller,
    PrefsService prefs, {
    required bool isPinned,
  }) async {
    final entries = _overflowItems(controller, prefs, isPinned: isPinned);
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
              (h, e) => h + (e is _OverflowDivider ? 1.0 : rowHeight),
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
                    _OverflowDivider() => const Divider(height: 1),
                    _OverflowAction(:final value, :final icon, :final label) =>
                      ListTile(
                        leading: Icon(icon),
                        title: Text(label),
                        onTap: () => Navigator.of(sheetContext).pop(value),
                      ),
                    _OverflowCheckboxAction(
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
      await _onOverflow(context, controller, selected);
    }
  }

  Future<void> _onOverflow(
    BuildContext context,
    ChecklistsController controller,
    String value,
  ) async {
    final prefs = PrefsService.instance;
    switch (value) {
      case 'select_items':
        controller.enterSelection();
      case 'sort':
        await _showSortDialog(context, controller);
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
      case 'sort_store':
        await controller.setSortBy('store');
      case 'sort_custom':
        await controller.setSortBy('custom');
      case 'reset_order':
        await _showResetOrderDialog(context, controller);
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
      case 'manage_stores':
        await _openManageStores(context, controller);
      case 'start_shopping':
        await _openShopping(controller);
      case 'shopping_history':
        await _openShoppingHistory(controller);
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

  /// Presents the sort choices in a dialog — the mobile overflow menu is too
  /// long to inline all of them, so it shows a single "Sort: current" row
  /// that opens this dialog. Applies the choice immediately on selection.
  Future<void> _showSortDialog(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final effective = controller.effectiveSortBy;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.sortTooltip),
        children: [
          for (final o in _sortOptions(showCustom: !controller.isMetaMode))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.key),
              child: Row(
                children: [
                  _RadioIndicator(selected: effective == o.key),
                  const SizedBox(width: 14),
                  Expanded(child: Text(o.label)),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked != null) {
      await controller.setSortBy(picked);
    }
  }

  /// Pick a basis (Date added / Name A–Z / Name Z–A), confirm the destructive
  /// overwrite, then re-seed the custom order.
  Future<void> _showResetOrderDialog(
    BuildContext context,
    ChecklistsController controller,
  ) async {
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
    await controller.resetOrder(basis);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.resetOrder.success)));
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
    ChecklistsController controller, {
    int? defaultListId,
  }) async {
    final created = await showDialog<models.Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(
        houseId: controller.houseId,
        defaultListId: defaultListId,
      ),
    );
    if (created != null) {
      await controller.onCategoriesChanged();
    }
    return created;
  }

  Future<void> _openManageStores(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoresView(houseId: controller.houseId),
      ),
    );
    await controller.onStoresChanged();
  }

  /// Opens the create-store dialog inline from the compose bar's store tray. On
  /// success, refreshes the controller's store list (so the new option shows up
  /// in the tray) and returns the new Store so compose bar can auto-select it.
  Future<models.Store?> _createStore(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final created = await showDialog<models.Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: controller.houseId),
    );
    if (created != null) {
      await controller.onStoresChanged();
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

  /// Whether the "No category" chip (items with no category) is offered.
  final bool showNoCategory;
  final bool noCategorySelected;
  final VoidCallback onToggleNoCategory;

  /// All-lists view only — when false, no list filter is shown at all.
  final bool showListFilter;
  final List<ChecklistList> lists;
  final Set<int> selectedListIds;
  final ValueChanged<int> onToggleList;
  final VoidCallback onClearLists;

  /// Store filter — gated on the `stores` capability and only shown when at
  /// least one item on the list carries (or lacks) a store.
  final bool showStoreFilter;
  final List<models.Store> stores;
  final Set<int> selectedStoreIds;
  final ValueChanged<int> onToggleStore;
  final VoidCallback onClearStores;
  final bool showNoStore;
  final bool noStoreSelected;
  final VoidCallback onToggleNoStore;

  /// Price filter — gated on the `item-price` capability and only shown when at
  /// least one item on the list carries a price.
  final bool showPriceFilter;
  final PriceFilter priceFilter;
  final ValueChanged<PriceFilter> onPriceFilterChanged;

  final String view;
  final ValueChanged<String> onViewChanged;

  const _FiltersSection({
    required this.categories,
    required this.selectedCategoryIds,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.showNoCategory,
    required this.noCategorySelected,
    required this.onToggleNoCategory,
    required this.showListFilter,
    required this.lists,
    required this.selectedListIds,
    required this.onToggleList,
    required this.onClearLists,
    required this.showStoreFilter,
    required this.stores,
    required this.selectedStoreIds,
    required this.onToggleStore,
    required this.onClearStores,
    required this.showNoStore,
    required this.noStoreSelected,
    required this.onToggleNoStore,
    required this.showPriceFilter,
    required this.priceFilter,
    required this.onPriceFilterChanged,
    required this.view,
    required this.onViewChanged,
  });

  @override
  State<_FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<_FiltersSection> {
  _FilterDropdown _listDropdown(ColorScheme cs) {
    return _FilterDropdown(
      label: m.checklists.filters.lists,
      icon: allListsIcon,
      selectedCount: widget.selectedListIds.length,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allLists,
          color: cs.primary,
          icon: Icons.done_all,
          selected: widget.selectedListIds.isEmpty,
          onTap: widget.onClearLists,
        ),
        for (final l in widget.lists)
          _FilterMenuEntry(
            label: l.name,
            color: parseHexColor(l.color) ?? cs.primary,
            icon: checklistIcon(l.icon),
            selected: widget.selectedListIds.contains(l.id),
            onTap: () => widget.onToggleList(l.id),
          ),
      ],
    );
  }

  _FilterDropdown _categoryDropdown(ColorScheme cs) {
    final count =
        widget.selectedCategoryIds.length + (widget.noCategorySelected ? 1 : 0);
    return _FilterDropdown(
      label: m.checklists.filters.categories,
      icon: Icons.label_outline,
      selectedCount: count,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allCategories,
          color: cs.primary,
          icon: Icons.done_all,
          selected: count == 0,
          onTap: widget.onClearCategories,
        ),
        for (final c in widget.categories)
          _FilterMenuEntry(
            label: c.name,
            color: parseHexColor(c.color) ?? cs.primary,
            icon: categoryIcon(c.icon),
            selected: widget.selectedCategoryIds.contains(c.id),
            onTap: () => widget.onToggleCategory(c.id),
          ),
        if (widget.showNoCategory)
          _FilterMenuEntry(
            label: m.checklists.filters.noCategory,
            color: cs.outline,
            icon: Icons.label_off_outlined,
            selected: widget.noCategorySelected,
            onTap: widget.onToggleNoCategory,
          ),
      ],
    );
  }

  _FilterDropdown _storeDropdown(ColorScheme cs) {
    final count =
        widget.selectedStoreIds.length + (widget.noStoreSelected ? 1 : 0);
    return _FilterDropdown(
      label: m.checklists.filters.stores,
      icon: Icons.storefront_outlined,
      selectedCount: count,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allStores,
          color: cs.primary,
          icon: Icons.done_all,
          selected: count == 0,
          onTap: widget.onClearStores,
        ),
        for (final s in widget.stores)
          _FilterMenuEntry(
            label: s.name,
            color: parseHexColor(s.color) ?? cs.primary,
            icon: storeIcon(s.icon),
            selected: widget.selectedStoreIds.contains(s.id),
            onTap: () => widget.onToggleStore(s.id),
          ),
        if (widget.showNoStore)
          _FilterMenuEntry(
            label: m.checklists.filters.noStores,
            color: cs.outline,
            icon: Icons.label_off_outlined,
            selected: widget.noStoreSelected,
            onTap: widget.onToggleNoStore,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // One multi-select dropdown per active filter dimension, laid out in a
    // horizontally-scrollable row so the same layout serves mobile and desktop
    // no matter how many dimensions are present.
    final buttons = <Widget>[
      if (widget.showListFilter) _listDropdown(cs),
      _categoryDropdown(cs),
      if (widget.showStoreFilter) _storeDropdown(cs),
      if (widget.showPriceFilter)
        _PriceFilterDropdown(
          value: widget.priceFilter,
          onChanged: widget.onPriceFilterChanged,
        ),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      buttons[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ViewToggle(view: widget.view, onChanged: widget.onViewChanged),
        ],
      ),
    );
  }
}

/// A single option row inside a [_FilterDropdown] menu. [onTap] toggles the
/// value and — by design — does NOT close the menu, so several values can be
/// picked in one pass.
class _FilterMenuEntry {
  final String label;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterMenuEntry({
    required this.label,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
}

/// A filter dimension rendered as a dropdown button that opens a multi-select
/// menu. Selecting an option toggles it in place without dismissing the menu
/// (see [_FilterMenuEntry]); the menu closes on an outside tap. The button
/// summarises the current selection as "Label · N" when anything is chosen.
class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final int selectedCount;
  final List<_FilterMenuEntry> entries;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.selectedCount,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = selectedCount > 0;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 210,
            maxWidth: 300,
            maxHeight: 340,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final e in entries) _FilterMenuRow(entry: e)],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => _FilterButton(
        label: active ? '$label · $selectedCount' : label,
        icon: icon,
        active: active,
        open: controller.isOpen,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _FilterMenuRow extends StatelessWidget {
  final _FilterMenuEntry entry;

  const _FilterMenuRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
        child: Row(
          children: [
            Icon(entry.icon, size: 17, color: entry.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              entry.selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 18,
              color: entry.selected ? cs.primary : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The tappable pill that opens a [_FilterDropdown]. Tinted with the accent
/// when a selection is applied.
class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool open;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = active ? cs.onPrimary : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerHighest,
          border: Border.all(color: active ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(width: 1),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, size: 18, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// The price filter: a dropdown whose panel holds a min/max amount range and a
/// currency selector ("Any currency" compares amounts verbatim across
/// currencies). The trigger summarises the active range, e.g. "$1-10", "≥1".
class _PriceFilterDropdown extends StatefulWidget {
  final PriceFilter value;
  final ValueChanged<PriceFilter> onChanged;

  const _PriceFilterDropdown({required this.value, required this.onChanged});

  @override
  State<_PriceFilterDropdown> createState() => _PriceFilterDropdownState();
}

class _PriceFilterDropdownState extends State<_PriceFilterDropdown> {
  static const _anyCurrency = '__any__';
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  // Guards against re-seeding the fields when the parent echoes our own emit
  // back (which would drop a trailing "." mid-decimal).
  PriceFilter? _lastEmitted;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: _fmt(widget.value.min));
    _maxCtrl = TextEditingController(text: _fmt(widget.value.max));
  }

  @override
  void didUpdateWidget(_PriceFilterDropdown old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (_lastEmitted != null &&
        v.min == _lastEmitted!.min &&
        v.max == _lastEmitted!.max &&
        v.currency == _lastEmitted!.currency) {
      return;
    }
    _minCtrl.text = _fmt(v.min);
    _maxCtrl.text = _fmt(v.max);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  static double? _parse(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final n = double.tryParse(cleaned);
    if (n == null || n < 0) return null;
    return n;
  }

  void _emit({String? currency, bool clearCurrency = false}) {
    final next = PriceFilter(
      min: _parse(_minCtrl.text),
      max: _parse(_maxCtrl.text),
      currency: clearCurrency ? null : (currency ?? widget.value.currency),
    );
    _lastEmitted = next;
    widget.onChanged(next);
  }

  void _clear() {
    _minCtrl.clear();
    _maxCtrl.clear();
    _emit(clearCurrency: true);
  }

  String _triggerLabel() {
    final f = widget.value;
    if (!f.isActive) return m.checklists.filters.price;
    final sym = f.currency != null ? resolveCurrency(f.currency).symbol : '';
    final lo = _fmt(f.min);
    final hi = _fmt(f.max);
    final String range;
    if (lo.isNotEmpty && hi.isNotEmpty) {
      range = '$lo-$hi';
    } else if (lo.isNotEmpty) {
      range = '≥$lo';
    } else if (hi.isNotEmpty) {
      range = '≤$hi';
    } else {
      // Currency-only: the symbol alone carries the filter.
      return sym.isNotEmpty ? sym : (f.currency ?? m.checklists.filters.price);
    }
    return sym.isNotEmpty ? '$sym$range' : range;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = m.checklists.price;
    final active = widget.value.isActive;
    final currency = widget.value.currency;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 268,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PriceFilterField(
                        controller: _minCtrl,
                        label: p.min,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PriceFilterField(
                        controller: _maxCtrl,
                        label: p.max,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: p.currency,
                    isDense: true,
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      12,
                      8,
                      12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currency == null
                          ? _anyCurrency
                          : (currencyByCode(currency) != null
                                ? currency.toUpperCase()
                                : _anyCurrency),
                      isExpanded: true,
                      isDense: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: _anyCurrency,
                          child: Text(
                            m.checklists.filters.anyCurrency,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final c in currencies)
                          DropdownMenuItem<String>(
                            value: c.code,
                            child: Text(
                              '${c.code} (${c.symbol})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (code) {
                        if (code == null || code == _anyCurrency) {
                          _emit(clearCurrency: true);
                        } else {
                          _emit(currency: code);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: active ? _clear : null,
                    child: Text(m.common.clear),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => _FilterButton(
        label: _triggerLabel(),
        icon: Icons.sell_outlined,
        active: active,
        open: controller.isOpen,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _PriceFilterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _PriceFilterField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  const _ItemList({
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
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              if (widget.controller.canUncheckAll) ...[
                TextButton(
                  onPressed: () => _confirmUncheckAll(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 10,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    m.checklists.uncheckAll,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            delegate: _CategoryHeaderDelegate(category: category),
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
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
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
            delegate: _StoreHeaderDelegate(store: store),
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
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
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

/// Sticky-header delegate for a store group. Fixed extent so the pinned header
/// keeps a stable height as it sticks and releases. Mirrors
/// [_CategoryHeaderDelegate].
class _StoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  final models.Store? store;

  const _StoreHeaderDelegate({required this.store});

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _StoreHeader(store: store);

  @override
  bool shouldRebuild(_StoreHeaderDelegate oldDelegate) =>
      oldDelegate.store?.id != store?.id ||
      oldDelegate.store?.color != store?.color ||
      oldDelegate.store?.name != store?.name ||
      oldDelegate.store?.icon != store?.icon;
}

/// Grouped-list header shown above each store run when sorting by store. Mirrors
/// [_CategoryHeader]: real stores render their icon + name in the store color;
/// the "No store" group falls back to muted default text.
class _StoreHeader extends StatelessWidget {
  final models.Store? store;

  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = store != null
        ? (parseHexColor(store!.color) ?? cs.onSurfaceVariant)
        : cs.onSurfaceVariant;
    final name = store?.name ?? m.checklists.noStore;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Icon(storeIcon(store?.icon), size: 16, color: color),
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

/// Sticky-header delegate for a category group. Fixed extent so the pinned
/// header keeps a stable height as it sticks and releases.
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final models.Category? category;

  const _CategoryHeaderDelegate({required this.category});

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _CategoryHeader(category: category);

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.category?.id != category?.id ||
      oldDelegate.category?.color != category?.color ||
      oldDelegate.category?.name != category?.name ||
      oldDelegate.category?.icon != category?.icon;
}

/// Grouped-list header shown above each category run when sorting by category.
/// Real categories render their icon + name in the category color; the
/// uncategorised group falls back to muted default text and label. Fills the
/// fixed height its pinned-header delegate reserves, with an opaque background
/// so item rows don't show through while it's stuck to the top.
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
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      alignment: AlignmentDirectional.centerStart,
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

/// One row in the AppBar overflow bottom sheet: a section [_OverflowDivider], a
/// plain [_OverflowAction], or a toggle [_OverflowCheckboxAction].
sealed class _OverflowEntry {
  const _OverflowEntry();
}

class _OverflowDivider extends _OverflowEntry {
  const _OverflowDivider();
}

class _OverflowAction extends _OverflowEntry {
  const _OverflowAction({
    required this.value,
    required this.icon,
    required this.label,
  });

  /// Dispatched to `_onOverflow` when the row is tapped.
  final String value;
  final IconData icon;
  final String label;
}

class _OverflowCheckboxAction extends _OverflowEntry {
  const _OverflowCheckboxAction({
    required this.value,
    required this.label,
    required this.checked,
  });

  /// Dispatched to `_onOverflow` when the row is tapped.
  final String value;
  final String label;
  final bool checked;
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
                    if (controller.hasStoresFeature)
                      _action(
                        context,
                        icon: Icons.storefront_outlined,
                        label: m.checklists.batch.stores,
                        enabled: controller.canBatchStores,
                        onTap: () => _stores(context),
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
    final affected = List.of(controller.selectedItems);
    final targetId = await _pickTargetList(
      context,
      title: m.checklists.batch.moveTitle,
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
    final targetId = await _pickTargetList(
      context,
      title: m.checklists.batch.copyTitle,
    );
    if (targetId == null) return;
    controller.batchCopy(targetId);
    // Copy is additive and non-destructive — no undo, just a confirmation.
    showAppSnackBar(message: m.checklists.batch.copied(count));
  }

  Future<void> _category(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    final choice = await _pickCategory(context);
    if (choice == null) return;
    final categoryId = choice == _kBatchClearCategory ? null : choice;
    controller.batchSetCategory(categoryId);
    _showUndo(
      m.checklists.batch.categorySet(affected.length),
      () => controller.undoBatchSetCategory(affected),
    );
  }

  Future<void> _stores(BuildContext context) async {
    final affected = List.of(controller.selectedItems);
    final choice = await _pickStores(context);
    if (choice == null) return;
    controller.batchSetStores(choice);
    _showUndo(
      m.checklists.batch.storesSet(affected.length),
      () => controller.undoBatchSetStores(affected),
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
    // Selected items may span lists (meta view), so only globals are safe there;
    // in a per-list view the current list's scope applies.
    final cats = controller.categoriesForList(
      controller.isMetaMode ? null : controller.currentList?.id,
    );
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

  /// Multi-select store picker for set-stores. Returns null on dismiss, or the
  /// chosen store ids (an empty list clears the stores on every item). The set
  /// replaces whatever the items currently carry, so it starts empty.
  Future<List<int>?> _pickStores(BuildContext context) {
    final stores = controller.sortedStores;
    final cs = Theme.of(context).colorScheme;
    final selected = <int>{};
    return showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(m.checklists.batch.storesTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: stores.isEmpty
                ? Text(m.stores.noStores)
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in stores)
                        CheckboxListTile(
                          value: selected.contains(s.id),
                          onChanged: (v) => setState(() {
                            if (v ?? false) {
                              selected.add(s.id);
                            } else {
                              selected.remove(s.id);
                            }
                          }),
                          secondary: Icon(
                            storeIcon(s.icon),
                            color: parseHexColor(s.color) ?? cs.primary,
                          ),
                          title: Text(s.name),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(m.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected.toList()),
              child: Text(m.common.save),
            ),
          ],
        ),
      ),
    );
  }
}
