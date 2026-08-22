import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';

import '../utils/platform_info.dart';

/// A request to open a specific list, produced by an OS-level entry point: a
/// `pantry://list/<houseId>/<listId>` URL (NFC tags, automation apps, browser
/// links), a launcher quick action, or a pinned home-screen shortcut.
class ListLink {
  final int listId;
  final int? houseId;

  const ListLink({required this.listId, this.houseId});

  static const scheme = 'pantry';
  static const host = 'list';

  /// The canonical deep-link URL for [listId] in [houseId].
  static Uri uri(int houseId, int listId) =>
      Uri.parse('$scheme://$host/$houseId/$listId');

  /// Parse `pantry://list/<houseId>/<listId>` (or `pantry://list/<listId>`).
  /// Returns null when the URI isn't a well-formed list link.
  static ListLink? fromUri(Uri uri) {
    if (uri.scheme != scheme || uri.host != host) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
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

/// Resolves OS-level requests to open a specific list. Owns the custom URL
/// scheme (`app_links`), launcher quick actions (`quick_actions`) and the
/// native pinned home-screen shortcut channel. The home view observes
/// [pending] and navigates when a request lands.
class ListLinkService {
  ListLinkService._();
  static final ListLinkService instance = ListLinkService._();

  static const _shortcutChannel = MethodChannel('dev.casraf.pantry/shortcuts');

  final ValueNotifier<ListLink?> pending = ValueNotifier(null);

  AppLinks? _appLinks;
  final QuickActions _quickActions = const QuickActions();

  Future<void> init() async {
    if (!PlatformInfo.isMobile) return;
    _appLinks = AppLinks();
    // Links that arrive while the app is already running. The singleton lives
    // for the app's lifetime, so the subscription is never cancelled.
    _appLinks!.uriLinkStream.listen(_handleUri, onError: (_) {});
    // The URL that cold-started the app, if any.
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}
    _quickActions.initialize((type) {
      final link = ListLink.fromQuickActionType(type);
      if (link != null) pending.value = link;
    });
  }

  void _handleUri(Uri uri) {
    final link = ListLink.fromUri(uri);
    if (link != null) pending.value = link;
  }

  /// Publish the pinned lists as launcher quick actions (long-press the app
  /// icon). [entries] carries `{id, name, houseId}` per pinned list. Android
  /// caps the visible count, so only the first few appear.
  Future<void> setPinnedShortcuts(List<Map<String, dynamic>> entries) async {
    if (!PlatformInfo.isMobile) return;
    final items = <ShortcutItem>[
      for (final e in entries)
        if (e['id'] is int && e['houseId'] is int)
          ShortcutItem(
            type: ListLink.quickActionType(e['houseId'] as int, e['id'] as int),
            localizedTitle: (e['name'] as String?) ?? '',
          ),
    ];
    try {
      await _quickActions.setShortcutItems(items);
    } catch (_) {}
  }

  /// Ask the launcher to pin a home-screen icon that opens [listId] in
  /// [houseId]. Android only; returns false when the launcher doesn't
  /// support pinning.
  Future<bool> pinListToHomeScreen({
    required int houseId,
    required int listId,
    required String name,
  }) async {
    if (!PlatformInfo.isAndroid) return false;
    try {
      final ok = await _shortcutChannel.invokeMethod<bool>('pinListShortcut', {
        'houseId': houseId,
        'listId': listId,
        'name': name,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
