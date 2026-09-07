import 'package:flutter/foundation.dart';
import 'package:pantry_core/models/notification.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry_core/services/notification_service.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController();

  List<NcNotification> _notifications = [];
  List<NcNotification> get notifications => _notifications;

  int get unreadCount => _notifications.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Token for the list in [_notifications], so a refresh that finds nothing
  /// changed costs a request with no body. Only ever sent alongside the list it
  /// describes — a controller that has just been built holds neither.
  String? _etag;

  Future<void> load() async {
    _error = null;
    if (_notifications.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final changed = await _fetch();
      _isLoading = false;
      notifyListeners();
      if (changed) await _markAllSeen();
    } catch (e) {
      debugPrint('[NotificationsController] Failed to load: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      if (await _fetch()) {
        notifyListeners();
        await _markAllSeen();
      }
    } catch (e) {
      debugPrint('[NotificationsController] Failed to refresh: $e');
    }
  }

  /// Returns whether the list moved — false means the server confirmed the one
  /// already held, so there is nothing to repaint or mark seen.
  Future<bool> _fetch() async {
    final fetch = await NotificationService.instance.getNotifications(
      etag: _etag,
    );
    _etag = fetch.etag;
    if (fetch.unchanged) return false;
    _notifications = fetch.notifications;
    return true;
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
    // The held list no longer matches what the token describes, and a dismissal
    // the server rejected would otherwise stay hidden behind a `304`.
    _etag = null;
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
    _etag = null;
    notifyListeners();
    try {
      await NotificationService.instance.dismissAll(ids);
    } catch (e) {
      debugPrint('[NotificationsController] Failed to dismiss all: $e');
    }
  }
}
