import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/services/item_memory_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

void main() {
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final dairy = makeCategory(id: 12, name: 'Dairy');
  final bakery = makeCategory(id: 13, name: 'Bakery', sortOrder: 1);
  late List<ComposeSubmission> submitted;

  setUp(() {
    submitted = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });

  tearDown(() async {
    await PrefsService.instance.clear();
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  /// Item memory remembering "milk" as Dairy, added as "1 L" on list 7.
  void rememberMilk() {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.40.0'),
    );
    ItemMemoryService.instance.debugSeed(1, {
      'categories': [
        {
          'nameKey': 'milk',
          'categoryId': 12,
          'uses': 4,
          'rejections': 1,
          'updatedAt': 1,
        },
      ],
      'quantities': [
        {'listId': 7, 'nameKey': 'milk', 'quantity': '1 L'},
      ],
      'serverTime': 1,
    });
  }

  Widget bar({List<Category>? categories, ItemDefaults? itemDefaults}) =>
      wrapForTest(
        ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: 7,
          categories: categories ?? [dairy, bakery],
          itemDefaults: itemDefaults,
          initiallyFocused: true,
          onSubmit: (s) async {
            submitted.add(s);
            return true;
          },
        ),
      );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).first, text);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
  }

  Finder dropButton() => find.byTooltip(m.checklists.compose.dropSuggestion);

  testWidgets('a typed quantity fills the quantity chip', (tester) async {
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, '2 L milk');

    expect(find.text('2 L'), findsOneWidget);
    await submit(tester);

    expect(submitted.single.name, 'milk');
    expect(submitted.single.quantity, '2 L');
    expect(submitted.single.suggestionRejected, isNull);
  });

  testWidgets('dropping a typed quantity keeps the text whole', (tester) async {
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, '2 L milk');

    await tester.tap(dropButton());
    await tester.pumpAndSettle();
    expect(dropButton(), findsNothing);
    await submit(tester);

    expect(submitted.single.name, '2 L milk');
    expect(submitted.single.quantity, isNull);
  });

  testWidgets('smart input off takes the text as typed', (tester) async {
    await PrefsService.instance.setSmartItemInput(false);
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, '2 L milk');

    expect(dropButton(), findsNothing);
    await submit(tester);

    expect(submitted.single.name, '2 L milk');
    expect(submitted.single.quantity, isNull);
    expect(submitted.single.categoryId, isNull);
  });

  testWidgets('a remembered category and amount are offered', (tester) async {
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, 'Milk');

    expect(find.text('Dairy'), findsOneWidget);
    expect(find.text('1 L'), findsOneWidget);
    expect(dropButton(), findsNWidgets(2));
    await submit(tester);

    expect(submitted.single.name, 'Milk');
    expect(submitted.single.categoryId, 12);
    expect(submitted.single.quantity, '1 L');
    expect(submitted.single.suggestionRejected, isNull);
  });

  testWidgets('dropped guesses are reported with the item', (tester) async {
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, 'Milk');

    await tester.tap(dropButton().first);
    await tester.pumpAndSettle();
    await tester.tap(dropButton().first);
    await tester.pumpAndSettle();
    expect(dropButton(), findsNothing);
    await submit(tester);

    final s = submitted.single;
    expect(s.categoryId, isNull);
    expect(s.quantity, isNull);
    expect(s.suggestionRejected?.toJson(), {
      'categoryId': 12,
      'quantity': true,
    });
  });

  testWidgets('a typed quantity replaces a remembered one without a drop', (
    tester,
  ) async {
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, '2 L milk');
    await submit(tester);

    expect(submitted.single.quantity, '2 L');
    expect(submitted.single.suggestionRejected, isNull);
  });

  testWidgets('picking another category reports the guess as wrong', (
    tester,
  ) async {
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await type(tester, 'Milk');

    await tester.tap(find.text('Dairy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bakery'));
    await tester.pumpAndSettle();
    await submit(tester);

    expect(submitted.single.categoryId, 13);
    expect(submitted.single.suggestionRejected?.toJson(), {'categoryId': 12});
  });

  testWidgets('a guess is never offered outside the list categories', (
    tester,
  ) async {
    rememberMilk();
    await tester.pumpWidget(bar(categories: [bakery]));
    await tester.pumpAndSettle();
    await type(tester, 'Milk');
    await submit(tester);

    expect(submitted.single.categoryId, isNull);
  });

  testWidgets('a list default stands over a remembered amount', (tester) async {
    rememberMilk();
    await tester.pumpWidget(
      bar(
        itemDefaults: ItemDefaults.fromJson({
          'quantity': {'mode': 'fixed', 'value': '6'},
          'category': {'mode': 'fixed', 'value': 13},
        }),
      ),
    );
    await tester.pumpAndSettle();
    await type(tester, 'Milk');
    expect(dropButton(), findsNothing);
    await submit(tester);

    expect(submitted.single.quantity, '6');
    expect(submitted.single.categoryId, 13);
  });

  testWidgets('each line of a batch is read on its own', (tester) async {
    rememberMilk();
    await tester.pumpWidget(bar());
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.checklists.compose.multiple));
    await tester.pumpAndSettle();
    await type(tester, '2 L milk\n3x bread\njam');

    // One review row per line with a guess: milk carries an amount and a
    // category, bread its amount; jam has none.
    expect(dropButton(), findsNWidgets(3));
    await tester.tap(find.byTooltip(m.checklists.compose.dropSuggestion).at(1));
    await tester.pumpAndSettle();
    await submit(tester);

    expect(
      [for (final s in submitted) (s.name, s.quantity, s.categoryId)],
      [('milk', '2 L', null), ('bread', '3', null), ('jam', null, null)],
    );
    expect(submitted.first.suggestionRejected?.toJson(), {'categoryId': 12});
  });
}
