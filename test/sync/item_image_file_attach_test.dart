import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

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
  });

  test('a queued Nextcloud file is attached by its id', () async {
    final requests = <http.Request>[];
    manager.queueForTest.enqueue(
      SyncOp(
        uuid: 'attach',
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.setImage,
        houseId: 1,
        parentId: 50,
        entityId: 60,
        body: {itemImageFileIdKey: 77, itemImageModeKey: 'link'},
        createdAt: 0,
      ),
    );

    await http.runWithClient(
      manager.flushNow,
      () => MockClient((req) async {
        requests.add(req);
        return http.Response(
          '{"id":60,"listId":50,"name":"Milk","done":false,'
          '"repeatFromCompletion":false,"sortOrder":1,'
          '"createdAt":0,"updatedAt":0,"imageFileId":77}',
          200,
        );
      }),
    );

    expect(manager.queueForTest.all(), isEmpty);
    final req = requests.single;
    expect(req.method, 'POST');
    expect(req.url.path, endsWith('/houses/1/lists/50/items/60/image/files'));
    expect(jsonDecode(req.body), {'fileId': 77, 'mode': 'link'});
  });
}
