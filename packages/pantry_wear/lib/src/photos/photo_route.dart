import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/image_route.dart';
import '../widgets/preview_image.dart';
import '../widgets/preview_sizes.dart';
import '../widgets/wear_mechanics.dart';
import 'photo_detail_page.dart';
import 'photo_image.dart';

/// One photo off the board, full screen and zoomable.
///
/// A press and hold opens what else is known about it, the same gesture that
/// reaches the detail page from the tile.
class PhotoRoute extends StatefulWidget {
  final Photo photo;
  final int houseId;

  const PhotoRoute({super.key, required this.photo, required this.houseId});

  @override
  State<PhotoRoute> createState() => _PhotoRouteState();
}

class _PhotoRouteState extends State<PhotoRoute> {
  /// The detail page must take the crown with it: the detent stream is
  /// broadcast and this route stays mounted underneath, so without this one
  /// turn zooms the photo behind the page being read.
  var _covered = false;

  Future<void> _openDetail() async {
    setState(() => _covered = true);
    await Navigator.of(context).push(
      wearRoute<void>(
        PhotoDetailPage(
          photo: widget.photo,
          houseId: widget.houseId,
          onPreviewTap: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(() => _covered = false);
  }

  @override
  Widget build(BuildContext context) => ImageRoute(
    image: (context, size) => PhotoImage(
      photo: widget.photo,
      houseId: widget.houseId,
      size: size,
      fit: BoxFit.contain,
      unavailable: const ImageUnavailable(),
    ),
    cached: WearPreviewSize.tile,
    caption: _Meta(photo: widget.photo),
    onLongPress: () => unawaited(_openDetail()),
    rotary: !_covered,
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
