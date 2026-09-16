import 'package:flutter/material.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/avif_image.dart';

/// A housemate's face, or the initial of their name when there is no face to
/// draw.
///
/// The initial is not a placeholder waiting for bytes — it is the answer
/// whenever the avatar cannot be reached, which on a watch is most of the time
/// a wearer is out of range of their phone. It carries the same diameter and
/// the same ring either way, so a stack of them keeps its geometry between
/// online and offline.
class WearAvatar extends StatelessWidget {
  final String userId;
  final String displayName;
  final double size;

  const WearAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final credentials = AuthService.instance.credentials;
    final initial = _initial;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2A2A30),
      ),
      child: Center(
        child: Text(
          initial,
          textDirection: detectTextDirection(initial),
          style: TextStyle(
            fontSize: size * 0.46,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: credentials == null || userId.isEmpty
          ? fallback
          : ClipOval(
              child: AvifNetworkImage(
                // The watch is always on the dark ground, so the avatar the
                // server renders for it is too.
                imageUrl:
                    '${credentials.serverUrl}/index.php/avatar/$userId/128/dark',
                headers: credentials.basicAuthHeaders,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorWidget: fallback,
              ),
            ),
    );
  }

  String get _initial {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    return name.characters.first.toUpperCase();
  }
}

/// Up to [max] faces, overlapping, in the order they were given.
///
/// Anyone past [max] is dropped rather than counted off in a "+2" bubble: the
/// row that carries the stack already names the trip's members, and a second
/// tally on a watch-sized card reads as another person rather than as a total.
class WearAvatarStack extends StatelessWidget {
  final List<({String userId, String displayName})> members;
  final double size;
  final int max;

  const WearAvatarStack({
    super.key,
    required this.members,
    this.size = 22,
    this.max = 3,
  });

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final overlap = size * 0.62;
    return SizedBox(
      width: size + (shown.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * overlap,
              child: DecoratedBox(
                // The ring is what keeps two faces from reading as one shape
                // where they overlap.
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B0B0C),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: WearAvatar(
                    userId: shown[i].userId,
                    displayName: shown[i].displayName,
                    size: size - 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
