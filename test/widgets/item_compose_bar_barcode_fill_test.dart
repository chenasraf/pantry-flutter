import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/barcode_service.dart';
import 'package:pantry/views/checklists/barcode_scanner/manual_barcode_dialog.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

class _FakeBarcodeService extends BarcodeService {
  _FakeBarcodeService() : super.forTesting();

  final downloads = <String>[];

  @override
  Future<BarcodeResult?> lookup(String ean) async => BarcodeResult(
    ean: ean,
    name: 'Chocolate Bar',
    provider: 'openfoodfacts',
    category: 'Snacks',
    imageUrl: 'https://example.test/product.jpg',
  );

  @override
  Future<List<int>?> downloadImage(String url) async {
    downloads.add(url);
    return const [1, 2, 3];
  }
}

void main() {
  const ean = '4001724819103';
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final prefs = PrefsService.instance;
  late _FakeBarcodeService barcodes;

  Future<void> setFill({
    bool name = true,
    bool category = true,
    bool image = true,
  }) async {
    await prefs.setBarcodeFillNameCache(name);
    await prefs.setBarcodeFillCategoryCache(category);
    await prefs.setBarcodeFillImageCache(image);
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
    barcodes = _FakeBarcodeService();
    BarcodeService.debugOverride = barcodes;
  });

  tearDown(() async {
    await setFill();
    BarcodeService.debugOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  Finder nameField() => find
      .descendant(
        of: find.byType(ItemComposeBar),
        matching: find.byType(TextField),
      )
      .first;

  String nameText(WidgetTester tester) =>
      tester.widget<TextField>(nameField()).controller!.text;

  /// Pumps the bar and enters [ean] through the manual entry dialog. With
  /// [typedAfterScan], that name is typed once the scan has prefilled — a scan
  /// that fills no name leaves nothing to submit otherwise. Then submits,
  /// returning what the bar handed to `onSubmit`.
  Future<ComposeSubmission> scanAndSubmit(
    WidgetTester tester, {
    String? typedAfterScan,
    void Function()? afterScan,
  }) async {
    ComposeSubmission? submitted;
    await tester.pumpWidget(
      wrapForTest(
        ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: 1,
          categories: [makeCategory(id: 7, name: 'Snacks')],
          initiallyFocused: true,
          onSubmit: (s) async {
            submitted = s;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(m.checklists.barcode.manualTitle));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(ManualBarcodeDialog),
        matching: find.byType(TextField),
      ),
      ean,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(ManualBarcodeDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
    afterScan?.call();
    if (typedAfterScan != null) {
      await tester.enterText(nameField(), typedAfterScan);
    }

    await tester.showKeyboard(nameField());
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    return submitted!;
  }

  testWidgets('fills name, category and image when every field is enabled', (
    tester,
  ) async {
    final s = await scanAndSubmit(tester);

    expect(s.name, 'Chocolate Bar');
    expect(s.categoryId, 7);
    expect(s.imageBytes, isNotNull);
    expect(barcodes.downloads, ['https://example.test/product.jpg']);
  });

  testWidgets('leaves the name empty when name filling is disabled', (
    tester,
  ) async {
    await setFill(name: false);

    final s = await scanAndSubmit(
      tester,
      afterScan: () => expect(nameText(tester), isEmpty),
      typedAfterScan: 'Own wording',
    );

    expect(s.name, 'Own wording');
    expect(s.categoryId, 7);
    expect(s.imageBytes, isNotNull);
  });

  testWidgets('skips the category match when category filling is disabled', (
    tester,
  ) async {
    await setFill(category: false);

    final s = await scanAndSubmit(tester);

    expect(s.categoryId, isNull);
    expect(s.name, 'Chocolate Bar');
  });

  testWidgets('never downloads the image when image filling is disabled', (
    tester,
  ) async {
    await setFill(image: false);

    final s = await scanAndSubmit(tester);

    expect(barcodes.downloads, isEmpty);
    expect(s.imageBytes, isNull);
    expect(s.name, 'Chocolate Bar');
  });

  testWidgets('still records the barcode when every detail is disabled', (
    tester,
  ) async {
    await setFill(name: false, category: false, image: false);

    final s = await scanAndSubmit(
      tester,
      afterScan: () => expect(nameText(tester), isEmpty),
      typedAfterScan: 'Own wording',
    );

    expect(s.barcode, ean);
    expect(s.name, 'Own wording');
    expect(s.categoryId, isNull);
    expect(s.imageBytes, isNull);
  });
}
