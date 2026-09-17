import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/models/photo_link.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../widgets/image_route.dart';
import '../widgets/preview_image.dart';
import '../widgets/preview_sizes.dart';
import '../widgets/wear_detail.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_scroll_indicator.dart';
import '../widgets/wear_surfaces.dart';
import 'photo_image.dart';

/// What is known about one photo on the board, and the hand-off to the phone.
///
/// The board itself answers "which photo", and the viewer answers "what does
/// it show" — neither says who put it there or when, and on a shared household
/// board that is often the question. It is reached by a press and hold, from
/// the tile and from the viewer alike, the same gesture that opens an item's
/// details from a checklist row.
class PhotoDetailPage extends StatelessWidget {
  final Photo photo;
  final int houseId;

  /// What a tap on the preview does. The viewer is one of the two ways here,
  /// and from there the photo is the screen underneath — so it goes back to it
  /// rather than stacking a second copy of it on top.
  final VoidCallback? onPreviewTap;

  const PhotoDetailPage({
    super.key,
    required this.photo,
    required this.houseId,
    this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      // Route (a) turns off the system dismiss app-wide, so a pushed route
      // that does not carry this strip has no way back at all.
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: WearScrollIndicator(
          child: ListView(
            padding: WearMetrics.bandInsets(context),
            children: [
              _Thumbnail(photo: photo, houseId: houseId, onTap: onPreviewTap),
              const SizedBox(height: 12),
              if (caption != null && caption.isNotEmpty) ...[
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(caption),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              WearFact(
                label: m.wear.addedBy,
                value: EntityChip(
                  textColor: kDetailInk,
                  label: photo.uploadedBy,
                  leading: const Icon(
                    Icons.person,
                    size: 12,
                    color: kDetailInk,
                  ),
                ),
              ),
              // The relative time is the one read at a glance; the exact moment
              // under it is the one that tells two days of the same week apart.
              WearFact(
                label: m.wear.added,
                value: EntityChip(
                  textColor: kDetailInk,
                  label: relativeTime(photo.createdAt),
                ),
                note: formatDateTime(photo.createdAt),
              ),
              const SizedBox(height: 16),
              OpenOnPhoneButton(
                url: PhotoLink.uri(houseId, photo.id).toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo, over what the page has to say about it.
///
/// Square and well short of the full width, for the reason an item's thumbnail
/// is: this is the top of a scroll, which on a round screen is the narrowest
/// the glass gets, and a first screenful that is all photo has buried the facts
/// the wearer came here for. A tap gives it the whole screen again.
class _Thumbnail extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final VoidCallback? onTap;

  const _Thumbnail({required this.photo, required this.houseId, this.onTap});

  static double _side(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.55;

  Widget _image(BuildContext context, int size, BoxFit fit) => PhotoImage(
    photo: photo,
    houseId: houseId,
    size: size,
    fit: fit,
    unavailable: const ImageUnavailable(),
  );

  void _open(BuildContext context) {
    Navigator.of(context).push(
      wearRoute<void>(
        ImageRoute(
          image: (context, size) => _image(context, size, BoxFit.contain),
          cached: (context) =>
              WearPreviewSize.forWidth(context, _side(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final side = _side(context);
    return Center(
      child: GestureDetector(
        onTap: onTap ?? () => _open(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WearSurface.panelRadius),
          child: SizedBox.square(
            dimension: side,
            child: _image(
              context,
              WearPreviewSize.forWidth(context, side),
              BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
