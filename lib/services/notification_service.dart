import 'package:flutter/foundation.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/services/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _client = ApiClient(
    basePath: '/ocs/v2.php/apps/notifications/api/v2',
  );

  /// Fetch all notifications, filtered to this app only.
  Future<List<NcNotification>> getNotifications() async {
    try {
      return await _client.get<List, List<NcNotification>>(
        '/notifications',
        fromJson: (data) => data
            .map((e) => NcNotification.fromJson(e as Map<String, dynamic>))
            .where((n) => n.app == 'pantry')
            .toList(),
      );
    } on ApiException catch (e) {
      // Notifications app not installed / disabled
      if (e.statusCode == 404) return [];
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
