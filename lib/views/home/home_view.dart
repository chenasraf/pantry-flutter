import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/nav_section.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/deep_link_service.dart';
import 'package:pantry/services/list_link_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/services/share_intent_service.dart';
import 'package:pantry/services/widget_link_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/views/checklists/checklists_view.dart';
import 'package:pantry/views/notes/notes_wall_view.dart';
import 'package:pantry/views/notifications/notifications_controller.dart';
import 'package:pantry/views/notifications/notifications_view.dart';
import 'package:pantry/views/photos/photo_board_view.dart';
import 'package:pantry/views/settings/settings_view.dart';
import 'package:pantry/views/share/share_router_view.dart';
import 'package:pantry/widgets/create_house_dialog.dart';
import 'package:pantry/widgets/no_access_view.dart';
import 'package:pantry/widgets/no_houses_view.dart';
import 'package:pantry/widgets/notifications_bell.dart';
import 'package:pantry/widgets/server_app_missing_view.dart';
import 'package:pantry/widgets/sync_status.dart';
import 'package:pantry/widgets/user_menu_button.dart';
import 'home_bottom_nav.dart';
import 'home_controller.dart';

class HomeView extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeView({super.key, required this.onLogout});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _HomeViewBody(onLogout: widget.onLogout),
    );
  }
}

class _HomeViewBody extends StatefulWidget {
  final VoidCallback onLogout;

  const _HomeViewBody({required this.onLogout});

  @override
  State<_HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<_HomeViewBody>
    with WidgetsBindingObserver {
  int _tabIndex = 0;
  // Order seen at the last pass, so a reorder in settings can remap _tabIndex
  // to follow the active section to its new position instead of snapping.
  late List<NavSection> _lastOrder = PrefsService.instance.enabledNavOrder;
  final _pageController = PageController();
  final _notificationsController = NotificationsController();
  // Per-section refresh holders. Keyed by NavSection so that reordering
  // the bottom bar doesn't rewire which tab pulls which refresher.
  final Map<NavSection, ValueNotifier<Future<void> Function()?>>
  _tabRefreshers = {for (final s in NavSection.values) s: ValueNotifier(null)};
  // Per-section scroll controllers, owned here so iOS status-bar-tap can scroll
  // the active tab to the top regardless of which view is hosting it.
  final Map<NavSection, ScrollController> _tabScrollers = {
    for (final s in NavSection.values) s: ScrollController(),
  };
  // Single shared AppBar; ChecklistsView writes its leading/title/actions into
  // this slot so the AppBar stays the same widget instance across tab swipes
  // and only its content swaps.
  final ValueNotifier<ChecklistsAppBarSpec?> _checklistsAppBarSpec =
      ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsController.load();
    PrefsService.instance.addListener(_onPrefsChanged);

    // Consume any deep link or share intent that arrived before we
    // mounted (e.g. from a cold-start notification tap or share sheet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
      _consumePendingShare();
      _consumePendingListLink();
      WidgetLinkService.instance.checkOnResume();
    });

    // Listen for deep links and share intents that arrive while the home
    // view is mounted.
    DeepLinkService.instance.pending.addListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.addListener(_consumePendingShare);
    WidgetLinkService.instance.pending.addListener(_consumePendingWidgetTap);
    ListLinkService.instance.pending.addListener(_consumePendingListLink);
  }

  @override
  void dispose() {
    DeepLinkService.instance.pending.removeListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.removeListener(_consumePendingShare);
    WidgetLinkService.instance.pending.removeListener(_consumePendingWidgetTap);
    ListLinkService.instance.pending.removeListener(_consumePendingListLink);
    PrefsService.instance.removeListener(_onPrefsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _notificationsController.dispose();
    for (final n in _tabRefreshers.values) {
      n.dispose();
    }
    for (final c in _tabScrollers.values) {
      c.dispose();
    }
    _checklistsAppBarSpec.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationsController.refresh();
      _consumePendingDeepLink();
      _consumePendingShare();
      unawaited(WidgetLinkService.instance.checkOnResume());
    }
  }

  @override
  void handleStatusBarTap() {
    // iOS scroll-to-top: animate whichever scrollable is active in the
    // current tab. Scaffold's default handler looks for a PrimaryScrollController
    // above itself and finds none, so we drive this ourselves against the
    // per-section controller the active view is using.
    final order = _navOrder;
    if (order.isEmpty) return;
    final section = order[_tabIndex.clamp(0, order.length - 1)];
    final ctrl = _tabScrollers[section];
    if (ctrl == null || !ctrl.hasClients) return;
    ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeMetrics() {
    // Rotating between portrait (PageView) and landscape (IndexedStack +
    // NavigationRail) detaches the PageController; on re-attach it defaults
    // to initialPage 0, which leaves the body on the first tab while the
    // AppBar title still reflects _tabIndex. Re-sync after the rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      final page =
          (_pageController.page ?? _pageController.initialPage.toDouble())
              .round();
      if (page != _tabIndex) {
        _pageController.jumpToPage(_tabIndex);
      }
    });
  }

  void _consumePendingShare() {
    final files = ShareIntentService.instance.consume();
    if (files == null || files.isEmpty || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareRouterView(files: files),
        fullscreenDialog: true,
      ),
    );
  }

  List<NavSection> get _navOrder => PrefsService.instance.enabledNavOrder;

  /// Keep the active section pinned when the user reorders or hides nav items
  /// in settings: find where the active section moved to and follow it.
  void _onPrefsChanged() {
    final newOrder = PrefsService.instance.enabledNavOrder;
    if (_listEqual(_lastOrder, newOrder)) return;
    final activeIndex = _tabIndex.clamp(0, _lastOrder.length - 1);
    final activeSection = _lastOrder[activeIndex];
    final newIndex = newOrder.indexOf(activeSection);
    _lastOrder = newOrder;
    if (newIndex < 0 || newIndex == _tabIndex) return;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(newIndex);
    }
    if (mounted) setState(() => _tabIndex = newIndex);
  }

  static bool _listEqual(List<NavSection> a, List<NavSection> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _goToTab(int index) {
    if (index == _tabIndex) return;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _tabIndex = index);
    }
  }

  void _consumePendingDeepLink() {
    final link = DeepLinkService.instance.consume();
    if (link == null) return;
    final homeController = context.read<HomeController>();

    // A reminder that names a list + item opens that item detail directly,
    // reusing the shared list/item sink (house switch, preselect, tab jump).
    if (link.listId != null) {
      _openList(
        listId: link.listId!,
        houseId: link.houseId,
        itemId: link.itemId,
      );
      return;
    }

    if (link.houseId != null &&
        link.houseId != homeController.currentHouse?.id) {
      final house = homeController.houses.cast<House?>().firstWhere(
        (h) => h!.id == link.houseId,
        orElse: () => null,
      );
      if (house != null) {
        homeController.selectHouse(house);
      }
    }

    if (!mounted) return;
    // DeepLink tab indices are semantic (0=checklists, 1=photos, 2=notes) —
    // translate to the current display order before navigating.
    final section = NavSection.fromDeepLinkIndex(link.tabIndex);
    if (section == null) return;
    final displayIndex = _navOrder.indexOf(section);
    if (displayIndex < 0) return;
    if (_pageController.hasClients) {
      _goToTab(displayIndex);
    } else {
      setState(() => _tabIndex = displayIndex);
    }
  }

  void _consumePendingWidgetTap() {
    final tap = WidgetLinkService.instance.pending.value;
    if (tap == null) return;
    WidgetLinkService.instance.pending.value = null;
    _openList(listId: tap.listId, houseId: tap.houseId);
  }

  void _consumePendingListLink() {
    final link = ListLinkService.instance.pending.value;
    if (link == null) return;
    ListLinkService.instance.pending.value = null;
    _openList(listId: link.listId, houseId: link.houseId, itemId: link.itemId);
  }

  /// Switch to [houseId] (when given and not already current), pre-select
  /// [listId], and jump to the checklists tab. Shared sink for widget taps,
  /// `pantry://` URL deep links, launcher quick actions and pinned shortcuts.
  /// When [itemId] is given, the checklists view opens that item once loaded.
  void _openList({required int listId, int? houseId, int? itemId}) {
    final homeController = context.read<HomeController>();

    if (houseId != null && houseId != homeController.currentHouse?.id) {
      final house = homeController.houses.cast<House?>().firstWhere(
        (h) => h!.id == houseId,
        orElse: () => null,
      );
      if (house != null) homeController.selectHouse(house);
    }

    // Pre-select the list so ChecklistsController picks it up on load.
    ChecklistService.instance.selectedListId = listId;
    ChecklistService.instance.pendingOpenItemId = itemId;

    if (!mounted) return;
    final checklistsIndex = _navOrder.indexOf(NavSection.checklists);
    if (_pageController.hasClients) {
      _goToTab(checklistsIndex);
    } else {
      setState(() => _tabIndex = checklistsIndex);
    }

    // Refresh so the checklists controller reloads with the new selectedListId.
    _tabRefreshers[NavSection.checklists]?.value?.call();
  }

  String _sectionTitle(NavSection s) => switch (s) {
    NavSection.checklists => m.nav.checklists,
    NavSection.photoBoard => m.nav.photoBoard,
    NavSection.notesWall => m.nav.notesWall,
  };

  IconData _sectionIcon(NavSection s) => switch (s) {
    NavSection.checklists => EntityIcons.checklists,
    NavSection.photoBoard => EntityIcons.photos,
    NavSection.notesWall => EntityIcons.notes,
  };

  bool _sectionVisible(NavSection s, HousePermissions perms) => switch (s) {
    NavSection.checklists => perms.canViewLists,
    NavSection.photoBoard => perms.canViewPhotos,
    NavSection.notesWall => perms.canViewNotes,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    // Rebuild when the nav order changes so a setting tweak applies live.
    context.watch<PrefsService>();
    final permissions =
        controller.currentHouse?.effectivePermissions ??
        HousePermissions.unrestricted;
    // Drop sections the current house can't view. The same filtered list feeds
    // both the nav destinations and the page bodies so indices stay aligned.
    final order = [
      for (final s in _navOrder)
        if (_sectionVisible(s, permissions)) s,
    ];
    final destinations = [
      for (final s in order) (icon: _sectionIcon(s), label: _sectionTitle(s)),
    ];

    return Provider<HousePermissions>.value(
      value: permissions,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final notificationsBell = NotificationsBell(
            controller: _notificationsController,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationsView(controller: _notificationsController),
                ),
              );
            },
          );
          final userMenuButton = UserMenuButton(
            houses: controller.houses,
            currentHouse: controller.currentHouse,
            onHouseSelected: controller.selectHouse,
            onCreateHouse: () => showCreateHouseDialog(context, controller),
            onOpenSettings: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
            },
            onLogout: widget.onLogout,
          );

          // The current house grants no viewable sections at all: show an
          // explanatory state but keep the house switcher / user menu reachable
          // so the user can switch to a house they can access or change account.
          if (order.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text(controller.currentHouse?.name ?? m.common.appTitle),
                actions: [notificationsBell, userMenuButton],
              ),
              body: const NoAccessView(),
            );
          }

          final useRail = constraints.maxWidth >= 720;
          final extendedRail = constraints.maxWidth >= 1100;
          // With a single visible section there's nothing to switch between,
          // so drop the rail / bottom bar and give the tab the full space.
          final showNav = order.length > 1;
          final tabIndex = _tabIndex.clamp(0, order.length - 1);
          final body = _buildBody(controller, useRail: useRail, order: order);

          // On the checklists tab, ChecklistsView populates
          // `_checklistsAppBarSpec` with its leading / title / actions.
          final currentSection = order[tabIndex];
          final isChecklistsTab = currentSection == NavSection.checklists;

          final appBar = PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: ValueListenableBuilder<ChecklistsAppBarSpec?>(
              valueListenable: _checklistsAppBarSpec,
              builder: (context, spec, _) {
                if (isChecklistsTab && spec != null) {
                  return AppBar(
                    leading: spec.leading,
                    leadingWidth: spec.leadingWidth,
                    title: spec.title,
                    titleSpacing: spec.titleSpacing,
                    actions: [
                      ...spec.actions,
                      notificationsBell,
                      userMenuButton,
                    ],
                  );
                }
                return AppBar(
                  title: Text(_sectionTitle(currentSection)),
                  actions: [
                    if (PlatformInfo.isDesktop)
                      ValueListenableBuilder<Future<void> Function()?>(
                        valueListenable: _tabRefreshers[currentSection]!,
                        builder: (_, refresh, _) => IconButton(
                          icon: const Icon(Icons.refresh),
                          tooltip: m.common.refresh,
                          onPressed: refresh,
                        ),
                      ),
                    notificationsBell,
                    userMenuButton,
                  ],
                );
              },
            ),
          );

          if (useRail) {
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    if (showNav) ...[
                      NavigationRail(
                        extended: extendedRail,
                        selectedIndex: tabIndex,
                        onDestinationSelected: _goToTab,
                        labelType: extendedRail
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        leading: PlatformInfo.isMacOS
                            ? const SizedBox(height: 24)
                            : null,
                        destinations: [
                          for (final d in destinations)
                            NavigationRailDestination(
                              icon: Icon(d.icon),
                              label: Text(d.label),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                    ],
                    Expanded(
                      child: Column(
                        children: [
                          appBar,
                          const SyncConnectivityListener(),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: isChecklistsTab ? 0 : 16,
                              ),
                              child: body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: appBar,
            body: Column(
              children: [
                const SyncConnectivityListener(),
                Expanded(child: body),
              ],
            ),
            bottomNavigationBar: showNav
                ? AnimatedBottomNav(
                    pageController: _pageController,
                    currentIndex: tabIndex,
                    onTap: _goToTab,
                    destinations: destinations,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody(
    HomeController controller, {
    required bool useRail,
    required List<NavSection> order,
  }) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.serverAppMissing) {
      return ServerAppMissingView(onRetry: controller.load);
    }

    if (controller.currentHouse == null && controller.error == null) {
      return NoHousesView(controller: controller);
    }

    if (controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }

    final houseId = controller.currentHouse!.id;
    Widget pageFor(NavSection s) => switch (s) {
      NavSection.checklists => ChecklistsView(
        key: ValueKey('checklists-$houseId'),
        houseId: houseId,
        refreshHolder: _tabRefreshers[NavSection.checklists]!,
        appBarSpecHolder: _checklistsAppBarSpec,
        scrollController: _tabScrollers[NavSection.checklists]!,
      ),
      NavSection.photoBoard => PhotoBoardView(
        key: ValueKey('photos-$houseId'),
        houseId: houseId,
        refreshHolder: _tabRefreshers[NavSection.photoBoard]!,
        scrollController: _tabScrollers[NavSection.photoBoard]!,
      ),
      NavSection.notesWall => NotesWallView(
        key: ValueKey('notes-$houseId'),
        houseId: houseId,
        refreshHolder: _tabRefreshers[NavSection.notesWall]!,
        scrollController: _tabScrollers[NavSection.notesWall]!,
      ),
    };
    final pages = [for (final s in order) pageFor(s)];
    final tabIndex = _tabIndex.clamp(0, pages.length - 1);
    if (useRail) {
      return IndexedStack(index: tabIndex, children: pages);
    }
    return PageView(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (i) => setState(() => _tabIndex = i),
      children: pages,
    );
  }
}
