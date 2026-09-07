import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry/services/list_link_service.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/checklist_sort.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/text_direction.dart';
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

part 'checklists_body_controller.menus.dart';
part 'checklists_body_controller.dialogs.dart';
part 'checklists_body_controller.navigation.dart';

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
}
