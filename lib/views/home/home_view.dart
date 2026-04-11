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
import 'package:pantry/views/photos/photo_board_view.dart';
import 'package:pantry/views/settings/settings_view.dart';
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
  final _notificationsController = NotificationsController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsController.load();

    // Consume any deep link that arrived before we mounted (e.g. from a
    // cold-start notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingDeepLink();
    });

    // Listen for deep links that arrive while the home view is mounted
    // (notification tapped while app is in foreground or background).
    DeepLinkService.instance.pending.addListener(_consumePendingDeepLink);
  }

  @override
  void dispose() {
    DeepLinkService.instance.pending.removeListener(_consumePendingDeepLink);
    WidgetsBinding.instance.removeObserver(this);
    _notificationsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationsController.refresh();
      _consumePendingDeepLink();
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

    if (mounted) setState(() => _tabIndex = link.tabIndex);
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.assignment_turned_in),
            label: m.nav.checklists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo),
            label: m.nav.photoBoard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insert_drive_file),
            label: m.nav.notesWall,
          ),
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
    switch (_tabIndex) {
      case 0:
        return ChecklistsView(
          key: ValueKey('checklists-$houseId'),
          houseId: houseId,
        );
      case 1:
        return PhotoBoardView(
          key: ValueKey('photos-$houseId'),
          houseId: houseId,
        );
      case 2:
        return NotesWallView(key: ValueKey('notes-$houseId'), houseId: houseId);
      default:
        return const SizedBox.shrink();
    }
  }
}
