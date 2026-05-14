import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/categories/categories_view.dart';
import 'package:pantry/views/checklists/checklists_view.dart';
import 'package:pantry/views/notes/notes_wall_view.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/deep_link_service.dart';
import 'package:pantry/views/notifications/notifications_controller.dart';
import 'package:pantry/views/notifications/notifications_view.dart';
import 'package:pantry/services/share_intent_service.dart';
import 'package:pantry/views/photos/photo_board_view.dart';
import 'package:pantry/views/settings/settings_view.dart';
import 'package:pantry/views/share/share_router_view.dart';
import 'package:pantry/widgets/create_house_dialog.dart';
import 'package:pantry/widgets/no_houses_view.dart';
import 'package:pantry/widgets/notifications_bell.dart';
import 'package:pantry/widgets/server_app_missing_view.dart';
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
  final _pageController = PageController();
  final _notificationsController = NotificationsController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsController.load();

    // Consume any deep link or share intent that arrived before we
    // mounted (e.g. from a cold-start notification tap or share sheet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
      _consumePendingShare();
    });

    // Listen for deep links and share intents that arrive while the home
    // view is mounted.
    DeepLinkService.instance.pending.addListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.addListener(_consumePendingShare);
  }

  @override
  void dispose() {
    DeepLinkService.instance.pending.removeListener(_consumePendingDeepLink);
    ShareIntentService.instance.pending.removeListener(_consumePendingShare);
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _notificationsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationsController.refresh();
      _consumePendingDeepLink();
      _consumePendingShare();
    }
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

  void _goToTab(int index) {
    if (index == _tabIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
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
    if (_pageController.hasClients) {
      _goToTab(link.tabIndex);
    } else {
      setState(() => _tabIndex = link.tabIndex);
    }
  }

  String get _tabTitle => switch (_tabIndex) {
    0 => m.nav.checklists,
    1 => m.nav.photoBoard,
    2 => m.nav.notesWall,
    _ => m.common.appTitle,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    final houseId = controller.currentHouse?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitle),
        actions: [
          if (_tabIndex == 0 && houseId != null)
            IconButton(
              icon: const Icon(Icons.sell_outlined),
              tooltip: m.checklists.categories,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoriesView(houseId: houseId),
                  ),
                );
              },
            ),
          NotificationsBell(
            controller: _notificationsController,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationsView(controller: _notificationsController),
                ),
              );
            },
          ),
          UserMenuButton(
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
          ),
        ],
      ),
      body: _buildBody(controller),
      bottomNavigationBar: _AnimatedBottomNav(
        pageController: _pageController,
        currentIndex: _tabIndex,
        onTap: _goToTab,
        destinations: [
          (icon: Icons.assignment_turned_in, label: m.nav.checklists),
          (icon: Icons.photo, label: m.nav.photoBoard),
          (icon: Icons.insert_drive_file, label: m.nav.notesWall),
        ],
      ),
    );
  }

  Widget _buildBody(HomeController controller) {
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
    return PageView(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (i) => setState(() => _tabIndex = i),
      children: [
        ChecklistsView(key: ValueKey('checklists-$houseId'), houseId: houseId),
        PhotoBoardView(key: ValueKey('photos-$houseId'), houseId: houseId),
        NotesWallView(key: ValueKey('notes-$houseId'), houseId: houseId),
      ],
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
