import 'package:flutter/material.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/widgets/avif_image.dart';

import 'wear_surfaces.dart';

/// An image the server renders on request, at the size the surface drawing it
/// asked for.
///
/// [source] is called rather than passed because a preview URL is built from
/// the server the credentials name, so without them there is no address to ask
/// — the URI builders throw rather than returning nothing. A page cached from a
/// previous session outlives the credentials that fetched it, and it degrades
/// to placeholders like any other image the watch cannot reach.
class PreviewImage extends StatelessWidget {
  final Uri Function() source;
  final BoxFit fit;

  /// What to draw when the bytes are neither on disk nor reachable. An image
  /// keeps its slot rather than dropping out of the layout, so on a surface
  /// where that matters this is never nothing.
  final Widget? unavailable;

  const PreviewImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.unavailable,
  });

  @override
  Widget build(BuildContext context) {
    final credentials = AuthService.instance.credentials;
    if (credentials == null) return unavailable ?? const SizedBox.shrink();
    return AvifNetworkImage(
      imageUrl: source().toString(),
      headers: credentials.basicAuthHeaders,
      fit: fit,
      errorWidget: unavailable ?? const SizedBox.shrink(),
    );
  }
}

/// An image whose bytes are not on disk and cannot be fetched.
///
/// It is deliberately the size of the slot it replaces: hiding an unavailable
/// photo would move every tile after it between online and offline, so "the
/// paint colour is the third one" would stop being true exactly when the
/// wearer is least able to go looking.
class ImageUnavailable extends StatelessWidget {
  const ImageUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface.withValues(alpha: 0.28);
    return DecoratedBox(
      decoration: WearSurface.placeholder(context, radius: 0),
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
