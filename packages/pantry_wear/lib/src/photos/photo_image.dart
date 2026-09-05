import 'package:flutter/material.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/widgets/avif_image.dart';

/// A photo, at the size the surface drawing it needs.
///
/// [size] is what the preview endpoint is asked for, not what the box is: the
/// server downscales, and asking twice for the same photo at two sizes is two
/// files on a watch that keeps only what the wearer looked at.
class PhotoImage extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final int size;
  final BoxFit fit;

  /// What to draw when the bytes are neither on disk nor reachable. A photo
  /// keeps its slot rather than dropping out of the grid, so this is never
  /// nothing.
  final Widget? unavailable;

  const PhotoImage({
    super.key,
    required this.photo,
    required this.houseId,
    required this.size,
    this.fit = BoxFit.cover,
    this.unavailable,
  });

  @override
  Widget build(BuildContext context) {
    final credentials = AuthService.instance.credentials;
    // A preview URL is built from the server the credentials name, so without
    // them there is no address to ask — `photoPreviewUri` throws rather than
    // returning nothing. A board cached from a previous session outlives the
    // credentials that fetched it, and it degrades to placeholders like any
    // other photo the watch cannot reach.
    if (credentials == null) return unavailable ?? const SizedBox.shrink();
    return AvifNetworkImage(
      imageUrl: PhotoService.instance
          .photoPreviewUri(houseId, photo.id, size: size)
          .toString(),
      headers: credentials.basicAuthHeaders,
      fit: fit,
      errorWidget: unavailable ?? const SizedBox.shrink(),
    );
  }
}

/// A photo whose bytes are not on disk and cannot be fetched.
///
/// It is deliberately the size of the tile it replaces: hiding an unavailable
/// photo would move every tile after it between online and offline, so "the
/// paint colour is the third one" would stop being true exactly when the
/// wearer is least able to go looking.
class PhotoUnavailable extends StatelessWidget {
  const PhotoUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface.withValues(alpha: 0.28);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.07),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.image_outlined, size: 22, color: ink)),
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Icon(Icons.cloud_off_outlined, size: 11, color: ink),
          ),
        ],
      ),
    );
  }
}
