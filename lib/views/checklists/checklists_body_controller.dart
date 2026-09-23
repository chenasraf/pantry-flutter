import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/main.dart' show appVersion;
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_presence_entry.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
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
import 'package:pantry/utils/app_toast.dart';
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
import 'package:pantry/widgets/auto_refresh.dart';
import 'package:pantry/widgets/create_label_dialog.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
import 'checklist_switcher_sheet.dart';
import 'checklists_controller.dart';
import 'checklists_dev_dialogs.dart';
import 'package:pantry/widgets/overflow_menu.dart';
import 'package:pantry/views/home/home_app_bar_spec.dart';
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
  final ValueNotifier<HomeAppBarSpec?>? appBarSpecHolder;

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
  ///
  /// Not necessarily started by the caller — a trip they joined resolves here
  /// too, so check [ShoppingSession.isStartedBy] before offering anything only
  /// its starter may do.
  ShoppingSession? shoppingSession;

  /// A housemate's live trip the caller could join, read from house presence.
  /// Null when nobody else is out, when the caller is already on every live
  /// trip, or when the server lacks `shopping-join-session`.
  ShoppingPresenceEntry? joinableTrip;

  /// Guards the join action: it may close the caller's own trip first, which a
  /// second tap must not repeat.
  bool joiningTrip = false;

  final String? currentUserId = AuthService.instance.credentials?.loginName;

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
    _startShoppingPoll();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopShoppingPoll();
    WidgetsBinding.instance.removeObserver(this);
    searchCtrl.dispose();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// A housemate's trip only ever surfaces through a presence read, so the
  /// join banner needs a cadence of its own — unlike the resume banner, which
  /// reflects the caller's own state and can ride navigation alone. Follows the
  /// shopping refresh interval, and "off" means no automatic calls at all.
  Timer? _shoppingPollTimer;

  void _startShoppingPoll() {
    _stopShoppingPoll();
    final interval = AutoRefresh.durationFromSeconds(
      PrefsService.instance.shoppingRefreshSecondsResolved,
    );
    if (interval == null) return;
    _shoppingPollTimer = Timer.periodic(
      interval,
      (_) => refreshShoppingSession(),
    );
  }

  void _stopShoppingPoll() {
    _shoppingPollTimer?.cancel();
    _shoppingPollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        refreshShoppingSession();
        _startShoppingPoll();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopShoppingPoll();
      case AppLifecycleState.inactive:
        break;
    }
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
    await refreshJoinableTrip();
  }

  /// Look for a housemate's trip worth offering. Presence is house-wide and
  /// covers the caller's own trip too, so the offer is the freshest trip they
  /// are not already on — one at a time, which keeps the action unambiguous.
  ///
  /// Joining implies checking things off, so it asks for `canCheckItems` and
  /// not the `canViewLists` the rest of the screen runs on.
  Future<void> refreshJoinableTrip() async {
    if (!hasFeature('shopping-join-session') ||
        !domain.permissions.canCheckItems ||
        currentUserId == null) {
      return;
    }
    try {
      final entries = await ShoppingService.instance.getPresence(
        domain.houseId,
      );
      if (_disposed) return;
      joinableTrip = entries.cast<ShoppingPresenceEntry?>().firstWhere(
        (e) => e!.sessionId != null && !e.includes(currentUserId),
        orElse: () => null,
      );
      _safeNotify();
    } catch (_) {
      /* keep the last-known offer */
    }
  }

  /// Bottom inset reserved under the item list so the resting compose bar
  /// doesn't overlap the last row. The host's own obscured inset — the floating
  /// nav and the system navigation bar — is added to this at the call site.
  double listBottomInset(ChecklistList? list) {
    if (domain.isSoftView) return 36;
    // Clears the resting compose bar plus a little breathing room.
    return PrefsService.instance.composeBarOnTop ? 0.0 : 112.0;
  }

  /// Top inset reserved above the item list for a top-anchored compose bar.
  double listTopInset(ChecklistList? list) {
    if (domain.isSoftView || !PrefsService.instance.composeBarOnTop) return 0;
    if (list == null || !domain.canAddItemsHere) return 0;
    return 80;
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

  /// The "{name} is shopping · [Join]" banner offering a housemate's trip.
  /// Joining shops that trip rather than starting a parallel one: same items,
  /// same check log, and whoever ends it ends it for everyone.
  Widget buildJoinBanner(BuildContext context) {
    final entry = joinableTrip!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = domain.members[entry.userId]?.displayName ?? entry.userId;
    final others = entry.memberIds.length - 1;
    final storeId = entry.activeStoreId;
    final store = storeId != null ? domain.stores[storeId] : null;
    // A trip several housemates already share reads as the group, so the line
    // doesn't imply its starter is out alone; the store is dropped there to
    // keep it short.
    final label = others > 0
        ? m.shopping.bannerHousematesShopping(name, others)
        : store != null
        ? m.shopping.bannerHousemateShoppingAt(name, store.name)
        : m.shopping.bannerHousemateShopping(name);

    return Material(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(Icons.groups, color: cs.onSecondaryContainer, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textDirection: detectTextDirection(name),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: joiningTrip ? null : () => joinShopping(context),
              child: Text(m.shopping.join),
            ),
          ],
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
