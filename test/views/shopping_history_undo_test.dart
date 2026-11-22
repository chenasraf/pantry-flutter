import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';

import '../helpers/test_app.dart';

/// Anyone who shopped a finished trip may undo it once they have confirmed;
/// the row is then labelled as undone, and anything left as it was is listed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  var undoStatus = 200;
  var skipped = <Map<String, Object?>>[];
  final undone = <int>{};
  final undos = <String>[];
  var undoneCallbacks = 0;

  Map<String, Object?> session(int id) => {
    'id': id,
    'houseId': 1,
    'userId': 'chen',
    'listIds': [1],
    'stores': [],
    'activeStoreId': null,
    'includeUnassigned': true,
    'isPrivate': false,
    'lastSeenAt': 2000,
    'live': false,
    'closedAt': 2000,
    'undoneAt': undone.contains(id) ? 3000 : null,
    'createdAt': 1000,
    'updatedAt': 2000,
  };

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    final Object? data;
    var status = 200;
    if (request.method == 'POST' && path.endsWith('/undo')) {
      undos.add(path);
      final id = int.parse(path.split('/').reversed.elementAt(1));
      status = undoStatus;
      if (status == 200) undone.add(id);
      data = status == 200
          ? {
              'session': session(id),
              'reverted': [11],
              'skipped': skipped,
            }
          : session(id);
    } else if (path.endsWith('/sessions/history')) {
      data = [
        for (final (id, user, members, store, aborted) in [
          (5, 'chen', ['chen'], 'Store A', null),
          (6, 'ada', ['ada', 'chen'], 'Store B', null),
          (7, 'ada', ['ada'], 'Store C', null),
          (8, 'chen', ['chen'], 'Store D', 2000),
        ])
          {
            'id': id,
            'userId': user,
            'memberIds': members,
            'createdAt': 1000,
            'closedAt': 2000,
            'abortedAt': aborted,
            'undoneAt': undone.contains(id) ? 3000 : null,
            'stores': [store],
            'itemCount': aborted == null ? 2 : 0,
            'grandTotal': undone.contains(id) || aborted != null
                ? []
                : [
                    {'currency': 'USD', 'amount': 12.5},
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
      status,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  Future<void> openHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        ShoppingHistoryView(houseId: 1, onTripUndone: () => undoneCallbacks++),
      ),
    );
    await tester.pumpAndSettle();
    // The reference data the list caches is written behind a debounce timer,
    // which would otherwise still be pending when the test ends.
    await tester.pump(const Duration(seconds: 1));
  }

  Finder cardOf(String store) =>
      find.ancestor(of: find.text(store), matching: find.byType(Card));

  Finder menuOf(String store) => find.descendant(
    of: cardOf(store),
    matching: find.byIcon(Icons.more_vert),
  );

  Future<void> chooseUndo(WidgetTester tester, String store) async {
    await tester.tap(menuOf(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.shopping.undoTrip));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(m.shopping.undoTrip),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Lets a toast run out so no timer outlives the test.
  Future<void> drainToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  void seed({required bool canUndo}) => ServerVersionService.instance.debugSeed(
    pantryVersion: Version.parse(canUndo ? '0.40.0' : '0.39.0'),
  );

  setUp(() async {
    undoStatus = 200;
    skipped = [];
    undone.clear();
    undos.clear();
    undoneCallbacks = 0;
    seed(canUndo: true);
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
  });

  tearDown(() {
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('an older server offers no undo', (tester) async {
    seed(canUndo: false);
    await withServer(() async {
      await openHistory(tester);

      // Delete still shows on the shopper's own trips; undo does not.
      await tester.tap(menuOf('Store A'));
      await tester.pumpAndSettle();
      expect(find.text(m.shopping.undoTrip), findsNothing);
    });
  });

  testWidgets('trips the viewer shopped offer undo, others do not', (
    tester,
  ) async {
    await withServer(() async {
      await openHistory(tester);

      await tester.tap(menuOf('Store B'));
      await tester.pumpAndSettle();
      expect(find.text(m.shopping.undoTrip), findsOneWidget);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      expect(menuOf('Store C'), findsNothing);

      await tester.tap(menuOf('Store D'));
      await tester.pumpAndSettle();
      expect(find.text(m.shopping.undoTrip), findsNothing);
    });
  });

  testWidgets('a confirmed undo labels the row and drops its total', (
    tester,
  ) async {
    final total = formatCurrencyAmounts(const [
      CurrencyAmount(currency: 'USD', amount: 12.5),
    ])!;
    await withServer(() async {
      await openHistory(tester);
      expect(
        find.descendant(of: cardOf('Store A'), matching: find.text(total)),
        findsOneWidget,
      );

      await chooseUndo(tester, 'Store A');
      expect(find.text(m.shopping.undoTripBody), findsOneWidget);
      await confirm(tester);
      expect(find.text(m.shopping.undoTripDone), findsOneWidget);
      await tester.pumpAndSettle();

      expect(undos, [
        '/ocs/v2.php/apps/pantry/api/houses/1/shopping/sessions/5/undo',
      ]);
      expect(undoneCallbacks, 1);
      expect(
        find.descendant(
          of: cardOf('Store A'),
          matching: find.text(m.shopping.undoneBadge),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cardOf('Store A'), matching: find.text(total)),
        findsNothing,
      );
      expect(menuOf('Store A'), findsOneWidget);
      await tester.tap(menuOf('Store A'));
      await tester.pumpAndSettle();
      expect(find.text(m.shopping.undoTrip), findsNothing);
      await tester.tapAt(Offset.zero);
      await drainToast(tester);
    });
  });

  testWidgets('a cancelled confirm sends nothing', (tester) async {
    await withServer(() async {
      await openHistory(tester);

      await chooseUndo(tester, 'Store A');
      await tester.tap(find.text(m.common.cancel));
      await tester.pumpAndSettle();

      expect(undos, isEmpty);
      expect(undoneCallbacks, 0);
    });
  });

  testWidgets('items left as they were are listed with why', (tester) async {
    skipped = [
      {'itemId': 11, 'itemName': 'Milk', 'reason': 'changed'},
      {'itemId': 12, 'itemName': null, 'reason': 'gone'},
    ];
    await withServer(() async {
      await openHistory(tester);

      await chooseUndo(tester, 'Store A');
      await confirm(tester);
      await tester.pumpAndSettle();

      expect(find.text(m.shopping.undoSkippedTitle), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text(m.shopping.undoSkippedChanged), findsOneWidget);
      expect(find.text(m.shopping.undoSkippedUnnamed), findsOneWidget);
      expect(find.text(m.shopping.undoSkippedGone), findsOneWidget);
      expect(undoneCallbacks, 1);
    });
  });

  testWidgets('a trip that can no longer be undone says so', (tester) async {
    undoStatus = 409;
    await withServer(() async {
      await openHistory(tester);

      await chooseUndo(tester, 'Store A');
      await confirm(tester);

      expect(undos, hasLength(1));
      expect(undoneCallbacks, 0);
      expect(find.text(m.shopping.undoTripConflict), findsOneWidget);
      await drainToast(tester);
    });
  });
}
