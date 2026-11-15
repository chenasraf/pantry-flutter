import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final manager = SyncManager.instance;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    await manager.reset();
    manager.setOnline(true);
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
  });

  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
    ServerVersionService.instance.debugSeed();
  });

  const itemBody =
      '{"id":60,"listId":50,"name":"Milk","done":true,'
      '"repeatFromCompletion":false,"sortOrder":1,'
      '"createdAt":0,"updatedAt":0}';

  final bodies = <String>[];

  setUp(bodies.clear);

  http.Client server() => MockClient((req) async {
    bodies.add(req.body);
    return http.Response(itemBody, 200);
  });

  SyncOp toggle({bool? done}) => SyncOp(
    uuid: 'toggle',
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: 50,
    entityId: 60,
    body: {'done': ?done},
    createdAt: 0,
  );

  void seed(String version) => ServerVersionService.instance.debugSeed(
    pantryVersion: Version.parse(version),
  );

  test('sends the target state to a server that takes it', () async {
    seed('0.39.0');
    manager.queueForTest.enqueue(toggle(done: true));

    await http.runWithClient(manager.flushNow, server);

    expect(manager.queueForTest.all(), isEmpty);
    expect(jsonDecode(bodies.single), {'done': true});
  });

  test('sends a bare flip to a server that only flips', () async {
    seed('0.38.0');
    manager.queueForTest.enqueue(toggle(done: true));

    await http.runWithClient(manager.flushNow, server);

    expect(bodies.single, isEmpty);
  });

  test('sends a bare flip for a toggle that names no state', () async {
    seed('0.39.0');
    manager.queueForTest.enqueue(toggle());

    await http.runWithClient(manager.flushNow, server);

    expect(bodies.single, isEmpty);
  });
}
