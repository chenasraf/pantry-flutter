import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// Watches the platform's network interfaces so a queue waiting out a backoff
/// can be retried the moment a link comes back.
///
/// This is an accelerator and nothing more. What "online" means is the outcome
/// of the last real request ([SyncManager.isOnline]) — an interface reading
/// cannot answer it, because a Bluetooth-paired watch proxies its traffic
/// through the phone and reports no interface of its own the whole time it is
/// reaching the server perfectly well. So a `none` reading is ignored
/// entirely, and only a returning interface is acted on.
class ReachabilityService {
  ReachabilityService._();

  static final ReachabilityService instance = ReachabilityService._();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _hadInterface = true;

  /// Begin watching. Safe to call on any platform: a plugin that cannot
  /// initialise leaves the app on request outcomes alone, which is the
  /// definition that decides anyway.
  void start() {
    if (_sub != null) return;
    try {
      _sub = Connectivity().onConnectivityChanged.listen(
        _onChanged,
        onError: (Object e) =>
            debugPrint('[ReachabilityService] connectivity stream failed: $e'),
      );
    } catch (e) {
      debugPrint('[ReachabilityService] unavailable: $e');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onChanged(List<ConnectivityResult> results) {
    final hasInterface =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
    final returned = hasInterface && !_hadInterface;
    _hadInterface = hasInterface;
    if (returned) SyncManager.instance.reportInterfaceAvailable();
  }
}
