import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/views/shopping/shopping_item_row.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/item_thumb.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// The to-buy row is built from the same pieces as a checklist row, but a tap
/// on it always means "bought" — the trip is the one place
/// `defaultItemTapAction` gets no say, because a shopper checks items off far
/// more often than they open one.
void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  ShoppingSession session() => ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'chen',
    listIds: const [4],
    stores: const [ShoppingSessionStore(storeId: 7, position: 0)],
    activeStoreId: 7,
    includeUnassigned: true,
    isPrivate: false,
    lastSeenAt: 0,
    memberIds: const ['chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

  /// What each gesture landed on, so a test can say a tap reached the check and
  /// not the item.
  final taps = <String, int>{};

  setUp(() async {
    taps.clear();
    // A thumbnail's URL is built from the signed-in server, so the row cannot
    // draw a picture for a session that has none.
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  /// The row on its own, with a controller that has never loaded — reference
  /// data is best-effort everywhere it is read, so an empty one is a legal
  /// state and the row has to draw in it.
  Future<void> pumpRow(WidgetTester tester, ListItem item) async {
    final controller = ShoppingSessionController(session: session());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: ListView(
            children: [
              ShoppingItemRow(
                item: item,
                controller: controller,
                onCheck: () =>
                    taps.update('check', (n) => n + 1, ifAbsent: () => 1),
                onSkip: () {},
                onView: () =>
                    taps.update('view', (n) => n + 1, ifAbsent: () => 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('a tap anywhere on the row checks the item off', (tester) async {
    await pumpRow(tester, makeListItem(id: 1, name: 'Milk'));

    // The name itself, which on a checklist row would open the item under the
    // default tap action.
    await tester.tap(find.text('Milk'));
    await tester.pump();

    expect(taps['check'], 1);
    expect(taps['view'], isNull);
  });

  testWidgets('the trailing button is what opens the item', (tester) async {
    await pumpRow(tester, makeListItem(id: 1, name: 'Milk'));

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(taps['view'], 1);
    expect(taps['check'], isNull);
  });

  testWidgets('quantity and note ride along as chips', (tester) async {
    await pumpRow(
      tester,
      makeListItem(
        id: 1,
        name: 'Milk',
        quantity: '2 L',
        description: 'the blue cap one',
      ),
    );

    expect(find.text('2 L'), findsOneWidget);
    // The note chip is its icon alone — there is nowhere for it to open to
    // from a row whose tap is spoken for.
    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(find.byType(EntityChip), findsNWidgets(2));
  });

  testWidgets('a chip does not swallow the tap that checks the item', (
    tester,
  ) async {
    await pumpRow(tester, makeListItem(id: 1, name: 'Milk', quantity: '2 L'));

    await tester.tap(find.text('2 L'));
    await tester.pump();

    expect(taps['check'], 1);
  });

  testWidgets('an item with no picture reserves no room for one', (
    tester,
  ) async {
    await pumpRow(tester, makeListItem(id: 1, name: 'Milk'));

    expect(find.byType(ItemThumb), findsNothing);
  });

  testWidgets('an item with a picture shows it', (tester) async {
    await pumpRow(tester, makeListItem(id: 1, name: 'Milk', imageFileId: 42));

    expect(find.byType(ItemThumb), findsOneWidget);
  });
}
