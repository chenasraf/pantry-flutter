import 'package:flutter/material.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/image_route.dart';
import '../widgets/preview_image.dart';
import '../widgets/preview_sizes.dart';
import 'photo_image.dart';

/// One photo off the board, full screen and zoomable.
class PhotoRoute extends StatelessWidget {
  final Photo photo;
  final int houseId;

  const PhotoRoute({super.key, required this.photo, required this.houseId});

  @override
  Widget build(BuildContext context) => ImageRoute(
    image: (context, size) => PhotoImage(
      photo: photo,
      houseId: houseId,
      size: size,
      fit: BoxFit.contain,
      unavailable: const ImageUnavailable(),
    ),
    cached: WearPreviewSize.tile,
    caption: _Meta(photo: photo),
  );
}

/// Caption, who added it and when.
///
/// The phone shows none of this — its detail view carries the caption alone —
/// but on a shared household board "Dana, Tuesday" is often the thing that
/// tells two similar photos apart, and a pushed route has the room.
class _Meta extends StatelessWidget {
  final Photo photo;

  const _Meta({required this.photo});

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption;
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: 22,
        end: 22,
        top: 16,
        bottom: WearShape.isRound ? 24 : 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (caption != null && caption.isNotEmpty) ...[
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textDirection: detectTextDirection(caption),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '${photo.uploadedBy} · ${relativeTime(photo.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.2,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
