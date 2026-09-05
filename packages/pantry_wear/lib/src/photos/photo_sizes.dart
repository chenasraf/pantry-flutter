import 'package:flutter/widgets.dart';

import '../widgets/wear_metrics.dart';

/// What `size` the watch asks the preview endpoint for.
///
/// The server clamps `size` to 16–2048 and downscales a Nextcloud-generated
/// preview, so the watch asks for what it is about to draw rather than pulling
/// a full-size image and shrinking it. Every figure here is therefore derived
/// from the screen it lands on, not carried as a constant: the reference watch
/// is 480 device pixels across, and another Wear screen is not.
///
/// Requests snap to powers of two. A tile's box moves by a fraction of a pixel
/// as the focus falloff scales it, and an exact request would make each of
/// those a separate URL, a separate fetch and a separate cache entry — three
/// rungs is what the whole page needs.
class WearPreviewSize {
  const WearPreviewSize._();

  /// The endpoint's own clamp. Asking beyond it just gets this back.
  static const int max = 2048;

  /// Below this a preview is cheaper to fetch than to think about.
  static const int min = 64;

  /// What a photo is drawn at while it is being read. Nothing between fit and
  /// this is worth a rung: the wearer either glanced at the photo or is
  /// zoomed into it looking for a lock code.
  static const int zoomed = max;

  static int _rung(double devicePixels) {
    var size = min;
    while (size < devicePixels && size < max) {
      size *= 2;
    }
    return size;
  }

  /// A tile in a two-up row.
  ///
  /// Measured from the screen rather than the tile's own box: the box shrinks
  /// with distance from the centre line, and a request that followed it would
  /// re-fetch every row on every scroll.
  static int tile(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final usable = width * (1 - 2 * WearMetrics.tallSideInset);
    final tileWidth = (usable - WearMetrics.photoTileGap) / 2;
    return _rung(tileWidth * MediaQuery.devicePixelRatioOf(context));
  }

  /// A photo filling the screen, before the wearer zooms.
  static int fit(BuildContext context) => _rung(
    MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context),
  );
}
