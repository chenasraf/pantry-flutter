import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/views/shopping/shopping_session_view.dart';

import '../helpers/test_app.dart';

/// Cancelling a trip throws away everything done on it: nothing queued for it
/// may reach the server afterwards, and a trip a housemate finished first is
/// not reported as cancelled.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final manager = SyncManager.instance;

  Map<String, dynamic> sessionJson({int? abortedAt}) => {
    'id': 12,
    'houseId': 1,
    'userId': 'chen',
    'listIds': [4],
    'stores': [],
    'activeStoreId': null,
    'includeUnassigned': true,
    'isPrivate': false,
    'lastSeenAt': 0,
    'memberIds': ['chen'],
    'live': false,
    'closedAt': 2000,
    'abortedAt': abortedAt,
    'createdAt': 1000,
    'updatedAt': 2000,
  };

  http.Response ocs(Object data, int status) => http.Response(
    jsonEncode({
      'ocs': {'data': data},
    }),
    status,
    headers: {'content-type': 'application/json'},
  );

  SyncOp op(
    String uuid,
    SyncEntity entity, {
    int sessionId = 12,
    SyncOpKind kind = SyncOpKind.create,
  }) => SyncOp(
    uuid: uuid,
    entity: entity,
    op: kind,
    houseId: 1,
    entityId: 30,
    parentId: sessionId,
    createdAt: 0,
  );

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
    // Held offline so the queue stays exactly as each test seeds it.
    manager.setOnline(false);
  });

  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  group('cancelling', () {
    ShoppingSessionController controller() {
      final c = ShoppingSessionController(
        session: ShoppingSession.fromJson({
          ...sessionJson(),
          'live': true,
          'closedAt': null,
        }),
      );
      addTearDown(c.dispose);
      return c;
    }

    test('drops what was queued for the trip and nothing else', () async {
      manager
        ..enqueue(op('check', SyncEntity.shoppingCheck))
        ..enqueue(
          op('uncheck', SyncEntity.shoppingCheck, kind: SyncOpKind.delete),
        )
        ..enqueue(op('skip', SyncEntity.shoppingSkip))
        ..enqueue(
          op('till', SyncEntity.shoppingSession, kind: SyncOpKind.update),
        )
        ..enqueue(op('other-trip', SyncEntity.shoppingCheck, sessionId: 99))
        ..enqueue(
          op('amount', SyncEntity.checklistItem, kind: SyncOpKind.update),
        );
      final posted = <String>[];

      final ended = await http.runWithClient(
        () => controller().cancel(),
        () => MockClient((request) async {
          posted.add('${request.method} ${request.url.path}');
          return ocs(sessionJson(abortedAt: 2000), 200);
        }),
      );

      expect(posted, [
        'POST /ocs/v2.php/apps/pantry/api/houses/1/shopping/sessions/12/abort',
      ]);
      expect(ended.isCancelled, isTrue);
      expect(manager.queuedOps.map((o) => o.uuid), ['other-trip', 'amount']);
    });

    test('a trip a housemate finished first keeps its queue', () async {
      manager.enqueue(op('check', SyncEntity.shoppingCheck));

      // Reaching the server brings the queue back online; anything but the
      // cancel finds no route, so the check holds where it is.
      final attempt = http.runWithClient(
        () => controller().cancel(),
        () => MockClient((request) async {
          if (!request.url.path.endsWith('/abort')) {
            throw http.ClientException('unreachable');
          }
          return ocs(sessionJson(), 409);
        }),
      );

      await expectLater(
        attempt,
        throwsA(
          isA<ShoppingSessionConflict>().having(
            (e) => e.session.isCancelled,
            'isCancelled',
            isFalse,
          ),
        ),
      );
      expect(manager.queuedOps.map((o) => o.uuid), ['check']);
    });
  });

  group('the trip screen', () {
    Future<void> openTrip(WidgetTester tester, String version) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse(version),
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            wrapForTest(
              ShoppingSessionView(
                session: ShoppingSession.fromJson({
                  ...sessionJson(),
                  'live': true,
                  'closedAt': null,
                }),
              ),
            ),
          );
          await tester.pumpAndSettle();
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/review')) {
            return ocs({
              'stores': [],
              'grandTotal': [],
              'uncheckedCount': 0,
            }, 200);
          }
          if (request.url.path.endsWith('/sessions/current')) {
            return ocs({...sessionJson(), 'live': true, 'closedAt': null}, 200);
          }
          return ocs(const [], 200);
        }),
      );
    }

    Future<void> closeTrip(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('an older server offers no cancel', (tester) async {
      await openTrip(tester, '0.38.0');

      expect(find.byKey(const ValueKey('trip-overflow')), findsNothing);
      await closeTrip(tester);
    });

    testWidgets('cancel lives in the overflow menu and asks first', (
      tester,
    ) async {
      await openTrip(tester, '0.39.0');

      expect(find.text(m.shopping.cancelTrip), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trip-overflow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(m.shopping.cancelTrip));
      await tester.pumpAndSettle();

      expect(find.text(m.shopping.cancelTripTitle), findsOneWidget);
      await tester.tap(find.text(m.shopping.keepShopping));
      await tester.pumpAndSettle();
      expect(find.text(m.shopping.cancelTripTitle), findsNothing);
      await closeTrip(tester);
    });
  });

  group('history', () {
    testWidgets('a cancelled trip says so, with no count or total', (
      tester,
    ) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.39.0'),
      );
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            wrapForTest(const ShoppingHistoryView(houseId: 1)),
          );
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 1));
        },
        () => MockClient((request) async {
          if (!request.url.path.endsWith('/sessions/history')) {
            return ocs(const [], 200);
          }
          return ocs([
            {
              'id': 5,
              'userId': 'chen',
              'createdAt': 1000,
              'closedAt': 2000,
              'abortedAt': 2000,
              'stores': ['Corner shop'],
              'itemCount': 0,
              'grandTotal': [],
            },
          ], 200);
        }),
      );

      expect(find.text(m.shopping.cancelledBadge), findsOneWidget);
      expect(find.text(m.shopping.itemsCount(0)), findsNothing);
      expect(find.text('—'), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
