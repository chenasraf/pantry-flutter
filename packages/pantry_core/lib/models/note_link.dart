/// A request to open one note off the household wall, produced by an OS-level
/// entry point: a `pantry://note/<houseId>/<noteId>` URL, or the watch handing
/// this phone the note the wearer is reading.
///
/// The grammar lives in core because two surfaces touch it — the phone's
/// `ListLinkService` reads it and the watch's note detail page writes it — and
/// a second spelling would drift from the first.
class NoteLink {
  final int houseId;
  final int noteId;

  const NoteLink({required this.houseId, required this.noteId});

  static const scheme = 'pantry';
  static const host = 'note';

  /// The canonical deep-link URL for [noteId] in [houseId].
  static Uri uri(int houseId, int noteId) =>
      Uri.parse('$scheme://$host/$houseId/$noteId');

  /// Parse `pantry://note/<houseId>/<noteId>`. Null if not well-formed.
  ///
  /// The house is required where a list link's is optional: a note id is
  /// unique to its house and there is no selected-wall fallback to land on.
  static NoteLink? fromUri(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    final houseId = int.tryParse(segments[0]);
    final noteId = int.tryParse(segments[1]);
    if (houseId == null || noteId == null) return null;
    return NoteLink(houseId: houseId, noteId: noteId);
  }
}
