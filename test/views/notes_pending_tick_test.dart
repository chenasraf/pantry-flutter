import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/notes/notes_controller.dart';

import '../helpers/test_models.dart';

/// The queue wins over any snapshot, from any source.
///
/// A note body is a document the server rewrites at drain, not a field the op
/// replaces, so a list fetched between a tick and its drain still reads the way
/// it did before the tick. Taken as-is it un-ticks the line on screen and
/// caches it that way.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const unticked = '- [ ] Wood glue\n- [ ] Sandpaper\n';
  const ticked = '- [ ] Wood glue\n- [x] Sandpaper\n';

  /// A server that hands back one note whose body predates the queued tick.
  http.Client serverWith(String content) => MockClient((request) async {
    final body = request.url.path.endsWith('/notes')
        ? {
            'ocs': {
              'data': [makeNote(id: 9, houseId: 1, content: content).toJson()],
            },
          }
        : {
            'ocs': {'data': {}},
          };
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  void queueTick({int noteId = 9, int houseId = 1}) {
    manager.queueForTest.enqueue(
      SyncOp(
        uuid: 'tick-$houseId-$noteId',
        entity: SyncEntity.note,
        op: SyncOpKind.toggle,
        houseId: houseId,
        entityId: noteId,
        body: {'ordinal': 1, 'text': 'Sandpaper', 'checked': true},
        createdAt: 0,
      ),
    );
  }

  NotesController controllerFor(int houseId) {
    final controller = NotesController(houseId: houseId);
    addTearDown(controller.dispose);
    return controller;
  }

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          const credentials = {
            'nextcloud_credentials':
                '{"serverUrl":"https://cloud.example.com",'
                '"loginName":"chen","appPassword":"secret"}',
          };
          if (call.method == 'read') return credentials[args['key']];
          if (call.method == 'readAll') return credentials;
          return null;
        });
    await AuthService.instance.loadCredentials();
    await manager.reset();
    NoteService.instance.cache.clear();
  });

  tearDown(() async {
    await manager.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('a load between a tick and its drain keeps the line ticked', () async {
    final controller = controllerFor(1);
    queueTick();

    await http.runWithClient(controller.load, () => serverWith(unticked));

    expect(controller.notes.single.content, ticked);
  });

  test('and the cache is written the same way, not the stale way', () async {
    final controller = controllerFor(1);
    queueTick();

    await http.runWithClient(controller.load, () => serverWith(unticked));

    expect(NoteService.instance.getCachedNotes(1)!.single.content, ticked);
  });

  test('a re-sort does not undo it either', () async {
    final controller = controllerFor(1);
    queueTick();

    await http.runWithClient(
      () => controller.setSortBy('title'),
      () => serverWith(unticked),
    );

    expect(controller.notes.single.content, ticked);
  });

  test('a body the server already caught up with is left alone', () async {
    final controller = controllerFor(1);
    queueTick();

    await http.runWithClient(controller.load, () => serverWith(ticked));

    expect(controller.notes.single.content, ticked);
  });

  test('an empty queue hands the snapshot through untouched', () async {
    final controller = controllerFor(1);

    await http.runWithClient(controller.load, () => serverWith(unticked));

    expect(controller.notes.single.content, unticked);
  });

  test('another house\'s tick does not reach this one', () async {
    final controller = controllerFor(1);
    queueTick(houseId: 2);

    await http.runWithClient(controller.load, () => serverWith(unticked));

    expect(controller.notes.single.content, unticked);
  });
}
