import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/auth_service.dart';

class UserMenuButton extends StatelessWidget {
  final List<House> houses;
  final House? currentHouse;
  final ValueChanged<House> onHouseSelected;
  final VoidCallback onCreateHouse;
  final VoidCallback onLogout;

  const UserMenuButton({
    super.key,
    required this.houses,
    required this.currentHouse,
    required this.onHouseSelected,
    required this.onCreateHouse,
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
          value: 'create_house',
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text(m.home.createHouse),
            ],
          ),
        ),
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
        } else if (value == 'create_house') {
          onCreateHouse();
        } else if (value == 'logout') {
          onLogout();
        }
      },
    );
  }
}
