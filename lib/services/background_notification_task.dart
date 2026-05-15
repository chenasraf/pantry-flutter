import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/deep_link_service.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/notification_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:workmanager/workmanager.dart';

/// Unique name for the periodic notification poll task.
const notificationPollTaskName = 'pantry-notification-poll';

/// Secure storage key used to persist which notification IDs we've
/// already shown as local notifications (to avoid re-notifying).
const _seenIdsKey = 'seen_notification_ids';

/// Top-level function required by workmanager. Must be annotated
/// `@pragma('vm:entry-point')` so tree-shaking doesn't strip it.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != notificationPollTaskName) return true;
    try {
      await _pollAndNotify();
    } catch (e) {
      debugPrint('[bg-notify] task failed: $e');
    }
    return true;
  });
}

Future<void> _pollAndNotify() async {
  // In a background isolate, AuthService and PrefsService are fresh
  // instances — load credentials + user prefs.
  await AuthService.instance.loadCredentials();
  if (!AuthService.instance.isLoggedIn) return;

  await PrefsService.instance.load();
  if (!PrefsService.instance.notificationsEnabled) return;

  final notifications = await NotificationService.instance.getNotifications();
  if (notifications.isEmpty) return;

  // Compare against stored seen IDs.
  const storage = FlutterSecureStorage();
  final seenRaw = await storage.read(key: _seenIdsKey);
  final seen = seenRaw == null || seenRaw.isEmpty
      ? <int>{}
      : seenRaw.split(',').map(int.parse).toSet();

  final newOnes = notifications
      .where((n) => !seen.contains(n.notificationId))
      .toList();

  if (newOnes.isEmpty) return;

  await LocalNotificationsService.instance.init();

  for (final n in newOnes) {
    await LocalNotificationsService.instance.show(
      id: n.notificationId,
      title: n.subject,
      body: n.message.isNotEmpty ? n.message : null,
      payload: _payloadFor(n),
    );
  }

  // Persist the current set of IDs (drop stale entries — keep only what the
  // server still returns, to avoid the list growing unbounded).
  final currentIds = notifications.map((n) => n.notificationId).toSet();
  await storage.write(key: _seenIdsKey, value: currentIds.join(','));
}

/// Marks the currently visible notifications as "seen" without showing
/// a local notification. Called from the foreground after the user
/// opens the app so we don't re-alert them.
Future<void> markCurrentNotificationsAsSeen(List<int> ids) async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _seenIdsKey, value: ids.join(','));
}

/// workmanager only supports Android and iOS; other platforms throw
/// UnimplementedError. Gate every call so callers don't need to.
bool get _workmanagerSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Schedule the periodic background poll using the user's configured
/// interval from [PrefsService] (minimum 15 minutes on Android).
Future<void> registerBackgroundNotificationPoll() async {
  if (!_workmanagerSupported) return;
  await Workmanager().initialize(backgroundCallbackDispatcher);
  final minutes = PrefsService.instance.pollIntervalMinutes;
  // Android enforces a 15-minute minimum for periodic tasks.
  final clamped = minutes < 15 ? 15 : minutes;
  await Workmanager().registerPeriodicTask(
    notificationPollTaskName,
    notificationPollTaskName,
    frequency: Duration(minutes: clamped),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
  );
}

Future<void> cancelBackgroundNotificationPoll() async {
  if (!_workmanagerSupported) return;
  await Workmanager().cancelByUniqueName(notificationPollTaskName);
}

/// Cancel then re-register with the latest interval. Call this after
/// the user changes poll frequency in settings.
Future<void> rescheduleBackgroundNotificationPoll() async {
  await cancelBackgroundNotificationPoll();
  await registerBackgroundNotificationPoll();
}

String? _payloadFor(NcNotification n) {
  final target = n.target;
  if (target == null) return null;
  final tab = switch (target) {
    NotificationTarget.checklists => 0,
    NotificationTarget.photos => 1,
    NotificationTarget.notes => 2,
  };
  return DeepLink(tabIndex: tab, houseId: n.houseId).encode();
}
