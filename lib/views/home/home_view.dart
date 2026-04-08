import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/models/house.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/views/checklists/checklists_view.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(controller.currentHouse?.name ?? 'Pantry'),
        actions: [
          _UserMenuButton(
            houses: controller.houses,
            currentHouse: controller.currentHouse,
            avatarBytes: AuthService.instance.avatarBytes,
            onHouseSelected: controller.selectHouse,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      body: _buildBody(controller),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in),
            label: 'Checklists',
          ),
          NavigationDestination(icon: Icon(Icons.photo), label: 'Photo Board'),
          NavigationDestination(
            icon: Icon(Icons.insert_drive_file),
            label: 'Notes Wall',
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
                child: const Text('Retry'),
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
        return const Center(child: Text('Photo Board'));
      case 2:
        return const Center(child: Text('Notes Wall'));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _UserMenuButton extends StatelessWidget {
  final List<House> houses;
  final House? currentHouse;
  final Uint8List? avatarBytes;
  final ValueChanged<House> onHouseSelected;
  final VoidCallback onLogout;

  const _UserMenuButton({
    required this.houses,
    required this.currentHouse,
    required this.avatarBytes,
    required this.onHouseSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final loginName = AuthService.instance.credentials?.loginName ?? '';

    return PopupMenuButton<Object>(
      offset: const Offset(0, 48),
      tooltip: loginName,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: avatarBytes != null
            ? CircleAvatar(
                radius: 16,
                backgroundImage: MemoryImage(avatarBytes!),
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
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Logout'),
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
