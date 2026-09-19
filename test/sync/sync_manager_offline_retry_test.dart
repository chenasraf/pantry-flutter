import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// What restarts a queue that stopped because nothing answered.
///
/// Nothing outside the queue can be relied on to. A returning network interface
/// never arrives on a Bluetooth-proxied watch — it reports none for the whole
/// time it is reaching the server — and the reads that would otherwise settle
/// [SyncManager.isOnline] are a refresh interval the wearer is free to switch
/// off. A queue waiting on one of those holds a check-off until the app is next
/// reopened, showing a dot that says so and offering nothing to act on.
///
/// So it comes back on its own clock, and the attempt that does it is charged to
/// the link rather than to the write: a server that said nothing has said
/// nothing about the change.
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

  SyncOp toggle(String uuid, int itemId) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: 7,
    entityId: itemId,
    createdAt: 0,
  );

  const itemBody =
      '{"id":42,"listId":7,"name":"Milk","done":true,'
      '"repeatFromCompletion":false,"sortOrder":1,'
      '"createdAt":0,"updatedAt":0}';

  /// A server that is unreachable until [reachable] is set, counting what
  /// arrives so a re-attempt can be told from the flush that started it.
  ///
  /// The dead socket stands in for every way a request fails to arrive — a
  /// refused certificate and a timeout leave the queue at the same exit.
  var reachable = false;
  var requests = 0;
  http.Client server() => MockClient((_) async {
    requests++;
    if (!reachable) throw const SocketException('Network is unreachable');
    return http.Response(itemBody, 200);
  });

  setUp(() {
    reachable = false;
    requests = 0;
  });

  /// Wait for [ready], bounded by the clock rather than by a count of turns:
  /// what is under test is a real timer firing without being asked, so the test
  /// has to let time pass and has to give up in bounded time if it never does.
  Future<void> waitFor(bool Function() ready, {required String reason}) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!ready() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    expect(ready(), isTrue, reason: reason);
  }

  test(
    'the queue re-attempts with nothing telling it the link is back',
    () async {
      manager.queueForTest.enqueue(toggle('a', 42));

      // Every hand that could restart it stays still: no `setOnline`, no
      // `reportInterfaceAvailable`, no resume, no second `flushNow`.
      await http.runWithClient(() async {
        await manager.flushNow();
        expect(manager.queueForTest.all(), hasLength(1));

        reachable = true;
        await waitFor(
          () => manager.queueForTest.isEmpty,
          reason: 'the check-off should land once the server answers again',
        );
      }, server);

      expect(manager.isOnline, isTrue);
    },
  );

  test('a change made while offline starts the loop', () async {
    // The queue was empty when the link died, so there was no flush to stop and
    // nothing armed: the write itself is what gives the loop something to carry.
    manager.setOnline(false);
    reachable = true;

    await http.runWithClient(() async {
      manager.enqueue(toggle('a', 42));
      await waitFor(
        () => manager.queueForTest.isEmpty,
        reason: 'an offline enqueue should not wait for an outside event',
      );
    }, server);
  });

  test('the re-attempts are not charged to the write', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    await http.runWithClient(() async {
      await manager.flushNow();
      await waitFor(
        () => requests > 1,
        reason: 'the queue should try again on its own',
      );
    }, server);

    // Eight charged attempts dead-letter an op. A server that is merely
    // unreachable must never spend one, or a watch left out of range long
    // enough would delete the wearer's changes to make the queue drain.
    expect(manager.queueForTest.peek()!.attemptCount, 0);
    expect(manager.queueForTest.all().map((o) => o.uuid), ['a']);
  });
}
