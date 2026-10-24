import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/apply_template_view.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';
import 'package:pantry/views/checklists/switcher_form_stage.dart';
import 'package:pantry/views/checklists/switcher_list_stage.dart';

import '../helpers/test_app.dart';

/// Templates feed checklists and inventories from Pantry 0.38.0 on: their
/// items are suggested in the add box, drawn one at a time, or applied whole.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
  const staples = 20;
  const eggs = 200;
  const milk = 201;
  const drawnEggs = 300;
  const openMilk = 400;

  Map<String, dynamic> list(int id, String name, String kind) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'kind': kind,
    'icon': 'list',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    if (kind != 'template') 'fillFromDefaults': true,
  };

  Map<String, dynamic> item(int id, int listId, String name) => {
    'id': id,
    'listId': listId,
    'name': name,
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
  };

  late List<http.Request> requests;
  late bool drawReuses;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final method = request.method;
    Object data = const <Object>[];
    if (method == 'POST' && path.endsWith('/lists/$groceries/items/draw')) {
      data = {
        'item': item(drawReuses ? openMilk : drawnEggs, groceries, 'Eggs'),
        'reused': drawReuses,
      };
    } else if (method == 'POST' && path.endsWith('/items/batch/copy')) {
      data = {
        'success': true,
        'items': [item(drawnEggs, groceries, 'Eggs')],
        'skipped': <int>[],
        'reused': <int>[],
      };
    } else if (method == 'PUT' &&
        path.endsWith('/lists/$groceries/templates')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = {
        'templateIds': body['templateIds'],
        'everyListTemplateIds': <int>[],
      };
    } else if (method == 'PATCH' && path.endsWith('/lists/$groceries')) {
      data = list(groceries, 'Groceries', 'checklist');
    } else if (method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [list(groceries, 'Groceries', 'checklist')];
    } else if (path.endsWith('/houses/1/templates')) {
      data = [list(staples, 'Weekly staples', 'template')];
    } else if (path.endsWith('/lists/$groceries/suggestions')) {
      data = {
        'archived': <Object>[],
        'templates': [
          {
            'item': item(eggs, staples, 'Eggs'),
            'templates': [
              {'id': staples, 'name': 'Weekly staples'},
            ],
          },
        ],
      };
    } else if (path.endsWith('/lists/$groceries/templates')) {
      data = {'templateIds': <int>[], 'everyListTemplateIds': <int>[]};
    } else if (path.endsWith('/lists/$groceries/items')) {
      data = [
        {...item(openMilk, groceries, 'Milk'), 'done': false},
      ];
    } else if (path.endsWith('/templates/$staples/items')) {
      data = [item(eggs, staples, 'Eggs'), item(milk, staples, 'milk ')];
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

  void seedVersion(String version) => ServerVersionService.instance.debugSeed(
    pantryVersion: Version.parse(version),
  );

  Iterable<http.Request> hits(String method, String suffix) =>
      requests.where((r) => r.method == method && r.url.path.endsWith(suffix));

  setUp(() async {
    requests = [];
    drawReuses = false;
    seedVersion('0.38.0');
    ChecklistService.instance.cacheListsOfEveryKind(1, const []);
    ChecklistService.instance.selectedListId = null;
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

  Future<ChecklistsController> loaded(WidgetTester tester) async {
    final controller = ChecklistsController(houseId: 1);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pump();
    return controller;
  }

  ChecklistList byId(ChecklistsController c, int id) =>
      c.lists.singleWhere((l) => l.id == id);

  testWidgets('a checklist loads its template suggestions once', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);

      expect(controller.drawsFromTemplates(groceries), isTrue);
      expect(controller.drawsFromTemplates(staples), isFalse);
      controller.ensureTemplateSuggestionsLoaded(groceries);
      controller.ensureTemplateSuggestionsLoaded(groceries);
      await tester.pump();

      final fetched = hits('GET', '/lists/$groceries/suggestions');
      expect(fetched, hasLength(1));
      expect(fetched.single.url.queryParameters['archived'], 'false');
      final rows = controller.templateSuggestions(groceries);
      expect(rows.single.item.id, eggs);
      expect(rows.single.templateNames, ['Weekly staples']);

      await quiesce(tester);
    });
  });

  testWidgets('older servers have no template suggestions', (tester) async {
    seedVersion('0.37.0');
    await withServer(() async {
      final controller = await loaded(tester);

      expect(controller.drawsFromTemplates(groceries), isFalse);
      controller.ensureTemplateSuggestionsLoaded(groceries);
      await tester.pump();
      expect(hits('GET', '/suggestions'), isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('drawing adds the copy to the list on screen', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      expect(controller.currentList?.id, groceries);

      final result = await controller.drawTemplateItem(
        eggs,
        targetListId: groceries,
      );

      expect(result.reused, isFalse);
      final body =
          jsonDecode(hits('POST', '/items/draw').single.body)
              as Map<String, dynamic>;
      expect(body, {'templateItemId': eggs});
      expect(controller.items.map((i) => i.id), contains(drawnEggs));

      await quiesce(tester);
    });
  });

  testWidgets('drawing a name already on the list replaces its row', (
    tester,
  ) async {
    drawReuses = true;
    await withServer(() async {
      final controller = await loaded(tester);
      final before = controller.items.length;

      final result = await controller.drawTemplateItem(
        eggs,
        targetListId: groceries,
      );

      expect(result.reused, isTrue);
      expect(controller.items, hasLength(before));
      expect(
        controller.items.singleWhere((i) => i.id == openMilk).name,
        'Eggs',
      );

      await quiesce(tester);
    });
  });

  testWidgets('changing attachments refetches suggestions', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      controller.ensureTemplateSuggestionsLoaded(groceries);
      await tester.pump();

      final saved = await controller.setAttachedTemplates(groceries, [staples]);
      expect(saved.templateIds, [staples]);
      expect(
        jsonDecode(hits('PUT', '/lists/$groceries/templates').single.body),
        {
          'templateIds': [staples],
        },
      );

      controller.ensureTemplateSuggestionsLoaded(groceries);
      await tester.pump();
      expect(hits('GET', '/lists/$groceries/suggestions'), hasLength(2));

      await quiesce(tester);
    });
  });

  testWidgets('the fill switch rides the queued item-defaults write', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);

      controller.updateItemDefaults(
        groceries,
        const ItemDefaultsPatch(fillFromDefaults: false),
      );

      expect(byId(controller, groceries).fillFromDefaults, isFalse);
      final op = manager.queueForTest.all().single;
      expect(op.op, SyncOpKind.setItemDefaults);
      expect(op.body, {'fillFromDefaults': false});

      await quiesce(tester);
    });
  });

  test('queued fill switches fold into the latest', () {
    const earlier = ItemDefaultsPatch(fillFromDefaults: false);
    const later = ItemDefaultsPatch(fillFromDefaults: true);
    expect(earlier.then(later).fillFromDefaults, isTrue);
    expect(later.then(const ItemDefaultsPatch()).fillFromDefaults, isTrue);
    expect(const ItemDefaultsPatch(fillFromDefaults: false).isValueOnly, false);
  });

  testWidgets('the add box offers template rows after the list\'s own', (
    tester,
  ) async {
    final picked = <(int, int)>[];
    Future<void> pumpBar(List<ListItem> own) => tester.pumpWidget(
      wrapForTest(
        ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: groceries,
          categories: const [],
          initiallyFocused: true,
          onSubmit: (_) async => true,
          reuseCandidates: own,
          buildReuseSuggestion: (item, onTap, fromTemplates) => GestureDetector(
            onTap: onTap,
            child: Text(
              fromTemplates == null
                  ? 'own ${item.name}'
                  : 'template ${item.name} ${fromTemplates.join(',')}',
            ),
          ),
          onReuseExisting: (_) async => true,
          templateSuggestions: [
            TemplateSuggestion(
              item: ListItem.fromJson(item(eggs, staples, 'Eggs')),
              templates: const [(id: staples, name: 'Weekly staples')],
            ),
          ],
          onTemplateSearchStarted: (_) {},
          onPickTemplateItem: (templateItem, targetListId) async {
            picked.add((templateItem.id, targetListId));
            return true;
          },
        ),
      ),
    );

    await pumpBar(const []);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'egg');
    await tester.pumpAndSettle();
    expect(find.text('template Eggs Weekly staples'), findsOneWidget);

    await tester.tap(find.text('template Eggs Weekly staples'));
    await tester.pumpAndSettle();
    expect(picked, [(eggs, groceries)]);

    // The list's own copy of a name wins over the template's.
    await pumpBar([ListItem.fromJson(item(openMilk, groceries, ' eggs'))]);
    await tester.enterText(find.byType(TextField).first, 'egg');
    await tester.pumpAndSettle();
    expect(find.text('own  eggs'), findsOneWidget);
    expect(find.textContaining('template'), findsNothing);
  });

  testWidgets('applying a template reviews its items and copies the ticked '
      'ones', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await tester.pumpWidget(
        wrapForTest(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showApplyTemplate(
                context,
                controller,
                byId(controller, staples),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(m.templates.applyToList), findsOneWidget);
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // "milk " is already an open item, so it starts unticked.
      expect(find.text(m.templates.alreadyOnList), findsOneWidget);
      final ticked = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .map((t) => t.value)
          .toList();
      expect(ticked, [true, false]);

      await tester.tap(find.text(m.templates.applyItems(1)));
      // Short of settling, which would run the toast out.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final body =
          jsonDecode(hits('POST', '/items/batch/copy').single.body)
              as Map<String, dynamic>;
      expect(body, {
        'itemIds': [eggs],
        'targetListId': groceries,
      });
      expect(controller.items.map((i) => i.id), contains(drawnEggs));
      expect(find.text(m.templates.appliedAdded(1, 'Groceries')), findsOne);
      await tester.pump(const Duration(seconds: 5));

      await quiesce(tester);
    });
  });

  testWidgets('the switcher offers applying from each list\'s menu', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await tester.pumpWidget(
        wrapForTest(
          ListStage(
            controller: controller,
            itemCountForList: (_) async => 0,
            onCreateNew: () {},
            onEdit: (_) {},
            onDuplicate: (_) {},
            onOpenTrash: () {},
            onOpenArchive: () {},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(m.templates.applyTemplate));
      await tester.pumpAndSettle();

      // Opened from a checklist, the sheet asks for the template.
      expect(find.text('Weekly staples'), findsOneWidget);

      await quiesce(tester);
    });
  });

  testWidgets('editing a checklist attaches the templates picked', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await tester.pumpWidget(
        wrapForTest(
          ListFormStage(
            controller: controller,
            existing: byId(controller, groceries),
            onBack: () {},
            onSaved: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(m.templates.attachedHint), findsOneWidget);
      final chip = find.widgetWithText(FilterChip, 'Weekly staples');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pump();
      await tester.tap(find.text(m.checklists.saveListButton));
      await tester.pumpAndSettle();

      expect(
        jsonDecode(hits('PUT', '/lists/$groceries/templates').single.body),
        {
          'templateIds': [staples],
        },
      );

      await quiesce(tester);
    });
  });
}
