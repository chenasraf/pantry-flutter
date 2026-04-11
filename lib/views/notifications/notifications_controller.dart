import 'package:flutter/foundation.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/notification_service.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController();

  List<NcNotification> _notifications = [];
  List<NcNotification> get notifications => _notifications;

  int get unreadCount => _notifications.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _error = null;
    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _notifications = await NotificationService.instance.getNotifications();
      _isLoading = false;
      notifyListeners();
      await _markAllSeen();
    } catch (e) {
      debugPrint('[NotificationsController] Failed to load: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      _notifications = await NotificationService.instance.getNotifications();
      notifyListeners();
      await _markAllSeen();
    } catch (e) {
      debugPrint('[NotificationsController] Failed to refresh: $e');
    }
  }

  Future<void> _markAllSeen() async {
    final ids = _notifications.map((n) => n.notificationId).toList();
    try {
      await markCurrentNotificationsAsSeen(ids);
    } catch (e) {
      debugPrint('[NotificationsController] Failed to mark seen: $e');
    }
  }

  Future<void> dismiss(NcNotification notification) async {
    _notifications = _notifications
        .where((n) => n.notificationId != notification.notificationId)
        .toList();
    notifyListeners();
    try {
      await NotificationService.instance.dismiss(notification.notificationId);
    } catch (e) {
      debugPrint('[NotificationsController] Failed to dismiss: $e');
    }
  }

  Future<void> dismissAll() async {
    final ids = _notifications.map((n) => n.notificationId).toList();
    _notifications = [];
    notifyListeners();
    try {
      await NotificationService.instance.dismissAll(ids);
    } catch (e) {
      debugPrint('[NotificationsController] Failed to dismiss all: $e');
    }
  }
}
