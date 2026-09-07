import 'package:flutter/foundation.dart';
import 'package:pantry_core/models/notification.dart';
import 'package:pantry_core/services/api_client.dart';

/// One poll of the notifications endpoint.
class NotificationFetch {
  final List<NcNotification> notifications;

  /// Hand back to [NotificationService.getNotifications] next time to let the
  /// server skip the download. Null when it offered no token.
  final String? etag;

  /// The server answered `304`: whatever the caller held when it sent [etag]
  /// is still current, and [notifications] is empty because nothing was
  /// downloaded — not because there is nothing there.
  final bool unchanged;

  const NotificationFetch({
    this.notifications = const [],
    this.etag,
    this.unchanged = false,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _client = ApiClient(
    basePath: '/ocs/v2.php/apps/notifications/api/v2',
  );

  /// Fetch all notifications, filtered to this app only.
  ///
  /// Pass the [etag] from the previous fetch to poll conditionally: an
  /// unchanged list costs a request with no body, which is what the background
  /// poll finds nearly every time it runs.
  Future<NotificationFetch> getNotifications({String? etag}) async {
    try {
      final response = await _client.getConditional<List, List<NcNotification>>(
        '/notifications',
        etag: etag,
        fromJson: (data) => data
            .map((e) => NcNotification.fromJson(e as Map<String, dynamic>))
            .where((n) => n.app == 'pantry')
            .toList(),
      );
      return NotificationFetch(
        notifications: response.data ?? const [],
        etag: response.etag,
        unchanged: response.outcome == ConditionalOutcome.unchanged,
      );
    } on ApiException catch (e) {
      // Notifications app not installed / disabled
      if (e.statusCode == 404) return const NotificationFetch();
      rethrow;
    }
  }

  /// Delete (mark as read) a single notification.
  Future<void> dismiss(int notificationId) async {
    try {
      await _client.delete('/notifications/$notificationId');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return; // already gone
      rethrow;
    }
  }

  /// Delete all given notifications.
  Future<void> dismissAll(List<int> ids) async {
    for (final id in ids) {
      try {
        await dismiss(id);
      } catch (e) {
        debugPrint('[NotificationService] Failed to dismiss $id: $e');
      }
    }
  }
}
