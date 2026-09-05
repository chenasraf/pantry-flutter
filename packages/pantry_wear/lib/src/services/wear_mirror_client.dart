import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';

import '../scope/wear_scope.dart';

/// The watch's half of the mirror: it says what it is looking at, asks for
/// what it needs, and lands what arrives.
///
/// Nothing here is a correctness precondition. Every snapshot only saves the
/// watch a request it could have made itself, so a client that never receives
/// one leaves the app exactly as correct — which is what lets a standalone
/// watch, an F-Droid watch and an out-of-range watch share this code path
/// rather than each needing a case.
class WearMirrorClient extends ChangeNotifier {
  WearMirrorClient._();

  static final WearMirrorClient instance = WearMirrorClient._();

  final _link = WearLinkService.instance;
  final _mirror = WearMirrorService.instance;
  final _scope = WearScope.instance;

  StreamSubscription<WearLinkMessage>? _messages;

  MirrorScopeReport _reported = const MirrorScopeReport();
  int? _sessionId;

  DateTime? _landedAt;

  /// When a snapshot last arrived, as opposed to when it was taken. What the
  /// read poll stretches against: an arrival says the phone is alive and
  /// pushing, which is the condition under which polling buys least.
  DateTime? get landedAt => _landedAt;

  /// When the newest snapshot was taken on the phone — the sync detail the
  /// account page reads.
  DateTime? get capturedAt => _mirror.lastCapturedAt;

  Future<void> start() async {
    if (_messages != null) return;
    if (!await _link.isAvailable()) return;
    _messages = _link.messages.listen(_onMessage);
    _scope.addListener(_onScopeChanged);
    await reportScope();
    await requestMirror();
  }

  @override
  void dispose() {
    _messages?.cancel();
    _messages = null;
    _scope.removeListener(_onScopeChanged);
    super.dispose();
  }

  /// A trip takes the watch over wherever it is being shopped, and its items
  /// are their own mirrored scope — so the phone has to be told about it the
  /// same way it is told about the list.
  void setSession(int? sessionId) {
    if (_sessionId == sessionId) return;
    _sessionId = sessionId;
    unawaited(reportScope());
  }

  /// Tell the phone what to mirror. Sent on every scope change, because the
  /// phone cannot mirror what it does not know the watch is showing — and it
  /// fetches this scope on the watch's behalf even when it is not displaying
  /// it itself.
  Future<void> reportScope() async {
    final report = MirrorScopeReport(
      houseId: _scope.houseId,
      listId: _scope.listId,
      sessionId: _sessionId,
    );
    // Before the watch has a house there is nothing to mirror, and an empty
    // report would only make the phone fetch a scope that does not exist.
    if (report.isEmpty || report == _reported) return;
    if (await _link.send(WearMirrorService.scopeReportPath, report.toJson())) {
      _reported = report;
    }
  }

  /// Ask for the snapshots this scope needs. Sent on wake, when the watch has
  /// been off the link for however long the wrist was down.
  Future<void> requestMirror() async {
    // A request the phone cannot place is a fetch it will not make, so the
    // scope goes with it rather than relying on a report that may predate a
    // phone restart.
    await _link.send(WearMirrorService.mirrorRequestPath, {
      ...MirrorScopeReport(
        houseId: _scope.houseId,
        listId: _scope.listId,
        sessionId: _sessionId,
      ).toJson(),
    });
  }

  void _onScopeChanged() => unawaited(reportScope());

  /// Detach from the link and forget what was reported, so a test can start a
  /// second one against a different fake.
  @visibleForTesting
  Future<void> debugReset() async {
    await _messages?.cancel();
    _messages = null;
    _scope.removeListener(_onScopeChanged);
    _reported = const MirrorScopeReport();
    _sessionId = null;
    _landedAt = null;
  }

  void _onMessage(WearLinkMessage message) {
    if (message.delivery != WearLinkDelivery.channel) return;
    if (!_mirror.land(message.path, message.data)) return;
    _landedAt = DateTime.now();
    notifyListeners();
  }
}
