import 'package:flutter/material.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/photo_service.dart';

import '../widgets/preview_image.dart';

/// A photo off the household board, at the size the surface drawing it needs.
///
/// [size] is what the preview endpoint is asked for, not what the box is: the
/// server downscales, and asking twice for the same photo at two sizes is two
/// files on a watch that keeps only what the wearer looked at.
class PhotoImage extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final int size;
  final BoxFit fit;
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
  Widget build(BuildContext context) => PreviewImage(
    source: () =>
        PhotoService.instance.photoPreviewUri(houseId, photo.id, size: size),
    fit: fit,
    unavailable: unavailable,
  );
}
