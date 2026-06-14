import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/onboarding_view.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
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

  const ChecklistsView({
    super.key,
    required this.houseId,
    this.refreshHolder,
    this.appBarSpecHolder,
  });

  @override
  State<ChecklistsView> createState() => _ChecklistsViewState();
}

class _ChecklistsViewState extends State<ChecklistsView> {
  late final _controller = ChecklistsController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.load();
    final holder = widget.refreshHolder;
    if (holder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        holder.value = _controller.refresh;
      });
    }
  }

  @override
  void dispose() {
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
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _Body(appBarSpecHolder: widget.appBarSpecHolder),
    );
  }
}

class _Body extends StatefulWidget {
  final ValueNotifier<ChecklistsAppBarSpec?>? appBarSpecHolder;

  const _Body({this.appBarSpecHolder});

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

  String get _query => _searchCtrl.text.trim().toLowerCase();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ListItem> _applyFilters(List<ListItem> items) {
    if (_selectedCategoryIds.isEmpty && _query.isEmpty) return items;
    return items.where((item) {
      if (_selectedCategoryIds.isNotEmpty) {
        if (!_selectedCategoryIds.contains(item.categoryId)) return false;
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
    final filteredItems = _applyFilters(controller.items);
    final activeItems = filteredItems.where((i) => !i.done).toList();
    final doneItems = filteredItems.where((i) => i.done).toList();
    final total = controller.items.where((i) => i.deletedAt == null).length;
    final done = controller.items.where((i) => i.done).length;

    final prefs = context.watch<PrefsService>();
    final isCards = prefs.checklistView == 'cards';
    final doneCollapsed = prefs.checklistDoneCollapsed;
    final isEmptyList = controller.items.isEmpty && !controller.isTrashMode;

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
                    !controller.isTrashMode &&
                    !prefs.checklistProgressHeroHidden)
                  Dismissible(
                    key: const ValueKey('progress-hero'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) =>
                        prefs.setChecklistProgressHeroHidden(true),
                    background: const SizedBox.shrink(),
                    child: ProgressHero(
                      total: total,
                      done: done,
                      // Desktop mice can't reliably swipe. Surface a tap
                      // affordance there; the Dismissible above still works
                      // for anyone who can swipe.
                      onDismiss: isDesktop
                          ? () => prefs.setChecklistProgressHeroHidden(true)
                          : null,
                    ),
                  ),
                if (!isEmptyList && !controller.isTrashMode)
                  _FilterRow(
                    categories: filterCategories,
                    selectedIds: _selectedCategoryIds,
                    onToggle: (id) {
                      setState(() {
                        if (_selectedCategoryIds.contains(id)) {
                          _selectedCategoryIds.remove(id);
                        } else {
                          _selectedCategoryIds.add(id);
                        }
                      });
                    },
                    onClear: () => setState(() => _selectedCategoryIds.clear()),
                    view: prefs.checklistView,
                    onViewChanged: (v) => prefs.setChecklistView(v),
                  ),
                if (controller.isTrashMode)
                  _TrashBanner(onExit: () => controller.setTrashMode(false)),
                Expanded(
                  child: isEmptyList
                      ? _NoItemsEmptyState()
                      : (filteredItems.isEmpty
                            ? _NoMatchesEmptyState()
                            : Padding(
                                // Reserve enough room for the resting compose
                                // bar so the last item is always reachable
                                // without the bar overlapping it.
                                padding: const EdgeInsets.only(bottom: 76),
                                child: _ItemList(
                                  controller: controller,
                                  activeItems: activeItems,
                                  doneItems: doneItems,
                                  isCards: isCards,
                                  doneCollapsed: doneCollapsed,
                                  onToggleDoneCollapsed: () =>
                                      prefs.setChecklistDoneCollapsed(
                                        !doneCollapsed,
                                      ),
                                ),
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
            if (!controller.isTrashMode && list != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  child: ItemComposeBar(
                    key: _composeKey,
                    listName: list.name,
                    deleteOnDoneDefault: list.deleteOnDoneDefault,
                    categories: controller.sortedCategories,
                    initiallyFocused: false,
                    onActiveChanged: (active) {
                      if (active != _composeActive) {
                        setState(() => _composeActive = active);
                      }
                    },
                    onRequestCreateCategory: () =>
                        _createCategory(context, controller),
                    onSubmit: (s) async {
                      try {
                        final created = await controller.addItem(
                          name: s.name,
                          description: s.description,
                          quantity: s.quantity,
                          categoryId: s.categoryId,
                          rrule: s.rrule,
                          deleteOnDone: s.deleteOnDone,
                        );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(m.checklists.itemForm.saveFailed),
                          ),
                        );
                        return false;
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  ChecklistsAppBarSpec _buildAppBarSpec(
    BuildContext context,
    ChecklistsController controller,
    ChecklistList? list,
    PrefsService prefs,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tint = parseHexColor(list?.color) ?? cs.primary;
    final isPinned =
        list != null && PrefsService.instance.isListPinned(list.id);

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
                      child: Icon(
                        checklistIcon(list.icon),
                        color: tint,
                        size: 20,
                      ),
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
        if (isDesktop && !controller.isTrashMode) ...[
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
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            tooltip: m.categories.manageTitle,
            onPressed: () => _openManageCategories(context, controller),
          ),
          if (supportsFeature('soft-delete'))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: m.checklists.viewTrash,
              onPressed: () => controller.setTrashMode(true),
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
  List<PopupMenuEntry<String>> _sortMenuItems(ChecklistsController controller) {
    return [
      _radioRow(
        value: 'sort_newest',
        label: m.checklists.sort.newestFirst,
        selected: controller.sortBy == 'newest',
      ),
      _radioRow(
        value: 'sort_oldest',
        label: m.checklists.sort.oldestFirst,
        selected: controller.sortBy == 'oldest',
      ),
      _radioRow(
        value: 'sort_name_asc',
        label: m.checklists.sort.nameAZ,
        selected: controller.sortBy == 'name_asc',
      ),
      _radioRow(
        value: 'sort_name_desc',
        label: m.checklists.sort.nameZA,
        selected: controller.sortBy == 'name_desc',
      ),
      _radioRow(
        value: 'sort_category',
        label: m.checklists.sort.category,
        selected: controller.sortBy == 'category',
      ),
      _radioRow(
        value: 'sort_custom',
        label: m.checklists.sort.custom,
        selected: controller.sortBy == 'custom',
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
        _menuRow(
          value: 'empty_trash',
          leading: const Icon(Icons.delete_forever, size: 18),
          label: m.checklists.emptyTrash,
        ),
      ];
    }
    // Desktop has promoted refresh / sort / categories / trash to dedicated
    // toolbar buttons, and pinning lists feeds an Android-only widget, so
    // none of those need to live in the overflow menu here. Everything left
    // — the view toggles and the dev tools — stays in overflow on every
    // platform.
    return <PopupMenuEntry<String>>[
      if (!isDesktop) ...[
        _radioRow(
          value: 'sort_newest',
          label: m.checklists.sort.newestFirst,
          selected: controller.sortBy == 'newest',
        ),
        _radioRow(
          value: 'sort_oldest',
          label: m.checklists.sort.oldestFirst,
          selected: controller.sortBy == 'oldest',
        ),
        _radioRow(
          value: 'sort_name_asc',
          label: m.checklists.sort.nameAZ,
          selected: controller.sortBy == 'name_asc',
        ),
        _radioRow(
          value: 'sort_name_desc',
          label: m.checklists.sort.nameZA,
          selected: controller.sortBy == 'name_desc',
        ),
        _radioRow(
          value: 'sort_category',
          label: m.checklists.sort.category,
          selected: controller.sortBy == 'category',
        ),
        _radioRow(
          value: 'sort_custom',
          label: m.checklists.sort.custom,
          selected: controller.sortBy == 'custom',
        ),
        const PopupMenuDivider(),
        if (controller.currentList != null)
          _menuRow(
            value: 'toggle_pin',
            leading: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 18,
            ),
            label: isPinned ? 'Unpin list' : 'Pin list',
          ),
      ],
      _checkboxRow(
        value: 'toggle_tap_row',
        label: m.settings.tapRowToComplete,
        selected: prefs.checklistTapRowToToggle,
      ),
      if (hasFeature('item-authors'))
        _checkboxRow(
          value: 'toggle_added_by',
          label: m.checklists.showAddedBy,
          selected: controller.showAddedBy,
        ),
      if (!isDesktop) ...[
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
        if (supportsFeature('soft-delete')) ...[
          const PopupMenuDivider(),
          _menuRow(
            value: 'view_trash',
            leading: const Icon(Icons.delete_outline, size: 18),
            label: m.checklists.viewTrash,
          ),
        ],
      ],
      if (kDebugMode) ...[
        const PopupMenuDivider(),
        _menuRow(
          value: 'dev_show_onboarding',
          leading: const Icon(Icons.bug_report_outlined, size: 18),
          label: m.onboarding.dev.showOnboarding,
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
      case 'toggle_tap_row':
        await prefs.setChecklistTapRowToToggle(!prefs.checklistTapRowToToggle);
      case 'toggle_added_by':
        await controller.setShowAddedBy(!controller.showAddedBy);
      case 'view_trash':
        await controller.setTrashMode(true);
      case 'exit_trash':
        await controller.setTrashMode(false);
      case 'empty_trash':
        await _confirmEmptyTrash(context, controller);
      case 'toggle_pin':
        await _togglePin(context, controller);
      case 'manage_categories':
        await _openManageCategories(context, controller);
      case 'refresh':
        await controller.refresh();
      case 'dev_show_onboarding':
        await _devShowOnboarding(context);
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
    await PrefsService.instance.setLastSeenOnboardingVersion(picked.value);
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

class _FilterRow extends StatefulWidget {
  final List<models.Category> categories;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final VoidCallback onClear;
  final String view;
  final ValueChanged<String> onViewChanged;

  const _FilterRow({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onClear,
    required this.view,
    required this.onViewChanged,
  });

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
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
  void didUpdateWidget(_FilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Category list size can change (new category added/removed), which
    // shifts maxScrollExtent without firing a scroll event. Re-check after
    // the post-layout pass.
    if (oldWidget.categories.length != widget.categories.length) {
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              // ShaderMask fades the trailing edge of the chip row to signal
              // more content exists past the cutoff. The mask uses dstIn so
              // the gradient's alpha becomes the row's alpha; the gradient
              // direction flips for RTL so the fade always sits at the
              // visual trailing edge. The trailing color's alpha tracks
              // `_trailingFade` so it eases off to zero (i.e. opaque, no
              // fade) as the user reaches the end or when the chips fit.
              child: NotificationListener<ScrollMetricsNotification>(
                // Fires when maxScrollExtent changes (e.g. content reflow)
                // without a scroll event — needed to catch "now everything
                // fits" transitions.
                onNotification: (_) {
                  _recompute();
                  return false;
                },
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    final isRtl =
                        Directionality.of(context) == TextDirection.rtl;
                    return LinearGradient(
                      begin: isRtl
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
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
                    children: [
                      _Chip(
                        label: m.checklists.allCategories,
                        selected: widget.selectedIds.isEmpty,
                        color: cs.primary,
                        onTap: widget.onClear,
                      ),
                      const SizedBox(width: 8),
                      for (final c in widget.categories) ...[
                        _Chip(
                          label: c.name,
                          selected: widget.selectedIds.contains(c.id),
                          color: _parseColor(c.color) ?? cs.primary,
                          onTap: () => widget.onToggle(c.id),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
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

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final v = int.tryParse(hex, radix: 16);
    return v != null ? Color(v) : null;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
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

class _ItemList extends StatelessWidget {
  final ChecklistsController controller;
  final List<ListItem> activeItems;
  final List<ListItem> doneItems;
  final bool isCards;
  final bool doneCollapsed;
  final VoidCallback onToggleDoneCollapsed;

  const _ItemList({
    required this.controller,
    required this.activeItems,
    required this.doneItems,
    required this.isCards,
    required this.doneCollapsed,
    required this.onToggleDoneCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        children: [
          for (final item in activeItems) _buildTile(context, item),
          if (doneItems.isNotEmpty) ...[
            InkWell(
              onTap: onToggleDoneCollapsed,
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
                    Icon(Icons.check, color: const Color(0xFF5FBF8A), size: 18),
                    const SizedBox(width: 11),
                    Text(
                      m.checklists.doneCount(doneItems.length),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: doneCollapsed ? 0 : 0.5,
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
            if (!doneCollapsed)
              for (final item in doneItems) _buildTile(context, item),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, ListItem item) {
    final addedByUserId =
        controller.showAddedBy &&
            item.addedBy != null &&
            item.addedBy!.isNotEmpty
        ? item.addedBy
        : null;
    final addedByDisplayName = addedByUserId != null
        ? controller.members[addedByUserId]?.displayName
        : null;
    return ChecklistItemTile(
      key: ValueKey(item.id),
      item: item,
      category: item.categoryId != null
          ? controller.categories[item.categoryId]
          : null,
      houseId: controller.houseId,
      isCardsView: isCards,
      trashMode: controller.isTrashMode,
      addedByUserId: addedByUserId,
      addedByDisplayName: addedByDisplayName,
      onToggle: (i) => _onToggle(context, controller, i),
      onView: (i) => _openView(context, controller, i),
      onEdit: (i) => _openEdit(context, controller, i),
      onMove: controller.lists.length > 1 && !controller.isTrashMode
          ? (i) => _onMove(context, controller, i)
          : null,
      onDelete: (i) => _onDelete(context, controller, i),
      onRestore: controller.isTrashMode
          ? (i) => _onRestore(context, controller, i)
          : null,
      onPermanentDelete: controller.isTrashMode
          ? (i) => _onPermanentDelete(context, controller, i)
          : null,
    );
  }

  Future<void> _onMove(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) async {
    final others = controller.lists
        .where((l) => l.id != controller.currentList?.id)
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

  void _onToggle(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    final wasDone = item.done;
    final wasDeleteOnDone = item.deleteOnDone;
    controller.toggleItem(item);
    if (wasDone) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
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
