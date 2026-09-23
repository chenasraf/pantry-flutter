import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

/// What a drag on the photo board owes the server.
///
/// The board is the one place the stored order is authored, so a drag that
/// lands only in the grid — lost to a dead link, or written under a sort the
/// server will not honour — reads as the app forgetting what the user just did.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    PhotoService.instance.cache.clear();
    await SyncManager.instance.reset();
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    SyncManager.instance.setOnline(true);
  });

  tearDown(() async {
    await SyncManager.instance.reset();
    SyncManager.instance.setOnline(true);
  });

  Map<String, dynamic> photoJson({
    required int id,
    int? folderId,
    required int sortOrder,
    int createdAt = 0,
  }) => {
    'id': id,
    'houseId': 1,
    'folderId': folderId,
    'fileId': id * 10,
    'caption': null,
    'uploadedBy': 'ada',
    'sortOrder': sortOrder,
    'createdAt': createdAt,
    'updatedAt': createdAt,
  };

  http.Response ocs(Object data) => http.Response(
    jsonEncode({
      'ocs': {
        'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
        'data': data,
      },
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  /// Drives [body] against a server that serves [photos] and records every
  /// reorder it is sent. [reorderResponse] answers the reorder POST, so a test
  /// can put a dead link in front of it.
  Future<List<List<int>>> withBoard(
    List<Map<String, dynamic>> photos,
    Future<void> Function(PhotoBoardController controller) body, {
    String sortBy = 'custom',
    Future<http.Response> Function()? reorderResponse,
  }) async {
    final posted = <List<int>>[];
    // The board prefetches previews after a load; its cache manager reaches
    // sqflite, which has no binding here and throws into the zone.
    await runZonedGuarded(() async {
      await http.runWithClient(
        () async {
          final controller = PhotoBoardController(houseId: 1);
          await controller.load();
          await body(controller);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          controller.dispose();
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST' && path.endsWith('/photos/reorder')) {
            if (reorderResponse != null) return reorderResponse();
            final items =
                (jsonDecode(request.body) as Map<String, dynamic>)['items']
                    as List;
            posted.add([for (final e in items) (e as Map)['id'] as int]);
            return ocs({'success': true});
          }
          if (path.endsWith('/prefs')) return ocs({'photoSort': sortBy});
          if (path.endsWith('/photos')) return ocs(photos);
          if (path.endsWith('/photos/folders')) return ocs([]);
          return ocs([]);
        }),
      );
    }, (e, _) {});
    return posted;
  }

  final threePhotos = [
    photoJson(id: 1, sortOrder: 0, createdAt: 300),
    photoJson(id: 2, sortOrder: 1, createdAt: 200),
    photoJson(id: 3, sortOrder: 2, createdAt: 100),
  ];

  test('a drag persists the new order', () async {
    final posted = await withBoard(threePhotos, (controller) async {
      expect(controller.visiblePhotos.map((p) => p.id), [1, 2, 3]);
      controller.startDrag(3);
      controller.hoverReorder(1);
      controller.endDrag();
      expect(controller.visiblePhotos.map((p) => p.id), [3, 1, 2]);
    });

    expect(posted, hasLength(1), reason: 'the drag never reached the server');
    expect(posted.single, [3, 1, 2]);
  });

  test('a drag inside a folder leaves the rest of the house alone', () async {
    final posted = await withBoard(
      [
        photoJson(id: 1, sortOrder: 0, createdAt: 300),
        photoJson(id: 2, sortOrder: 1, createdAt: 200),
        photoJson(id: 3, folderId: 9, sortOrder: 2, createdAt: 100),
        photoJson(id: 4, folderId: 9, sortOrder: 3, createdAt: 50),
      ],
      (controller) async {
        controller.enterFolder(9);
        expect(controller.visiblePhotos.map((p) => p.id), [3, 4]);
        controller.startDrag(4);
        controller.hoverReorder(3);
        controller.endDrag();
        expect(controller.visiblePhotos.map((p) => p.id), [4, 3]);
        controller.exitFolder();
        expect(controller.visiblePhotos.map((p) => p.id), [1, 2]);
      },
    );

    // Every photo in the house gets a slot of its own: numbering the folder
    // 0..n on its own would hand its photos the slots the root two hold.
    expect(posted.single, [1, 2, 4, 3]);
  });

  test('a drag the link drops is not lost', () async {
    final posted = await withBoard(
      threePhotos,
      (controller) async {
        controller.startDrag(3);
        controller.hoverReorder(1);
        controller.endDrag();
      },
      reorderResponse: () => Future.error(const SocketException('nope')),
    );

    // The request failed; the order the user dragged has to be waiting to be
    // sent again rather than living only in this board's grid.
    expect(posted, isEmpty);
    expect(
      SyncManager.instance.pendingCount.value,
      greaterThan(0),
      reason: 'a reorder that did not reach the server is queued',
    );
  });

  test('a drag under a server sort that ignores it is refused', () async {
    // Under "newest first" the server orders by creation date, so a written
    // sort_order is invisible: the grid would show a drag the next load undoes.
    final posted = await withBoard(threePhotos, sortBy: 'newest', (
      controller,
    ) async {
      controller.startDrag(3);
      controller.hoverReorder(1);
      controller.endDrag();
    });

    expect(posted, isEmpty);
  });
}
