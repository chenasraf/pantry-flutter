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
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
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
import 'package:pantry/views/labels/labels_view.dart';
import 'package:pantry/views/categories/category_form_view.dart';
import 'package:pantry/views/custom_fields/custom_fields_view.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';
import 'package:pantry/views/shopping/shopping_session_view.dart';
import 'package:pantry/views/shopping/shopping_start_view.dart';
import 'package:pantry/views/stores/stores_view.dart';
import 'package:pantry/widgets/auto_refresh.dart';
import 'package:pantry/widgets/create_label_dialog.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
import 'checklist_item_list.dart';
import 'checklist_item_tile.dart';
import 'checklist_switcher_sheet.dart';
import 'checklists_banners.dart';
import 'checklists_controller.dart';
import 'checklists_dev_dialogs.dart';
import 'checklists_empty_states.dart';
import 'checklists_filter_bar.dart';
import 'checklists_overflow_menu.dart';
import 'checklists_selection_bar.dart';
import 'item_compose_bar.dart';
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
  final Set<int> _selectedLabelIds = {};
  bool _noLabelSelected = false;
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
    final labelFilterActive = _selectedLabelIds.isNotEmpty || _noLabelSelected;
    final priceFilterActive = _priceFilter.isActive;
    if (!categoryFilterActive &&
        !storeFilterActive &&
        !labelFilterActive &&
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
      if (labelFilterActive) {
        // Match-ANY (OR): an item passes if it carries at least one selected
        // label; "No label" matches items with no labels.
        final matchesId = item.labelIds.any(_selectedLabelIds.contains);
        final matchesNone = _noLabelSelected && item.labelIds.isEmpty;
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
      return ChecklistsErrorView(
        message: controller.error!,
        onRetry: controller.load,
      );
    }
    if (controller.lists.isEmpty) {
      return ChecklistsNoListsEmptyState(
        onCreate: () => _openSwitcher(controller),
      );
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
        _selectedLabelIds.isEmpty &&
        !_noLabelSelected &&
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

    // Label filter mirrors stores, gated on the `labels` capability. Only
    // labels with at least one (non-trashed) item on this list are offered.
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
        controller.items.any((i) => i.deletedAt == null && i.labelIds.isEmpty);
    final showLabelFilter =
        labelsEnabled && (filterLabels.isNotEmpty || hasNoLabelItems);

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
                        ? ChecklistsSearchField(
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
                  ChecklistsFiltersSection(
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
                    showLabelFilter: showLabelFilter,
                    labels: filterLabels,
                    selectedLabelIds: _selectedLabelIds,
                    onToggleLabel: (id) {
                      setState(() {
                        if (!_selectedLabelIds.remove(id)) {
                          _selectedLabelIds.add(id);
                        }
                      });
                    },
                    onClearLabels: () => setState(() {
                      _selectedLabelIds.clear();
                      _noLabelSelected = false;
                    }),
                    showNoLabel: hasNoLabelItems,
                    noLabelSelected: _noLabelSelected,
                    onToggleNoLabel: () =>
                        setState(() => _noLabelSelected = !_noLabelSelected),
                    showPriceFilter: showPriceFilter,
                    priceFilter: _priceFilter,
                    onPriceFilterChanged: (f) =>
                        setState(() => _priceFilter = f),
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
                                  // The room for the resting compose bar and the
                                  // floating shopping FAB is reserved as trailing
                                  // scroll padding *inside* the list (not an outer
                                  // gap), so items use the full viewport and are
                                  // never clipped mid-list — the extra space only
                                  // appears once scrolled to the bottom.
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
                      // Archived items join the reuse pool only when the user
                      // opts in and the server advertises the capability; the
                      // controller fetches them lazily and keeps them live.
                      final suggestArchived =
                          reuseActive &&
                          hasFeature('pref-suggest-archived-items') &&
                          prefs.suggestArchivedItems;
                      final archivedReuseCandidates = suggestArchived
                          ? controller.archivedReuseCandidates(reuseTargetId)
                          : const <ListItem>[];
                      return ItemComposeBar(
                        key: _composeKey,
                        listName: list.name,
                        houseId: controller.houseId,
                        listId: meta ? null : list.id,
                        deleteOnDoneDefault: meta
                            ? false
                            : list.deleteOnDoneDefault,
                        categories: controller.categoriesForList(
                          meta ? _composeTargetListId : list.id,
                        ),
                        stores: hasFeature('stores')
                            ? controller.sortedStores
                            : const [],
                        labels: hasFeature('labels')
                            ? controller.labelsForList(
                                meta ? _composeTargetListId : list.id,
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
                              labels: controller.labelsFor(item),
                              houseId: controller.houseId,
                              onTap: onTap,
                              archived: item.archivedAt != null,
                            ),
                        onReuseExisting: (item) =>
                            _reuseFromSuggestion(context, controller, item),
                        archivedReuseCandidates: archivedReuseCandidates,
                        onArchivedSearchStarted: suggestArchived
                            ? controller.ensureArchivedReuseLoaded
                            : null,
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
                        onRequestCreateLabel:
                            hasFeature('labels') &&
                                controller.permissions.canEditLists
                            ? () => _createLabel(
                                context,
                                controller,
                                defaultListId: meta
                                    ? _composeTargetListId
                                    : list.id,
                              )
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
                child: SelectionActionBar(controller: controller),
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
      await controller.reuseArchivedItem(item);
    } else {
      await controller.reuseItem(item);
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
          labelIds: s.labelIds.isEmpty ? null : s.labelIds,
          rrule: s.rrule,
          repeatFromCompletion: s.repeatFromCompletion,
          deleteOnDone: s.deleteOnDone,
          barcode: s.barcode,
          prices: s.prices,
          customFields: s.customFields,
        );
      } else {
        created = await controller.addItem(
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
                _selectedLabelIds.clear();
                _noLabelSelected = false;
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
              icon: const Icon(EntityIcons.category),
              tooltip: m.categories.manageTitle,
              onPressed: () => _openManageCategories(context, controller),
            ),
          if (controller.permissions.canEditLists && hasFeature('stores'))
            IconButton(
              icon: const Icon(EntityIcons.store),
              tooltip: m.stores.manageTitle,
              onPressed: () => _openManageStores(context, controller),
            ),
          if (controller.permissions.canEditLists && hasFeature('labels'))
            IconButton(
              icon: const Icon(EntityIcons.label),
              tooltip: m.labels.manageTitle,
              onPressed: () => _openManageLabels(context, controller),
            ),
          if (controller.permissions.canEditFields &&
              hasFeature('custom-fields'))
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: m.customFields.manageTitle,
              onPressed: () => _openManageCustomFields(context, controller),
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
            itemBuilder: (_) =>
                _overflowMenuItems(_overflowItems(controller, prefs)),
          )
        else
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: m.common.more,
            onPressed: () => _showOverflowSheet(context, controller, prefs),
          ),
      ],
    );
  }

  /// Renders the shared overflow [entries] as anchored popup-menu rows for the
  /// desktop toolbar. The bottom-sheet variant renders the same entries as
  /// [ListTile]s in [_showOverflowSheet].
  List<PopupMenuEntry<String>> _overflowMenuItems(
    List<ChecklistsOverflowEntry> entries,
  ) {
    return [
      for (final entry in entries)
        switch (entry) {
          ChecklistsOverflowDivider() => const PopupMenuDivider(),
          ChecklistsOverflowAction(:final value, :final icon, :final label) =>
            _menuRow(value: value, leading: Icon(icon, size: 20), label: label),
          ChecklistsOverflowCheckboxAction(
            :final value,
            :final label,
            :final checked,
          ) =>
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

  List<ChecklistsOverflowEntry> _overflowItems(
    ChecklistsController controller,
    PrefsService prefs,
  ) {
    if (controller.isTrashMode) {
      return _normalizeOverflow([
        ChecklistsOverflowAction(
          value: 'exit_trash',
          icon: Icons.arrow_back,
          label: m.checklists.exitTrash,
        ),
        // Bulk restore / permanent-delete need a selection; surface the entry
        // point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
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
    if (controller.isArchiveMode) {
      return _normalizeOverflow([
        ChecklistsOverflowAction(
          value: 'exit_archive',
          icon: Icons.arrow_back,
          label: m.checklists.exitArchive,
        ),
        // Bulk unarchive / permanent-delete need a selection; surface the
        // entry point here so it's reachable without a long-press (desktop).
        if (controller.canSelectItems && controller.items.isNotEmpty)
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
    final isMeta = controller.isMetaMode;
    final effective = controller.effectiveSortBy;
    return _normalizeOverflow([
      if (controller.canSelectItems && controller.items.isNotEmpty) ...[
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
          label: '${m.checklists.sortTooltip}: ${_sortLabel(effective)}',
        ),
        const ChecklistsOverflowDivider(),
        if (controller.currentList != null && !isMeta && PlatformInfo.isMobile)
          ChecklistsOverflowAction(
            value: 'copy_link',
            icon: Icons.link,
            label: m.checklists.copyLink,
          ),
        if (controller.currentList != null && !isMeta && PlatformInfo.isAndroid)
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
          checked: controller.showAddedBy,
        ),
      if (controller.currentList != null)
        ChecklistsOverflowCheckboxAction(
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
        const ChecklistsOverflowDivider(),
        ChecklistsOverflowAction(
          value: 'reset_order',
          icon: Icons.sort_by_alpha,
          label: m.checklists.resetOrder.menuLabel,
        ),
      ],
      // Markdown import/export are per-list only — not offered in the meta
      // "All lists" view, which has no single target.
      if (controller.currentList != null && !isMeta) ...[
        const ChecklistsOverflowDivider(),
        ChecklistsOverflowAction(
          value: 'export_markdown',
          icon: Icons.file_download_outlined,
          label: m.checklists.markdown.exportTitle,
        ),
        if (controller.canAddItemsHere)
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
            icon: _shoppingSession != null
                ? Icons.play_arrow
                : Icons.shopping_cart,
            label: _shoppingSession != null
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
        if (controller.permissions.canEditLists)
          ChecklistsOverflowAction(
            value: 'manage_categories',
            icon: EntityIcons.category,
            label: m.categories.manageTitle,
          ),
        if (controller.permissions.canEditLists && hasFeature('stores'))
          ChecklistsOverflowAction(
            value: 'manage_stores',
            icon: EntityIcons.store,
            label: m.stores.manageTitle,
          ),
        if (controller.permissions.canEditLists && hasFeature('labels'))
          ChecklistsOverflowAction(
            value: 'manage_labels',
            icon: EntityIcons.label,
            label: m.labels.manageTitle,
          ),
        if (controller.permissions.canEditFields && hasFeature('custom-fields'))
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
            controller.isCurrentListWritable &&
            controller.permissions.canDeleteItems &&
            (supportsFeature('soft-delete') || hasFeature('item-trash'))) ...[
          const ChecklistsOverflowDivider(),
          ChecklistsOverflowAction(
            value: 'view_trash',
            icon: Icons.delete_outline,
            label: m.checklists.viewTrash,
          ),
        ],
        if (!isMeta &&
            controller.isCurrentListWritable &&
            controller.permissions.canEditLists &&
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
  List<ChecklistsOverflowEntry> _normalizeOverflow(
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
    leading: ChecklistsRadioIndicator(selected: selected),
    label: label,
  );

  /// The AppBar overflow lives in a bottom sheet rather than a popup menu: it
  /// carries enough entries (view toggles, per-list actions, shopping, dev
  /// tools) that a sheet reads and scrolls better than a tall anchored menu.
  Future<void> _showOverflowSheet(
    BuildContext context,
    ChecklistsController controller,
    PrefsService prefs,
  ) async {
    final entries = _overflowItems(controller, prefs);
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
      case 'copy_link':
        await _copyListLink(context, controller);
      case 'add_to_home':
        await _addListToHomeScreen(context, controller);
      case 'manage_categories':
        await _openManageCategories(context, controller);
      case 'manage_stores':
        await _openManageStores(context, controller);
      case 'manage_labels':
        await _openManageLabels(context, controller);
      case 'manage_custom_fields':
        await _openManageCustomFields(context, controller);
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

  Future<void> _openManageCustomFields(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFieldsView(houseId: controller.houseId),
      ),
    );
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
    final created = await Navigator.of(context).push<models.Category>(
      itemModalRoute(
        CategoryFormView(
          houseId: controller.houseId,
          defaultListId: defaultListId,
        ),
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

  Future<void> _openManageLabels(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabelsView(houseId: controller.houseId),
      ),
    );
    await controller.onLabelsChanged();
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

  /// Opens the create-label dialog inline from the compose bar's label tray. On
  /// success, refreshes the controller's label list (so the new option shows up
  /// in the tray) and returns the new Label so compose bar can auto-select it.
  Future<models.Label?> _createLabel(
    BuildContext context,
    ChecklistsController controller, {
    int? defaultListId,
  }) async {
    final created = await showDialog<models.Label>(
      context: context,
      builder: (_) => CreateLabelDialog(
        houseId: controller.houseId,
        defaultListId: defaultListId,
      ),
    );
    if (created != null) {
      await controller.onLabelsChanged();
    }
    return created;
  }

  Future<void> _copyListLink(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final list = controller.currentList;
    if (list == null) return;
    final uri = ListLink.uri(list.houseId, list.id);
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m.common.copied)));
  }

  Future<void> _addListToHomeScreen(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final list = controller.currentList;
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
