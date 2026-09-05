/// A request to open a specific list, produced by an OS-level entry point: a
/// `pantry://list/<houseId>/<listId>` URL (NFC tags, automation apps, browser
/// links), a launcher quick action, a pinned home-screen shortcut, or the
/// watch's list Tile.
///
/// The grammar lives in core because two surfaces emit and read it — the
/// phone's `ListLinkService` and the watch's `WearDeepLink` — and a second
/// parser would drift from the first. The Tile is the case that forces it: a
/// ProtoLayout `LaunchAction` cannot carry a URI, so the watch activity
/// rebuilds one from intent extras and both halves have to agree on the shape
/// down to the segment order.
class ListLink {
  final int listId;
  final int? houseId;

  /// When set, open this item's detail after opening the list.
  final int? itemId;

  const ListLink({required this.listId, this.houseId, this.itemId});

  static const scheme = 'pantry';
  static const host = 'list';
  static const itemHost = 'item';

  /// The canonical deep-link URL for [listId] in [houseId].
  static Uri uri(int houseId, int listId) =>
      Uri.parse('$scheme://$host/$houseId/$listId');

  /// The canonical deep-link URL for [itemId] in [listId] / [houseId].
  static Uri itemUri(int houseId, int listId, int itemId) =>
      Uri.parse('$scheme://$itemHost/$houseId/$listId/$itemId');

  /// Parse `pantry://list/<houseId>/<listId>` (or `pantry://list/<listId>`), or
  /// `pantry://item/<houseId>/<listId>/<itemId>`. Null if not well-formed.
  static ListLink? fromUri(Uri uri) {
    if (uri.scheme != scheme) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (uri.host == itemHost) {
      if (segments.length < 3) return null;
      final houseId = int.tryParse(segments[0]);
      final listId = int.tryParse(segments[1]);
      final itemId = int.tryParse(segments[2]);
      if (listId == null || itemId == null) return null;
      return ListLink(listId: listId, houseId: houseId, itemId: itemId);
    }
    if (uri.host != host) return null;
    if (segments.isEmpty) return null;
    if (segments.length == 1) {
      final listId = int.tryParse(segments[0]);
      return listId == null ? null : ListLink(listId: listId);
    }
    final houseId = int.tryParse(segments[0]);
    final listId = int.tryParse(segments[1]);
    return listId == null ? null : ListLink(listId: listId, houseId: houseId);
  }

  static String quickActionType(int houseId, int listId) =>
      'list:$houseId:$listId';

  /// Parse a quick-action type string `list:<houseId>:<listId>`.
  static ListLink? fromQuickActionType(String type) {
    final parts = type.split(':');
    if (parts.length != 3 || parts[0] != 'list') return null;
    final houseId = int.tryParse(parts[1]);
    final listId = int.tryParse(parts[2]);
    return listId == null ? null : ListLink(listId: listId, houseId: houseId);
  }
}
