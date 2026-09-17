/// A request to open one photo off the household board, produced by an
/// OS-level entry point: a `pantry://photo/<houseId>/<photoId>` URL, or the
/// watch handing this phone the photo the wearer is looking at.
///
/// The grammar lives in core because two surfaces touch it — the phone's
/// `ListLinkService` reads it and the watch's photo detail page writes it —
/// and a second spelling would drift from the first.
class PhotoLink {
  final int houseId;
  final int photoId;

  const PhotoLink({required this.houseId, required this.photoId});

  static const scheme = 'pantry';
  static const host = 'photo';

  /// The canonical deep-link URL for [photoId] in [houseId].
  static Uri uri(int houseId, int photoId) =>
      Uri.parse('$scheme://$host/$houseId/$photoId');

  /// Parse `pantry://photo/<houseId>/<photoId>`. Null if not well-formed.
  ///
  /// The house is required where a list link's is optional: a photo id is
  /// unique to its house and there is no selected-board fallback to land on.
  static PhotoLink? fromUri(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    final houseId = int.tryParse(segments[0]);
    final photoId = int.tryParse(segments[1]);
    if (houseId == null || photoId == null) return null;
    return PhotoLink(houseId: houseId, photoId: photoId);
  }
}
