import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/wear_mirror_host.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// The phone's half of the mirror: what it agrees to fetch on a watch's
/// behalf, and what it refuses to send.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');

  final link = WearLinkService.instance;
  final host = WearMirrorHost.instance;

  final calls = <MethodCall>[];
  late _StreamHandler handler;

  void emit(String path, Map<String, dynamic> payload, {String? nodeId}) {
    handler.emit({
      'delivery': 'message',
      'path': path,
      'payload': jsonEncode(payload),
      'nodeId': nodeId ?? 'watch-1',
    });
  }

  setUp(() async {
    calls.clear();
    handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        if (call.method == 'isAvailable') return true;
        return true;
      })
      ..setMockStreamHandler(events, handler);
    link.debugReset();
    WearLinkService.debugHostSupported = true;
    await host.init();
  });

  tearDown(() async {
    await host.dispose();
    SyncManager.instance.setOnline(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  test('a scope report queues everything a row needs to be drawn', () async {
    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 4,
      'sessionId': null,
    });
    await pumpEventQueue();

    // The reference sets ride along: a snapshot of items whose categories and
    // stores are unknown is a list of unlabelled rows.
    expect(host.debugPendingFor('watch-1'), {
      (entity: MirrorEntity.lists, key: 1),
      (entity: MirrorEntity.categories, key: 1),
      (entity: MirrorEntity.stores, key: 1),
      (entity: MirrorEntity.labels, key: 1),
      (entity: MirrorEntity.notes, key: 1),
      (entity: MirrorEntity.items, key: 4),
    });
  });

  test('a trip adds its own items to the scope', () async {
    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 4,
      'sessionId': 12,
    });
    await pumpEventQueue();

    expect(
      host.debugPendingFor('watch-1'),
      contains((entity: MirrorEntity.sessionItems, key: 12)),
    );
  });

  test('the all-lists view has no items path of its own', () async {
    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 0,
      'sessionId': null,
    });
    await pumpEventQueue();

    expect(
      host.debugPendingFor('watch-1').map((s) => s.entity),
      isNot(contains(MirrorEntity.items)),
    );
  });

  test('a bare request falls back to the last scope the watch gave', () async {
    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 4,
      'sessionId': null,
    });
    await pumpEventQueue();
    await host.debugFlush();

    // A watch asking again after a wake need not repeat itself.
    emit(WearMirrorService.mirrorRequestPath, const {});
    await pumpEventQueue();

    expect(
      host.debugPendingFor('watch-1'),
      contains((entity: MirrorEntity.items, key: 4)),
    );
  });

  test('a watch that has said nothing is mirrored nothing', () async {
    emit(WearMirrorService.mirrorRequestPath, const {});
    await pumpEventQueue();
    host.nudge(houseId: 1);

    expect(host.debugPendingFor('watch-1'), isEmpty);
  });

  test('a house no watch is showing is not fetched for one', () async {
    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 4,
      'sessionId': null,
    });
    await pumpEventQueue();
    await host.debugFlush();

    host.nudge(houseId: 2);

    expect(host.debugPendingFor('watch-1'), isEmpty);
  });

  test('a snapshot that could not be fetched is not sent empty', () async {
    // Offline is what a failed leg looks like from here, and an empty snapshot
    // would land as "this house has no lists" rather than as nothing at all.
    SyncManager.instance.setOnline(false);

    emit(WearMirrorService.scopeReportPath, const {
      'houseId': 1,
      'listId': 4,
      'sessionId': null,
    });
    await pumpEventQueue();
    await host.debugFlush();

    expect(calls.map((c) => c.method), isNot(contains('stream')));
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _sink = events;

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
