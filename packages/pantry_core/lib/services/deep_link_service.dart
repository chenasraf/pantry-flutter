import 'package:flutter/foundation.dart';

/// A deferred navigation intent produced by a notification tap. The home
/// view consumes these and switches to the correct tab + house.
class DeepLink {
  /// 0 = checklists, 1 = photos, 2 = notes
  final int tabIndex;
  final int? houseId;

  /// When both are set (a checklists deep link), the target list is preselected
  /// and its item is opened once loaded — used by custom-field date reminders.
  final int? listId;
  final int? itemId;

  const DeepLink({
    required this.tabIndex,
    this.houseId,
    this.listId,
    this.itemId,
  });

  /// Serialize to a compact string for notification payloads.
  String encode() =>
      '$tabIndex:${houseId ?? ''}:${listId ?? ''}:${itemId ?? ''}';

  /// Parse a payload string. Returns null if invalid. Tolerates the older
  /// two-field form (`tab:house`) so payloads already scheduled still decode.
  static DeepLink? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split(':');
    if (parts.isEmpty) return null;
    final tab = int.tryParse(parts[0]);
    if (tab == null || tab < 0 || tab > 2) return null;
    int? at(int i) =>
        parts.length > i && parts[i].isNotEmpty ? int.tryParse(parts[i]) : null;
    return DeepLink(
      tabIndex: tab,
      houseId: at(1),
      listId: at(2),
      itemId: at(3),
    );
  }
}

/// Singleton holding the most recent pending deep link. The home view
/// observes [pending] via [ValueListenable] and consumes it on navigation.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final ValueNotifier<DeepLink?> pending = ValueNotifier(null);

  /// Schedule a deep link. Called from notification tap handlers.
  void push(DeepLink link) {
    pending.value = link;
  }

  /// Consume (and clear) the current pending link. Returns null if none.
  DeepLink? consume() {
    final link = pending.value;
    pending.value = null;
    return link;
  }
}
