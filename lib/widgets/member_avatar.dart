import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/services/auth_service.dart';

/// Circular avatar for a Nextcloud user. Falls back to a colored circle with
/// the user's initial when the avatar can't be fetched (no credentials, user
/// has none configured, offline, etc).
class MemberAvatar extends StatelessWidget {
  final String? userId;
  final String displayName;
  final double size;

  const MemberAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = displayName.isNotEmpty
        ? displayName.characters.first.toUpperCase()
        : '?';

    final creds = AuthService.instance.credentials;
    final brightness = Theme.of(context).brightness;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
    );

    if (creds == null || userId == null || userId!.isEmpty) {
      return placeholder;
    }

    final avatarPath = brightness == Brightness.dark
        ? 'index.php/avatar/$userId/128/dark'
        : 'index.php/avatar/$userId/128';
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: '${creds.serverUrl}/$avatarPath',
          httpHeaders: creds.basicAuthHeaders,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => placeholder,
          placeholder: (_, _) => placeholder,
        ),
      ),
    );
  }
}
