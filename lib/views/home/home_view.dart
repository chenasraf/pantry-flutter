import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/nav_section.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/deep_link_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/share_intent_service.dart';
import 'package:pantry/services/widget_link_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/checklists/checklists_view.dart';
import 'package:pantry/views/notes/notes_wall_view.dart';
import 'package:pantry/views/notifications/notifications_controller.dart';
import 'package:pantry/views/notifications/notifications_view.dart';
import 'package:pantry/views/photos/photo_board_view.dart';
import 'package:pantry/views/settings/settings_view.dart';
import 'package:pantry/views/share/share_router_view.dart';
import 'package:pantry/widgets/create_house_dialog.dart';
import 'package:pantry/widgets/no_houses_view.dart';
import 'package:pantry/widgets/notifications_bell.dart';
import 'package:pantry/widgets/server_app_missing_view.dart';
import 'package:pantry/widgets/sync_status_banner.dart';
import 'package:pantry/widgets/user_menu_button.dart';
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
  // Tracks the order seen at the last build/listener pass so we can remap
  // _tabIndex when the user reorders sections in settings — the active
  // section should follow its new display position, not snap to whatever
  // index it used to be.
  late List<NavSection> _lastOrder = PrefsService.instance.navOrder;
  final _pageController = PageController();
  final _notificationsController = NotificationsController();
  // Per-section refresh holders. Keyed by NavSection so that reordering
  // the bottom bar doesn't rewire which tab pulls which refresher.
  final Map<NavSection, ValueNotifier<Future<void> Function()?>>
  _tabRefreshers = {for (final s in NavSection.values) s: ValueNotifier(null)};
  // Per-section scroll controllers, owned here so iOS status-bar-tap can
  // scroll the active tab to the top regardless of which view is hosting it.
  // Each tab's view receives its controller via [scrollController:] and uses
  // it as the controller of its primary vertical scrollable.
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
      WidgetLinkService.instance.checkOnResume();
    });

    // Listen for deep links and share intents that arrive while the home
    // view is mounted.
    DeepLinkService.instance.pending.addListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.addListener(_consumePendingShare);
    WidgetLinkService.instance.pending.addListener(_consumePendingWidgetTap);
  }

  @override
  void dispose() {
    DeepLinkService.instance.pending.removeListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.removeListener(_consumePendingShare);
    WidgetLinkService.instance.pending.removeListener(_consumePendingWidgetTap);
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

  List<NavSection> get _navOrder => PrefsService.instance.navOrder;

  /// Keep the active section pinned when the user reorders nav items in
  /// settings: find where the active section moved to and follow it.
  void _onPrefsChanged() {
    final newOrder = PrefsService.instance.navOrder;
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

    // Switch house if specified and different from current.
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

    final homeController = context.read<HomeController>();

    // Switch to the right house if provided.
    if (tap.houseId != null && tap.houseId != homeController.currentHouse?.id) {
      final house = homeController.houses.cast<House?>().firstWhere(
        (h) => h!.id == tap.houseId,
        orElse: () => null,
      );
      if (house != null) homeController.selectHouse(house);
    }

    // Pre-select the list so ChecklistsController picks it up on load.
    ChecklistService.instance.selectedListId = tap.listId;

    if (!mounted) return;
    // Navigate to the checklists tab regardless of its current position.
    final checklistsIndex = _navOrder.indexOf(NavSection.checklists);
    if (_pageController.hasClients) {
      _goToTab(checklistsIndex);
    } else {
      setState(() => _tabIndex = checklistsIndex);
    }

    // Trigger a refresh on the checklists tab so the controller reloads
    // and picks up the new selectedListId.
    _tabRefreshers[NavSection.checklists]?.value?.call();
  }

  String _sectionTitle(NavSection s) => switch (s) {
    NavSection.checklists => m.nav.checklists,
    NavSection.photoBoard => m.nav.photoBoard,
    NavSection.notesWall => m.nav.notesWall,
  };

  IconData _sectionIcon(NavSection s) => switch (s) {
    NavSection.checklists => Icons.assignment_turned_in,
    NavSection.photoBoard => Icons.photo,
    NavSection.notesWall => Icons.insert_drive_file,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    // Rebuild when the nav order changes so a setting tweak applies live.
    context.watch<PrefsService>();
    final order = _navOrder;
    // Clamp so a reorder that shifted the active section still lands on a
    // real tab. The current section is preserved by adjusting `_tabIndex`
    // once a reorder happens via the settings screen.
    final tabIndex = _tabIndex.clamp(0, order.length - 1);
    final destinations = [
      for (final s in order) (icon: _sectionIcon(s), label: _sectionTitle(s)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 720;
        final extendedRail = constraints.maxWidth >= 1100;
        final body = _buildBody(controller, useRail: useRail, order: order);

        // Single shared AppBar across all tabs. On the checklists tab,
        // ChecklistsView populates `_checklistsAppBarSpec` with its leading /
        // title / actions; the AppBar widget instance stays put across tab
        // swipes so there's no jarring swap — only its content changes.
        final currentSection = order[tabIndex];
        final isChecklistsTab = currentSection == NavSection.checklists;

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
                  actions: [...spec.actions, notificationsBell, userMenuButton],
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
                  Expanded(
                    child: Column(
                      children: [
                        appBar,
                        const SyncStatusBanner(),
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
              const SyncStatusBanner(),
              Expanded(child: body),
            ],
          ),
          bottomNavigationBar: _AnimatedBottomNav(
            pageController: _pageController,
            currentIndex: tabIndex,
            onTap: _goToTab,
            destinations: destinations,
          ),
        );
      },
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

typedef _NavDestination = ({IconData icon, String label});

/// Bottom navigation bar that continuously interpolates its indicator
/// and icon colors based on a [PageController]'s fractional page value.
class _AnimatedBottomNav extends StatelessWidget {
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavDestination> destinations;

  const _AnimatedBottomNav({
    required this.pageController,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      elevation: 3,
      surfaceTintColor: cs.surfaceTint,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: AnimatedBuilder(
            animation: pageController,
            builder: (context, _) {
              final page = pageController.hasClients
                  ? (pageController.page ?? currentIndex.toDouble())
                  : currentIndex.toDouble();
              return Row(
                children: List.generate(destinations.length, (i) {
                  final d = destinations[i];
                  final distance = (page - i).abs().clamp(0.0, 1.0);
                  final t = 1.0 - distance;
                  final iconColor = Color.lerp(
                    cs.onSurfaceVariant,
                    cs.onSecondaryContainer,
                    t,
                  )!;
                  final labelColor = Color.lerp(
                    cs.onSurfaceVariant,
                    cs.onSurface,
                    t,
                  )!;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedIndicator(
                            opacity: t,
                            color: cs.secondaryContainer,
                            child: Icon(d.icon, color: iconColor, size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: labelColor,
                              fontWeight: t > 0.5
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedIndicator extends StatelessWidget {
  final double opacity;
  final Color color;
  final Widget child;

  const _AnimatedIndicator({
    required this.opacity,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
