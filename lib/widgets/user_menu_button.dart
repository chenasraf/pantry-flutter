import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/views/about/about_view.dart';

class UserMenuButton extends StatelessWidget {
  final List<House> houses;
  final House? currentHouse;
  final ValueChanged<House> onHouseSelected;
  final VoidCallback onCreateHouse;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  const UserMenuButton({
    super.key,
    required this.houses,
    required this.currentHouse,
    required this.onHouseSelected,
    required this.onCreateHouse,
    required this.onOpenSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final creds = AuthService.instance.credentials;
    final loginName = creds?.loginName ?? '';
    final displayName = AuthService.instance.displayName ?? loginName;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarPath = isDark
        ? 'index.php/avatar/$loginName/128/dark'
        : 'index.php/avatar/$loginName/128';

    final avatar = creds != null
        ? CachedNetworkImage(
            imageUrl: '${creds.serverUrl}/$avatarPath',
            httpHeaders: creds.basicAuthHeaders,
            imageBuilder: (_, imageProvider) =>
                CircleAvatar(radius: 18, backgroundImage: imageProvider),
            errorWidget: (_, _, _) => const CircleAvatar(
              radius: 18,
              child: Icon(Icons.person, size: 22),
            ),
            placeholder: (_, _) => const CircleAvatar(
              radius: 18,
              child: Icon(Icons.person, size: 22),
            ),
          )
        : const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 22));

    return IconButton(
      onPressed: () => _showMenu(context, displayName, loginName, avatar),
      icon: avatar,
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    String displayName,
    String loginName,
    Widget avatar,
  ) async {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu<Object>(
      context: context,
      position: position,
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                SizedBox(width: 40, height: 40, child: avatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        loginName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                      color: theme.colorScheme.primary,
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
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 18),
              const SizedBox(width: 8),
              Text(m.settings.title),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'about',
          child: Row(
            children: [
              const Icon(Icons.info_outlined, size: 18),
              const SizedBox(width: 8),
              Text(m.about.title),
            ],
          ),
        ),
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
    );

    if (value is House) {
      onHouseSelected(value);
    } else if (value == 'create_house') {
      onCreateHouse();
    } else if (value == 'settings') {
      onOpenSettings();
    } else if (value == 'about') {
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AboutView()));
      }
    } else if (value == 'logout') {
      onLogout();
    }
  }
}
