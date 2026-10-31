import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_put_away.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';

/// Finishing a trip says where what was bought goes: each item starts in the
/// inventories its tick restocked, and only what the shopper changes is sent
/// with the close.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const fridge = 20;
  const freezer = 21;

  Map<String, dynamic> inventory(int id, String name) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'kind': 'inventory',
    'icon': 'list',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  // Milk was ticked at the till and restocked 2 into the fridge.
  final milk = {
    'id': 7,
    'listId': 4,
    'name': 'Milk',
    'quantity': '2',
    'done': true,
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'restock': [
      {
        'itemId': 70,
        'listId': fridge,
        'itemName': 'Milk',
        'listName': 'Fridge',
        'added': '2',
        'previousLevel': null,
        'replaced': false,
      },
    ],
  };

  late List<http.Request> requests;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object data = const <Object>[];
    if (path.endsWith('/sessions/5/review')) {
      data = {
        'stores': [
          {
            'storeId': null,
            'items': [milk],
            'estimate': [],
            'noPriceCount': 1,
          },
        ],
        'grandTotal': [],
        'uncheckedCount': 0,
      };
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [inventory(fridge, 'Fridge'), inventory(freezer, 'Freezer')];
    } else if (path.endsWith('/sessions/5/close')) {
      data = {
        'id': 5,
        'houseId': 1,
        'userId': 'chen',
        'listIds': [4],
        'stores': [],
        'includeUnassigned': true,
        'isPrivate': false,
        'lastSeenAt': 0,
        'live': false,
        'createdAt': 0,
        'updatedAt': 0,
      };
    } else if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    }
    return http.Response(
      jsonEncode({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
          'data': data,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  /// Takes the queue's retry timer off the clock; see
  /// shopping_billed_offline_test.dart for why this isn't awaited.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  void seed({bool advertised = true}) =>
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.38.0'),
        advertised: {if (advertised) 'shopping-put-away'},
      );

  /// Opens the close review over a trip screen, and records what the confirm
  /// hands back.
  Future<List<List<PutAwayEntry>>> pumpReview(WidgetTester tester) async {
    final handed = <List<PutAwayEntry>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => ShoppingReviewView(
                  houseId: 1,
                  sessionId: 5,
                  mode: ShoppingReviewMode.close,
                  stores: const {},
                  onPutAway: handed.add,
                ),
              ),
            ),
            child: const Text('Review'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Review'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    return handed;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.ensureVisible(find.text(m.shopping.finishTrip));
    await tester.tap(find.text(m.shopping.finishTrip));
    await tester.pump();
  }

  setUp(() async {
    requests = [];
    seed();
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

  tearDown(() {
    unawaited(manager.reset());
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('starts each item where its tick restocked it', (tester) async {
    await withServer(() async {
      final handed = await pumpReview(tester);

      expect(find.text(m.shopping.putAwayTitle), findsOneWidget);
      expect(find.text('Fridge'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);

      await finish(tester);
      expect(handed, [isEmpty], reason: 'nothing changed, nothing is sent');

      await quiesce(tester);
    });
  });

  testWidgets('a storage added from the menu is sent', (tester) async {
    await withServer(() async {
      final handed = await pumpReview(tester);

      await tester.ensureVisible(find.text(m.shopping.putAwayAdd));
      await tester.tap(find.text(m.shopping.putAwayAdd));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Freezer').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The fridge already holds the whole purchase, so the freezer starts
      // with all of it again.
      await tester.enterText(find.widgetWithText(TextField, '2').first, '1');
      await tester.pump();
      await finish(tester);

      expect(handed.single.single.toJson(), {
        'itemId': 7,
        'storages': [
          {'listId': fridge, 'amount': 1.0},
          {'listId': freezer, 'amount': 2.0},
        ],
      });

      await quiesce(tester);
    });
  });

  testWidgets('a removed storage leaves the item not put away', (tester) async {
    await withServer(() async {
      final handed = await pumpReview(tester);

      await tester.tap(find.byTooltip(m.shopping.putAwayRemove));
      await tester.pump();
      expect(find.text(m.shopping.notPutAway), findsOneWidget);

      await finish(tester);
      expect(handed.single.single.storages, isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('servers without put-away get no section', (tester) async {
    seed(advertised: false);
    await withServer(() async {
      final handed = await pumpReview(tester);

      expect(find.text(m.shopping.putAwayTitle), findsNothing);
      expect(
        requests.map((r) => r.url.path),
        isNot(contains(endsWith('/inventories'))),
      );
      await finish(tester);
      expect(handed, isEmpty);

      await quiesce(tester);
    });
  });

  test('the close carries the put-away entries', () async {
    await http.runWithClient(() async {
      await ShoppingService.instance.close(
        1,
        5,
        putAway: const [
          PutAwayEntry(
            itemId: 7,
            storages: [PutAwayStorage(listId: freezer, amount: 2)],
          ),
        ],
      );
    }, server);

    final close = requests.singleWhere((r) => r.url.path.endsWith('/close'));
    expect(jsonDecode(close.body), {
      'putAway': [
        {
          'itemId': 7,
          'storages': [
            {'listId': freezer, 'amount': 2.0},
          ],
        },
      ],
    });
  });
}
