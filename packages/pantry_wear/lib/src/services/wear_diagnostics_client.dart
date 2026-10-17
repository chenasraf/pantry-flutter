import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/diagnostic_log.dart';
import 'package:pantry_core/services/wear_diagnostics.dart';
import 'package:pantry_core/services/wear_link_service.dart';

/// Answers the phone's request for this watch's diagnostic log. The log is
/// already masked, so it leaves the watch exactly as it is stored.
class WearDiagnosticsClient {
  WearDiagnosticsClient._();

  static final WearDiagnosticsClient instance = WearDiagnosticsClient._();

  final _link = WearLinkService.instance;

  StreamSubscription<WearLinkMessage>? _messages;

  Future<void> start() async {
    if (_messages != null) return;
    if (!await _link.isAvailable()) return;
    _messages = _link.messages.listen(_onMessage);
  }

  Future<void> _onMessage(WearLinkMessage message) async {
    if (message.path != WearDiagnostics.requestPath) return;
    final id = message.data['id'];
    if (id is! String) return;
    final log = await DiagnosticLog.instance.read();
    await _link.stream(WearDiagnostics.responsePath, {
      'id': id,
      'log': log,
    }, nodeId: message.nodeId);
  }

  @visibleForTesting
  Future<void> debugReset() async {
    await _messages?.cancel();
    _messages = null;
  }
}
