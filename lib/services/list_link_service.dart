import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:pantry_core/models/list_link.dart';
import 'package:pantry_core/utils/platform_info.dart';

export 'package:pantry_core/models/list_link.dart';

/// Resolves OS-level requests to open a specific list. Owns the custom URL
/// scheme (`app_links`), launcher quick actions (`quick_actions`) and the
/// native pinned home-screen shortcut channel. The home view observes
/// [pending] and navigates when a request lands.
class ListLinkService {
  ListLinkService._();
  static final ListLinkService instance = ListLinkService._();

  static const _shortcutChannel = MethodChannel('dev.casraf.pantry/shortcuts');

  final ValueNotifier<ListLink?> pending = ValueNotifier(null);

  /// A watch asking this phone to open its pairing screen. It arrives on the
  /// same `pantry://` scheme and therefore through the same subscription, so
  /// it is answered here rather than by a second `app_links` reader — two
  /// would each open their own stream over one messenger.
  final ValueNotifier<bool> pendingWatchSetup = ValueNotifier(false);

  static const _watchSetupHost = 'watch-setup';

  AppLinks? _appLinks;
  final QuickActions _quickActions = const QuickActions();

  Future<void> init() async {
    if (!PlatformInfo.isMobile) return;
    _appLinks = AppLinks();
    // Every link, the one that cold-started the app included: the plugin holds
    // the launch URI and hands it to the first subscriber. Asking for it again
    // with `getInitialLink` is what delivered it twice — and a request to open
    // something, answered twice, opens it twice.
    //
    // The singleton lives for the app's lifetime, so the subscription is never
    // cancelled and there is never a second subscriber to miss the replay.
    _appLinks!.uriLinkStream.listen(_handleUri, onError: (_) {});
    _quickActions.initialize((type) {
      final link = ListLink.fromQuickActionType(type);
      if (link != null) pending.value = link;
    });
  }

  void _handleUri(Uri uri) {
    if (uri.scheme == ListLink.scheme && uri.host == _watchSetupHost) {
      pendingWatchSetup.value = true;
      return;
    }
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
    if (!PlatformInfo.isAndroidPhone) return false;
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
