import 'dart:async';

import 'package:pantry_core/services/wear_diagnostics.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';

/// Reads the diagnostic log of the watch this phone is linked to.
class WearDiagnosticsHost {
  WearDiagnosticsHost._();

  static final WearDiagnosticsHost instance = WearDiagnosticsHost._();

  final _link = WearLinkService.instance;

  /// The watch's log, or null when no watch answered in time — none is in
  /// range, or Pantry isn't open on it.
  Future<String?> fetch() async {
    if (!await _link.isAvailable()) return null;
    final id = SyncIds.newOpUuid();
    final answer = Completer<String?>();
    // Listening before asking: a watch can answer faster than the send call
    // returns.
    final sub = _link.messages.listen((m) {
      final log = m.data['log'];
      if (m.path != WearDiagnostics.responsePath || m.data['id'] != id) return;
      if (log is String && !answer.isCompleted) answer.complete(log);
    });
    try {
      if (!await _link.send(WearDiagnostics.requestPath, {'id': id})) {
        return null;
      }
      return await answer.future.timeout(
        WearDiagnostics.timeout,
        onTimeout: () => null,
      );
    } finally {
      await sub.cancel();
    }
  }
}
