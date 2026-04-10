import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/views/checklists/checklists_view.dart';
import 'package:pantry/views/notes/notes_wall_view.dart';
import 'package:pantry/views/photos/photo_board_view.dart';
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

class _HomeViewBodyState extends State<_HomeViewBody> {
  int _tabIndex = 0;

  String get _tabTitle => switch (_tabIndex) {
    0 => m.nav.checklists,
    1 => m.nav.photoBoard,
    2 => m.nav.notesWall,
    _ => m.common.appTitle,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitle),
        actions: [
          _UserMenuButton(
            houses: controller.houses,
            currentHouse: controller.currentHouse,
            onHouseSelected: controller.selectHouse,
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

class _UserMenuButton extends StatelessWidget {
  final List<House> houses;
  final House? currentHouse;
  final ValueChanged<House> onHouseSelected;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.houses,
    required this.currentHouse,
    required this.onHouseSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final creds = AuthService.instance.credentials;
    final loginName = creds?.loginName ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarPath = isDark
        ? 'index.php/avatar/$loginName/128/dark'
        : 'index.php/avatar/$loginName/128';

    return PopupMenuButton<Object>(
      offset: const Offset(0, 48),
      tooltip: loginName,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: creds != null
            ? CachedNetworkImage(
                imageUrl: '${creds.serverUrl}/$avatarPath',
                httpHeaders: creds.basicAuthHeaders,
                imageBuilder: (_, imageProvider) =>
                    CircleAvatar(radius: 16, backgroundImage: imageProvider),
                errorWidget: (_, _, _) => const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 20),
                ),
                placeholder: (_, _) => const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 20),
                ),
              )
            : const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 20),
              ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(loginName, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (houses.isNotEmpty) ...[
          const PopupMenuDivider(),
          ...houses.map(
            (house) => PopupMenuItem<House>(
              value: house,
              child: Row(
                children: [
                  if (house.id == currentHouse?.id)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(house.name),
                ],
              ),
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18),
              const SizedBox(width: 8),
              Text(m.common.logout),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value is House) {
          onHouseSelected(value);
        } else if (value == 'logout') {
          onLogout();
        }
      },
    );
  }
}
