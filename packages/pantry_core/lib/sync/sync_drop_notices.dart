import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// Changes the server refused for one reason, gathered into a single notice.
class SyncDropReport {
  /// The status every op here was dropped with, or null for ops that ran out
  /// of retries without one.
  final int? statusCode;

  final List<SyncOp> ops;

  const SyncDropReport({required this.statusCode, required this.ops});

  /// The name the user gave the one thing they lost, when there is exactly one
  /// and its op carries a name — an op body holds what was typed, so this is
  /// the user's own word for it.
  String? get name {
    if (ops.length != 1) return null;
    final body = ops.single.body;
    final name = body['name'] ?? body['title'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  }

  /// A 4xx is the server deciding against the change; anything else is a
  /// server that never managed to take it.
  bool get refused =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  String get message {
    final name = this.name;
    final count = ops.length;
    if (refused) {
      final status = statusCode!;
      if (name != null) return m.sync.refusedNamed(name, status);
      if (count == 1) return m.sync.refusedOne(status);
      return m.sync.refusedMany(count, status);
    }
    if (name != null) return m.sync.failedNamed(name);
    if (count == 1) return m.sync.failedOne;
    return m.sync.failedMany(count);
  }
}

/// Turns the queue's unexpected drops into notices a user can act on.
///
/// Drops arrive in bursts: a proxy that blocks writes refuses every op in the
/// queue, one after another, and a toast per op would bury the screen. Drops
/// are held until [quiet] passes without another, then reported once per
/// status — so a whole blocked queue reads as one message.
class SyncDropNotices {
  SyncDropNotices(this._manager, {this.quiet = const Duration(seconds: 2)});

  static final SyncDropNotices instance = SyncDropNotices(SyncManager.instance);

  final SyncManager _manager;
  final Duration quiet;

  final _reports = StreamController<SyncDropReport>.broadcast();
  Stream<SyncDropReport> get reports => _reports.stream;

  StreamSubscription<SyncOpSkipped>? _sub;
  final _pending = <SyncOpSkipped>[];
  Timer? _timer;

  void start() {
    _sub ??= _manager.onSkipped.listen(_onSkipped);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _reports.close();
  }

  /// Put every op of [report] back on the queue.
  void retry(SyncDropReport report) => _manager.requeue(report.ops);

  void _onSkipped(SyncOpSkipped event) {
    if (!event.isUnexpected) return;
    _pending.add(event);
    _timer?.cancel();
    _timer = Timer(quiet, _flush);
  }

  void _flush() {
    _timer = null;
    final byStatus = <int?, List<SyncOp>>{};
    for (final event in _pending) {
      byStatus.putIfAbsent(event.statusCode, () => []).add(event.op);
    }
    _pending.clear();
    for (final MapEntry(key: status, value: ops) in byStatus.entries) {
      _reports.add(SyncDropReport(statusCode: status, ops: ops));
    }
  }

  @visibleForTesting
  void flushForTest() {
    _timer?.cancel();
    _flush();
  }
}
