import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/photos/photo_detail_page.dart';
import 'package:pantry_wear/src/photos/photo_route.dart';
import 'package:pantry_wear/src/photos/photos_controller.dart';
import 'package:pantry_wear/src/photos/photos_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/image_route.dart';
import 'package:pantry_wear/src/widgets/preview_image.dart';
import 'package:pantry_wear/src/widgets/wear_detail.dart';

import 'wear_fixtures.dart';

/// What the board and the viewer cannot say for themselves.
///
/// No credentials are installed, so every preview fails to resolve — which is
/// the offline board, and the state the detail page has to draw in too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.casraf.pantry/wear_host');
  final handoffs = <String>[];

  setUp(() {
    WearShape.markFrom(['round']);
    handoffs.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'openOnPhone') {
            handoffs.add((call.arguments as Map)['url'] as String);
          }
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  final photos = [
    testPhoto(id: 1, caption: 'Boiler dial', uploadedBy: 'dana'),
    testPhoto(id: 2, caption: 'Spare key', uploadedBy: 'sam'),
    testPhoto(id: 3, caption: 'Front door'),
  ];

  PhotosController seeded() =>
      PhotosController.seeded(houseId: 4, photos: photos);

  Widget host(PhotosController controller) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: PhotosPage(controller: controller, active: true, rotary: true),
    ),
  );

  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder tile(int id) => find.byKey(ValueKey('photo-$id'));

  /// The hand-off sits under the facts, which on a watch is past the fold.
  Future<void> reachHandoff(WidgetTester tester) async {
    final button = find.byType(OpenOnPhoneButton);
    await tester.scrollUntilVisible(
      button,
      60,
      scrollable: find.byType(Scrollable).last,
    );
    // Built is not the same as reachable: the list stops the moment the button
    // exists, which on a round screen is with it still off the bottom.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the page draws on both screen shapes', (tester) async {
    sizeToWatch(tester);
    for (final shape in ['round', 'square']) {
      WearShape.markFrom([shape]);
      await tester.pumpWidget(
        MaterialApp(home: PhotoDetailPage(photo: photos[0], houseId: 4)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Boiler dial'), findsOneWidget);
      expect(find.text('dana'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a hold on a tile says who added it and when', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.longPress(tile(1));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoDetailPage), findsOneWidget);
    expect(find.text('Boiler dial'), findsOneWidget);
    expect(find.text('dana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('and hands the phone the photo, not the board', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.longPress(tile(1));
    await tester.pumpAndSettle();
    await reachHandoff(tester);
    await tester.tap(find.byType(OpenOnPhoneButton));
    await tester.pumpAndSettle();

    expect(handoffs, ['pantry://photo/4/1']);
  });

  testWidgets('a hold on an off-centre row costs a scroll, never a page', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // The third photo is on the second row, below the centre line on a board
    // that has just opened.
    await tester.longPress(tile(3));
    await tester.pumpAndSettle();
    expect(
      find.byType(PhotoDetailPage),
      findsNothing,
      reason:
          'a mis-aimed hold must cost a scroll, the same as a mis-aimed tap',
    );

    await tester.longPress(tile(3));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoDetailPage), findsOneWidget);
  });

  testWidgets('a hold on the viewer opens it too, and takes the crown', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    await tester.tap(tile(1));
    await tester.pumpAndSettle();
    expect(find.byType(ImageRoute), findsOneWidget);
    expect(tester.widget<ImageRoute>(find.byType(ImageRoute)).rotary, isTrue);

    await tester.longPress(find.byType(ImageRoute));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoDetailPage), findsOneWidget);
    // The viewer stays mounted under the page — that is the hazard. The detent
    // stream is broadcast, so a viewer that kept its subscription would zoom a
    // photo nobody is looking at on every turn of the bezel.
    expect(
      tester
          .widget<ImageRoute>(find.byType(ImageRoute, skipOffstage: false))
          .rotary,
      isFalse,
    );
  });

  testWidgets('a photo with no caption still says who added it', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoDetailPage(photo: testPhoto(id: 9), houseId: 4)),
    );
    await tester.pumpAndSettle();

    expect(find.text('dana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hold on the viewer leaves the photo one tap away', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoRoute(photo: photos[0], houseId: 4)),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(ImageRoute));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoDetailPage), findsOneWidget);

    // Tapping the preview goes back to the photo underneath rather than
    // stacking a second copy of it on top.
    await tester.tap(
      find
          .descendant(
            of: find.byType(PhotoDetailPage),
            matching: find.byType(ImageUnavailable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoDetailPage), findsNothing);
    expect(find.byType(ImageRoute), findsOneWidget);
  });
}
