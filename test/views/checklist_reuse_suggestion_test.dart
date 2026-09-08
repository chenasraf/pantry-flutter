import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/checklists/checklists_body_controller.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

// Tapping a live reuse suggestion is an explicit request to reuse that one
// item, so the reuse pref only decides whether it is confirmed first.

void main() {
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  late ChecklistsController domain;
  late ChecklistsBodyController body;

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'read':
              return storage[args['key'] as String];
            case 'write':
              storage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
          }
          return null;
        });
    // A reuse enqueues a sync op; offline it stays queued instead of failing
    // against no server and leaving a retry timer behind.
    SyncManager.instance.setOnline(false);
    domain = ChecklistsController(houseId: 1);
    body = ChecklistsBodyController(
      domain: domain,
      scrollController: null,
      appBarSpecHolder: null,
    );
  });

  tearDown(() async {
    body.dispose();
    domain.dispose();
    await PrefsService.instance.clear();
    ServerVersionService.instance.debugSeed();
    SyncManager.instance.setOnline(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  Future<void> seed(String mode, {bool featureAvailable = true}) async {
    ServerVersionService.instance.debugSeed(
      features: {if (featureAvailable) 'reuse-existing-items': true},
      featuresAuthoritative: true,
    );
    await PrefsService.instance.setReuseExistingItemsCache(mode);
  }

  /// Taps a suggestion for [item] and returns the pending result without
  /// settling, so a test can assert on the dialog before answering it.
  Future<Future<bool>> tapSuggestion(WidgetTester tester, ListItem item) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      wrapForTest(
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final result = body.reuseFromSuggestion(ctx, item);
    await tester.pump();
    return result;
  }

  /// Lets the snackbar's auto-dismiss timer run out so none outlives the test.
  Future<void> settleSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('ask mode confirms before reusing', (tester) async {
    await seed('ask');
    final item = makeListItem(name: 'Milk', done: true);

    final result = await tapSuggestion(tester, item);
    expect(find.text(m.checklists.reuse.dialogTitle), findsOneWidget);

    await tester.tap(find.text(m.checklists.reuse.reuseExisting));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(
      find.text(m.checklists.reuse.reusedSnack(item.name)),
      findsOneWidget,
    );
    await settleSnackBar(tester);
  });

  testWidgets('ask mode reuses nothing on cancel', (tester) async {
    await seed('ask');
    final item = makeListItem(name: 'Milk', done: true);

    final result = await tapSuggestion(tester, item);
    await tester.tap(find.text(m.common.cancel));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(find.text(m.checklists.reuse.reusedSnack(item.name)), findsNothing);
  });

  testWidgets('reuse mode reuses without a dialog', (tester) async {
    await seed('reuse');
    final item = makeListItem(name: 'Milk', done: true);

    final result = await tapSuggestion(tester, item);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await result, isTrue);
    expect(
      find.text(m.checklists.reuse.reusedSnack(item.name)),
      findsOneWidget,
    );
    await settleSnackBar(tester);
  });

  testWidgets('never mode reuses without a dialog', (tester) async {
    await seed('never');
    final item = makeListItem(name: 'Milk', done: true);

    final result = await tapSuggestion(tester, item);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await result, isTrue);
    expect(
      find.text(m.checklists.reuse.reusedSnack(item.name)),
      findsOneWidget,
    );
    await settleSnackBar(tester);
  });

  testWidgets('reuse mode unarchives an archived suggestion without a dialog', (
    tester,
  ) async {
    await seed('reuse');
    final item = makeListItem(name: 'Milk', done: true, archivedAt: 1000);

    final result = await tapSuggestion(tester, item);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(await result, isTrue);
    expect(
      domain.items.where((i) => i.id == item.id && i.archivedAt == null),
      hasLength(1),
    );
    expect(
      find.text(m.checklists.reuse.reusedArchivedSnack(item.name)),
      findsOneWidget,
    );
    await settleSnackBar(tester);
  });

  testWidgets('confirms when the server lacks the reuse capability', (
    tester,
  ) async {
    await seed('reuse', featureAvailable: false);
    final item = makeListItem(name: 'Milk', done: true);

    final result = await tapSuggestion(tester, item);
    expect(find.text(m.checklists.reuse.dialogTitle), findsOneWidget);

    await tester.tap(find.text(m.checklists.reuse.reuseExisting));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    await settleSnackBar(tester);
  });
}
