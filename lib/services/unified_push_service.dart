import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/notification_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/secure_storage.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:unifiedpush_platform_interface/data/failed_reason.dart';
import 'package:unifiedpush_platform_interface/data/push_endpoint.dart';
import 'package:unifiedpush_platform_interface/data/push_message.dart';
import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';

/// Argument the UnifiedPush Android service starts a headless engine with,
/// when a push arrives and no app engine is alive to take it.
const unifiedPushBackgroundArg = '--unifiedpush-bg';

enum UnifiedPushStatus { off, connecting, active, failed }

/// An installed distributor app, as the launcher shows it.
class DistributorApp {
  final String package;
  final String label;
  final Uint8List? icon;

  const DistributorApp({required this.package, required this.label, this.icon});
}

enum UnifiedPushFailure {
  /// No distributor app is installed, or the saved one was removed.
  noDistributor,

  /// The server has no web push, or its administrator turned it off.
  serverUnsupported,

  /// The distributor or the server refused the subscription.
  registrationFailed,
}

/// Notification delivery over UnifiedPush and the Nextcloud Notifications
/// app's web push. The background poll keeps running until the server
/// confirms the subscription, and takes over again whenever it lapses.
class UnifiedPushService extends ChangeNotifier {
  UnifiedPushService._();
  static final UnifiedPushService instance = UnifiedPushService._();

  static const _instance = 'pantry';
  static const _activeKey = 'unifiedpush_active';

  static const _client = ApiClient(
    basePath: '/ocs/v2.php/apps/notifications/api/v2',
  );

  /// Distributors are Android apps, and the watch has no use for one when the
  /// phone it pairs with already gets the push.
  static bool get isSupported => PlatformInfo.isAndroidPhone;

  UnifiedPushStatus _status = UnifiedPushStatus.off;
  UnifiedPushStatus get status => _status;

  UnifiedPushFailure? _failure;
  UnifiedPushFailure? get failure => _failure;

  static const _apps = MethodChannel('dev.casraf.pantry/apps');

  String? _distributor;

  /// Package name of the distributor in use.
  String? get distributor => _distributor;

  final _labels = <String, String>{};

  /// The distributor's app name, once it has been looked up.
  String? get distributorLabel => _labels[_distributor];

  /// Bumped for every notification push, so an open notifications list can
  /// refresh instead of waiting for the next resume.
  final received = ValueNotifier<int>(0);

  bool _initialized = false;
  bool _background = false;

  Future<void> init({bool background = false}) async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    _background = background;
    try {
      await UnifiedPushPlatform.instance.initializeCallback(
        onNewEndpoint: (e, _) => unawaited(_onNewEndpoint(e)),
        onRegistrationFailed: (r, _) => unawaited(_onRegistrationFailed(r)),
        onUnregistered: (_) => unawaited(_onUnregistered()),
        onMessage: (m, _) => unawaited(_onMessage(m)),
      );
    } catch (e) {
      debugPrint('[UnifiedPush] init failed: $e');
      return;
    }
    if (background) return;

    if (await _readActive()) _setStatus(UnifiedPushStatus.active);
    if (PrefsService.instance.unifiedPushEnabled &&
        AuthService.instance.isLoggedIn) {
      unawaited(_resume());
    }
  }

  /// The distributor expects a registration on every launch, and answers it
  /// with the endpoint again — or a new one, if it moved.
  Future<void> _resume() async {
    try {
      _distributor = await UnifiedPushPlatform.instance.getDistributor();
      if (_distributor == null) {
        await _fail(UnifiedPushFailure.noDistributor);
        return;
      }
      unawaited(_describe([_distributor!]).then((_) => notifyListeners()));
      final vapid = await _fetchVapid();
      if (vapid == null) {
        await _fail(UnifiedPushFailure.serverUnsupported);
        return;
      }
      if (_status != UnifiedPushStatus.active) {
        _setStatus(UnifiedPushStatus.connecting);
      }
      await UnifiedPushPlatform.instance.register(_instance, [], null, vapid);
    } on OfflineException {
      // The subscription the server already holds still delivers; the next
      // launch with a connection renews it.
    } catch (e) {
      debugPrint('[UnifiedPush] resume failed: $e');
    }
  }

  /// Installed distributor apps, by package name.
  Future<List<String>> distributors() async {
    if (!isSupported) return const [];
    try {
      return await UnifiedPushPlatform.instance.getDistributors([]);
    } catch (e) {
      debugPrint('[UnifiedPush] listing distributors failed: $e');
      return const [];
    }
  }

  /// Installed distributor apps with their names and icons. An app the
  /// lookup misses still appears, under its package name.
  Future<List<DistributorApp>> distributorApps() async {
    final packages = await distributors();
    if (packages.isEmpty) return const [];
    final described = await _describe(packages);
    return [
      for (final p in packages)
        described[p] ?? DistributorApp(package: p, label: p),
    ];
  }

  Future<Map<String, DistributorApp>> _describe(List<String> packages) async {
    try {
      final raw = await _apps.invokeListMethod<Map<Object?, Object?>>(
        'describe',
        {'packages': packages},
      );
      final apps = {
        for (final a in raw ?? const <Map<Object?, Object?>>[])
          a['package'] as String: DistributorApp(
            package: a['package'] as String,
            label: a['label'] as String,
            icon: a['icon'] as Uint8List?,
          ),
      };
      for (final a in apps.values) {
        _labels[a.package] = a.label;
      }
      return apps;
    } catch (e) {
      debugPrint('[UnifiedPush] describing distributors failed: $e');
      return const {};
    }
  }

  /// Subscribes through [distributor]. Returns the failure when one is known
  /// up front; otherwise the outcome lands in [status] once the distributor
  /// and the server have answered.
  Future<UnifiedPushFailure?> enable(String distributor) async {
    await init();
    _failure = null;
    _setStatus(UnifiedPushStatus.connecting);
    final String? vapid;
    try {
      vapid = await _fetchVapid();
    } catch (e) {
      debugPrint('[UnifiedPush] fetching VAPID key failed: $e');
      _setStatus(UnifiedPushStatus.off);
      return UnifiedPushFailure.registrationFailed;
    }
    if (vapid == null) {
      _setStatus(UnifiedPushStatus.off);
      return UnifiedPushFailure.serverUnsupported;
    }
    await PrefsService.instance.setUnifiedPushEnabled(true);
    _distributor = distributor;
    await UnifiedPushPlatform.instance.saveDistributor(distributor);
    await UnifiedPushPlatform.instance.register(_instance, [], null, vapid);
    return null;
  }

  /// Drops the subscription on both ends and hands delivery back to polling.
  Future<void> disable() async {
    if (!isSupported || !PrefsService.instance.unifiedPushEnabled) return;
    await PrefsService.instance.setUnifiedPushEnabled(false);
    _activationRetry?.cancel();
    try {
      await UnifiedPushPlatform.instance.unregister(_instance);
    } catch (e) {
      debugPrint('[UnifiedPush] unregister failed: $e');
    }
    if (AuthService.instance.isLoggedIn) {
      try {
        await _client.delete('/webpush').timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[UnifiedPush] removing server subscription failed: $e');
      }
    }
    _distributor = null;
    _failure = null;
    await _setActive(false);
    _setStatus(UnifiedPushStatus.off);
  }

  /// Null when the server has no web push to offer.
  Future<String?> _fetchVapid() async {
    try {
      final vapid = await _client.get<Map<String, dynamic>, String?>(
        '/webpush/vapid',
        fromJson: (data) => data['vapid'] as String?,
      );
      return vapid;
    } on OfflineException {
      rethrow;
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) return null;
      rethrow;
    }
  }

  Timer? _activationRetry;

  /// The server pushes the activation token the moment it stores the
  /// subscription, which can be before the distributor listens on a topic it
  /// has only just created, and that push is then gone. Registering again
  /// makes the server issue a fresh token.
  void _scheduleActivationRetry(PushEndpoint endpoint, int attempt) {
    _activationRetry?.cancel();
    if (attempt >= _activationAttempts) return;
    _activationRetry = Timer(_activationWait, () {
      if (_status != UnifiedPushStatus.connecting ||
          !PrefsService.instance.unifiedPushEnabled) {
        return;
      }
      debugPrint('[UnifiedPush] no activation yet, registering again');
      unawaited(_onNewEndpoint(endpoint, attempt: attempt + 1));
    });
  }

  static const _activationAttempts = 3;
  static const _activationWait = Duration(seconds: 8);

  Future<void> _onNewEndpoint(PushEndpoint endpoint, {int attempt = 1}) async {
    debugPrint(
      '[UnifiedPush] endpoint on ${Uri.tryParse(endpoint.url)?.host} '
      '(keys: ${endpoint.pubKeySet != null})',
    );
    await _ensureSession();
    if (!AuthService.instance.isLoggedIn) return;
    final keys = endpoint.pubKeySet;
    if (keys == null) {
      await _fail(UnifiedPushFailure.registrationFailed);
      return;
    }
    try {
      final status = await _client.postForStatus(
        '/webpush',
        body: {
          'endpoint': endpoint.url,
          'uaPublicKey': keys.pubKey,
          'auth': keys.auth,
          'appTypes': 'pantry',
        },
      );
      debugPrint('[UnifiedPush] server took the subscription ($status)');
      // 201 means the server is about to push an activation token, which
      // [_onMessage] confirms; 200 means it already knew this subscription.
      if (status == 200) {
        await _setActive(true);
      } else if (!_background) {
        _scheduleActivationRetry(endpoint, attempt);
      }
    } on OfflineException {
      // Retried on the next launch's registration.
    } on ApiException catch (e) {
      debugPrint('[UnifiedPush] server registration failed: $e');
      await _fail(
        e.statusCode == 403
            ? UnifiedPushFailure.serverUnsupported
            : UnifiedPushFailure.registrationFailed,
      );
    }
  }

  Future<void> _onRegistrationFailed(FailedReason reason) async {
    debugPrint('[UnifiedPush] registration failed: $reason');
    // A network failure is the distributor's own connection, and it retries.
    if (reason == FailedReason.network) return;
    await _fail(UnifiedPushFailure.registrationFailed);
  }

  Future<void> _onUnregistered() async {
    await _ensureSession();
    _distributor = null;
    await _fail(UnifiedPushFailure.noDistributor);
  }

  Future<void> _onMessage(PushMessage message) async {
    debugPrint('[UnifiedPush] push received (decrypted: ${message.decrypted})');
    if (!message.decrypted) return;
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(message.content)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[UnifiedPush] undecodable push: $e');
      return;
    }
    await _ensureSession();
    if (!AuthService.instance.isLoggedIn) return;

    final token = data['activationToken'];
    if (token is String) {
      await _activate(token);
      return;
    }

    if (data['delete-all'] == true) {
      await LocalNotificationsService.instance.cancelAll();
    } else if (data['delete-multiple'] == true && data['nids'] is List) {
      for (final nid in (data['nids'] as List).whereType<int>()) {
        await LocalNotificationsService.instance.cancel(nid);
      }
    } else if (data['delete'] == true && data['nid'] is int) {
      await LocalNotificationsService.instance.cancel(data['nid'] as int);
    } else if (data['nid'] is int) {
      await _show(data['nid'] as int, data['subject'] as String?);
    }
    received.value++;
  }

  Future<void> _activate(String token) async {
    try {
      final status = await _client.postForStatus(
        '/webpush/activate',
        body: {'activationToken': token},
      );
      debugPrint('[UnifiedPush] server activated the subscription ($status)');
      await _setActive(true);
    } on ApiException catch (e) {
      debugPrint('[UnifiedPush] activation failed: $e');
      // A token that arrives after a retry replaced it is stale, and the
      // retry's own token is still on its way.
      if (e.statusCode == 400) return;
      await _fail(UnifiedPushFailure.registrationFailed);
    } catch (e) {
      debugPrint('[UnifiedPush] activation failed: $e');
    }
  }

  Future<void> _show(int nid, String? subject) async {
    if (!PrefsService.instance.notificationsEnabled) return;
    // In the foreground the notifications list takes it, as with polling.
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    await markNotificationAsSeen(nid);

    // The push carries the subject only. Show that straight away, then swap
    // in the full notification and its deep link if the server answers.
    if (subject != null && subject.isNotEmpty) {
      final lines = subject.split('\n');
      final rest = lines.skip(1).join('\n').trim();
      await LocalNotificationsService.instance.show(
        id: nid,
        title: lines.first,
        body: rest.isEmpty ? null : rest,
      );
    }
    try {
      final n = await NotificationService.instance.getNotification(nid);
      if (n == null) return;
      await LocalNotificationsService.instance.show(
        id: nid,
        title: n.subject,
        body: n.message.isNotEmpty ? n.message : null,
        payload: notificationPayloadFor(n),
      );
    } catch (e) {
      debugPrint('[UnifiedPush] fetching notification $nid failed: $e');
    }
  }

  Future<void> _fail(UnifiedPushFailure failure) async {
    // Unregistering on purpose echoes back as an unregistration event.
    if (!PrefsService.instance.unifiedPushEnabled) return;
    _failure = failure;
    await _setActive(false);
    _setStatus(UnifiedPushStatus.failed);
  }

  Future<void> _setActive(bool active) async {
    try {
      await secureStorage.write(key: _activeKey, value: active.toString());
    } catch (e) {
      debugPrint('[UnifiedPush] failed to store state: $e');
    }
    if (active) {
      _activationRetry?.cancel();
      _failure = null;
      _setStatus(UnifiedPushStatus.active);
    }
    await applyNotificationDelivery();
  }

  Future<bool> _readActive() async {
    try {
      return await secureStorage.read(key: _activeKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Whether pushes are what delivers notifications right now, so the poll can
  /// stand down.
  Future<bool> isActive() async =>
      isSupported &&
      PrefsService.instance.unifiedPushEnabled &&
      await _readActive();

  void _setStatus(UnifiedPushStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }

  bool _sessionLoaded = false;

  /// A headless engine starts with nothing loaded, and HttpOverrides is
  /// per-isolate, so the pinned-cert override has to be installed here too.
  Future<void> _ensureSession() async {
    if (!_background || _sessionLoaded) return;
    _sessionLoaded = true;
    await CertTrustService.instance.load();
    CertTrustService.instance.install();
    await AuthService.instance.loadCredentials();
    await PrefsService.instance.load();
  }
}

/// Runs the background poll unless an active push subscription makes it
/// redundant.
Future<void> applyNotificationDelivery() async {
  if (!PrefsService.instance.notificationsEnabled) {
    await cancelBackgroundNotificationPoll();
    return;
  }
  if (await UnifiedPushService.instance.isActive()) {
    await cancelBackgroundNotificationPoll();
  } else {
    await registerBackgroundNotificationPoll();
  }
}

/// Entry for the headless engine the UnifiedPush service starts.
Future<void> runUnifiedPushBackground() async {
  await LocalNotificationsService.instance.init();
  await UnifiedPushService.instance.init(background: true);
}
