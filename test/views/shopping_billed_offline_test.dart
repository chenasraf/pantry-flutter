import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';

/// A billed total is typed at a till, which is where the link is worst, so the
/// write goes to the queue rather than down the wire — and the figure has to be
/// read back through the queue, or the next fetch draws the older server value
/// over what was typed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  /// A server that answers the review fetch and nothing else: up long enough to
  /// open the screen, gone by the time a total is typed. A write that fails
  /// this way is retryable, so the op stays queued rather than being dropped.
  http.Client serverWith({double? billedTotal, String? billedCurrency}) =>
      MockClient((request) async {
        if (request.method != 'GET') {
          throw http.ClientException('offline', request.url);
        }
        return http.Response(
          jsonEncode({
            'ocs': {
              'data': {
                'stores': [
                  {
                    'storeId': null,
                    'items': [],
                    'estimate': [],
                    'noPriceCount': 0,
                    'billedTotal': billedTotal,
                    'billedCurrency': billedCurrency,
                  },
                ],
                'grandTotal': [],
                'uncheckedCount': 0,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

  /// Runs [body] with [client] serving every request the app makes — the review
  /// fetch, and any drain the queue attempts while the test runs.
  Future<void> withServer(http.Client client, Future<void> Function() body) =>
      http.runWithClient(body, () => client);

  /// Pumped in fixed steps rather than settled: a write the queue could not
  /// deliver leaves a retry timer behind, and settling would chase it forever.
  Future<void> pumpReview(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShoppingReviewView(
          houseId: 1,
          sessionId: 5,
          mode: ShoppingReviewMode.close,
          stores: {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> typeTotal(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
  }

  /// Lets the currency cache's debounced save fire, so the test does not end
  /// with a timer pending. An undeliverable write costs the op no retry budget
  /// and schedules nothing, so this is the only timer in play.
  Future<void> quiesce(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  /// The total field, the only text field on the section.
  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  List<SyncOp> billedOps() => manager.queueForTest
      .all()
      .where((op) => op.entity == SyncEntity.shoppingSession)
      .toList();

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
    unawaited(manager.reset());
  });

  // The reset is deliberately not awaited: a cache store's drain, once started
  // inside the test's fake-async zone, is never driven to completion, so
  // awaiting it hangs the file. `SyncQueue.clear` empties its ops
  // synchronously, which is the whole of what the next test needs.
  tearDown(() {
    unawaited(manager.reset());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('a typed total is queued, and survives a failed send', (
    tester,
  ) async {
    await withServer(serverWith(), () async {
      await pumpReview(tester);
      await typeTotal(tester, '42.50');

      final op = billedOps().single;
      expect(op.op, SyncOpKind.update);
      expect(op.houseId, 1);
      expect(op.parentId, 5);
      // The storeless fallback the session itself carries.
      expect(op.entityId, isNull);
      expect(op.body['billedTotal'], 42.5);
      expect(op.body['billedCurrency'], isNotNull);

      await quiesce(tester);
    });
  });

  testWidgets('an emptied field queues a write that clears it', (tester) async {
    await withServer(
      serverWith(billedTotal: 42.5, billedCurrency: 'EUR'),
      () async {
        await pumpReview(tester);
        expect(fieldText(tester), '42.5');

        await typeTotal(tester, '');

        final op = billedOps().single;
        expect(op.body['billedTotal'], isNull);
        expect(op.body['billedCurrency'], isNull);

        await quiesce(tester);
      },
    );
  });

  testWidgets('a queued total wins over the server\'s older one', (
    tester,
  ) async {
    manager.queueForTest.enqueue(
      SyncOp(
        uuid: 'billed-1',
        entity: SyncEntity.shoppingSession,
        op: SyncOpKind.update,
        houseId: 1,
        parentId: 5,
        body: {'billedTotal': 42.5, 'billedCurrency': 'EUR'},
        createdAt: 0,
      ),
    );

    // The server still reports what it knew before the op drained.
    await withServer(
      serverWith(billedTotal: 10, billedCurrency: 'EUR'),
      () async {
        await pumpReview(tester);
        expect(fieldText(tester), '42.5');
        await quiesce(tester);
      },
    );
  });

  testWidgets('another session\'s total does not leak in', (tester) async {
    manager.queueForTest.enqueue(
      SyncOp(
        uuid: 'billed-other',
        entity: SyncEntity.shoppingSession,
        op: SyncOpKind.update,
        houseId: 1,
        parentId: 6,
        body: {'billedTotal': 42.5, 'billedCurrency': 'EUR'},
        createdAt: 0,
      ),
    );

    await withServer(
      serverWith(billedTotal: 10, billedCurrency: 'EUR'),
      () async {
        await pumpReview(tester);
        expect(fieldText(tester), '10');
        await quiesce(tester);
      },
    );
  });
}
