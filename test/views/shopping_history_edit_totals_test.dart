import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';

/// A finished trip reads as a record: the amounts are shown, not offered for
/// typing, and only the shopper who made the trip can open them for a
/// correction. Once one is typed, leaving says so, because the history row the
/// trip was opened from still carries the figure from before.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  /// What the trip's total is worth on the server, in the history list. Raised
  /// once a correction has been typed, the way the server recomputes the row
  /// from the amended store totals.
  var serverTotal = 10.0;
  setUp(() => serverTotal = 10.0);

  /// Serves reads; every write fails, so a typed total stays queued.
  http.Client server() => MockClient((request) async {
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    }
    final path = request.url.path;
    final Object data;
    if (path.endsWith('/summary')) {
      data = {
        'stores': [
          {
            'storeId': null,
            'items': [],
            'estimate': [],
            'noPriceCount': 0,
            'billedTotal': 42.5,
            'billedCurrency': 'EUR',
          },
        ],
        'grandTotal': [],
        'uncheckedCount': 0,
      };
    } else if (path.endsWith('/sessions/history')) {
      data = [
        {
          'id': 5,
          'userId': 'chen',
          'createdAt': 1000,
          'closedAt': 2000,
          'stores': ['Store A'],
          'itemCount': 2,
          'grandTotal': [
            {'currency': 'EUR', 'amount': serverTotal},
          ],
        },
      ];
    } else {
      data = const [];
    }
    return http.Response(
      jsonEncode({
        'ocs': {'data': data},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  /// What the summary route popped, once it has.
  bool? popped;

  /// Opens the summary the way the history list does: pushed, and its result
  /// read back.
  Future<void> openSummary(WidgetTester tester, {required bool canEdit}) async {
    popped = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => ShoppingReviewView(
                      houseId: 1,
                      sessionId: 5,
                      mode: ShoppingReviewMode.history,
                      stores: const {},
                      canEditBilled: canEdit,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Pumped in fixed steps rather than settled: an undeliverable write leaves a
  /// retry timer behind, and settling would chase it forever.
  Future<void> typeTotal(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

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
  // awaiting it hangs the file.
  tearDown(() {
    unawaited(manager.reset());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('a housemate\'s trip offers nothing to edit', (tester) async {
    await withServer(() async {
      await openSummary(tester, canEdit: false);

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('the shopper types only after opting in', (tester) async {
    await withServer(() async {
      await openSummary(tester, canEdit: true);

      expect(find.byType(TextField), findsNothing);
      expect(find.text(m.shopping.reviewTitle), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(m.shopping.editTotalsTitle), findsOneWidget);
      expect(find.text(m.shopping.doneEditing), findsOneWidget);
      // A finished trip has no transition to confirm, editing or not.
      expect(find.text(m.shopping.finishTrip), findsNothing);
      expect(find.text(m.common.cancel), findsNothing);

      await tester.tap(find.text(m.shopping.doneEditing));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
    });
  });

  testWidgets('an amended total is queued and reported on the way out', (
    tester,
  ) async {
    await withServer(() async {
      await openSummary(tester, canEdit: true);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await typeTotal(tester, '50');

      final op = billedOps().single;
      expect(op.op, SyncOpKind.update);
      expect(op.parentId, 5);
      expect(op.body['billedTotal'], 50);

      await goBack(tester);
      expect(popped, isTrue);
    });
  });

  testWidgets('a trip left as it was reports nothing', (tester) async {
    await withServer(() async {
      await openSummary(tester, canEdit: true);
      await goBack(tester);

      expect(popped, isNull);
      expect(billedOps(), isEmpty);
    });
  });

  testWidgets('the history row catches up with the corrected total', (
    tester,
  ) async {
    await withServer(() async {
      await tester.pumpWidget(
        const MaterialApp(home: ShoppingHistoryView(houseId: 1)),
      );
      await tester.pumpAndSettle();

      final before = formatCurrencyAmounts(const [
        CurrencyAmount(currency: 'EUR', amount: 10),
      ])!;
      expect(find.text(before), findsOneWidget);

      await tester.tap(find.text('Store A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // The correction reaches the server between the two history reads.
      await typeTotal(tester, '50');
      serverTotal = 50;

      await goBack(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final after = formatCurrencyAmounts(const [
        CurrencyAmount(currency: 'EUR', amount: 50),
      ])!;
      expect(find.text(after), findsOneWidget);
      expect(find.text(before), findsNothing);
    });
  });
}
