import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/photos/photo_route.dart';
import 'package:pantry_wear/src/photos/photos_controller.dart';
import 'package:pantry_wear/src/photos/photos_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/preview_sizes.dart';

import 'wear_fixtures.dart';

/// The checks the photos page earned.
///
/// Everything here analysed clean before it was pumped, which is the whole
/// reason the page has tests at all: a watch layout fails by drawing the wrong
/// thing quietly, not by throwing.
///
/// No image cache is installed, so every preview fails to resolve — which is
/// exactly the offline board, and the state the grid has to keep its shape in.
void main() {
  final folders = [
    testPhotoFolder(id: 7, name: 'House'),
    testPhotoFolder(id: 8, name: 'Receipts', sortOrder: 1),
  ];
  final photos = [
    testPhoto(id: 1, caption: 'Fridge shelf'),
    testPhoto(id: 2, caption: 'Spare key'),
    testPhoto(id: 3, caption: 'Boiler dial'),
    testPhoto(id: 5, caption: 'Front door', folderId: 7),
    testPhoto(id: 6, caption: 'Boxed heater', folderId: 7),
  ];

  PhotosController seeded({bool foldersFirst = true}) =>
      PhotosController.seeded(
        houseId: 1,
        folders: folders,
        photos: photos,
        foldersFirst: foldersFirst,
      );

  Widget host(PhotosController controller) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: PhotosPage(controller: controller, active: true, rotary: true),
    ),
  );

  /// A watch-sized window, so a pushed route gets watch geometry too rather
  /// than the 800×600 a test window defaults to.
  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder tile(int id) => find.byKey(ValueKey('photo-$id'));

  /// How many lists are listening to the crown. The detent stream is broadcast
  /// and a covered list stays mounted, so this is the number that must never
  /// exceed one.
  /// Offstage is not skipped: a route pushed over the board takes the board
  /// offstage but leaves it mounted and subscribed, which is the entire thing
  /// being counted.
  int rotaryListeners(WidgetTester tester) => tester
      .widgetList<SnapFocusList>(
        find.byType(SnapFocusList, skipOffstage: false),
      )
      .where((list) => list.rotaryActive)
      .length;

  tearDown(() => WearShape.markFrom(['round']));

  testWidgets('the board draws on both screen shapes', (tester) async {
    sizeToWatch(tester);
    for (final shape in ['round', 'square']) {
      WearShape.markFrom([shape]);
      await tester.pumpWidget(host(seeded()));
      await tester.pumpAndSettle();

      // Folders come first, then the photos that sit outside any of them.
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
      expect(tile(1), findsOneWidget);
      // A photo inside a folder is not on the board.
      expect(tile(5), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the house decides which end the folders go', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded(foldersFirst: false)));
    await tester.pumpAndSettle();

    // `photoFoldersFirst` is a house pref, so the watch orders the board the
    // way the household's phone does — folders last is a real setting, not a
    // state the watch can end up in by itself.
    expect(tile(1), findsOneWidget);
    // The board now opens on a photo row, so its captions are drawn.
    expect(find.text('Fridge shelf'), findsOneWidget);
  });

  testWidgets('an off-centre tap scrolls, and the centred row opens', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // The board opens on the folder row, so the first photo row is below the
    // centre line and carries no caption — eight captions at once is the thing
    // being avoided.
    expect(find.text('Fridge shelf'), findsNothing);

    await tester.tap(tile(1));
    await tester.pumpAndSettle();

    // A mis-aim costs a scroll, never a route.
    expect(find.byType(PhotoRoute), findsNothing);
    // Having arrived on the centre line, the row now says what it holds.
    expect(find.text('Fridge shelf'), findsOneWidget);

    await tester.tap(tile(1));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoRoute), findsOneWidget);
  });

  testWidgets('the tapped tile opens, not the row', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // Centre the row, then act on its second tile: the row is the focus unit,
    // but horizontally the two tiles are large targets and the one under the
    // finger is unambiguous.
    await tester.tap(tile(2));
    await tester.pumpAndSettle();
    await tester.tap(tile(2));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoRoute), findsOneWidget);
    expect(find.text('Spare key'), findsOneWidget);
    expect(find.text('Fridge shelf'), findsNothing);
  });

  testWidgets('a folder opens as a route that takes the crown', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    expect(rotaryListeners(tester), 1);

    // The first folder is the focused row on a board that has just opened, so
    // one tap is enough.
    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoFolderRoute), findsOneWidget);
    // The board underneath stays mounted — that is the whole hazard, and the
    // reason the count below means something: two lists exist, one listens. If
    // the covered one kept its subscription, a single turn of the bezel would
    // scroll both it and the folder sitting over it.
    expect(find.byType(SnapFocusList, skipOffstage: false), findsNWidgets(2));
    expect(rotaryListeners(tester), 1);

    // The folder's photos, and none of the root's.
    expect(tile(5), findsOneWidget);
    expect(tile(1), findsNothing);
  });

  testWidgets('an unavailable photo keeps its slot', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(seeded()));
    await tester.pumpAndSettle();

    // Hiding a photo the watch cannot draw would move every tile after it
    // between online and offline, so the grid keeps the slot and marks it.
    for (final photo in photos.where((p) => p.folderId == null)) {
      expect(tile(photo.id), findsOneWidget);
    }
    expect(find.byIcon(Icons.cloud_off_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a photo opens at fit and double-taps back to it', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoRoute(photo: photos.first, houseId: 1)),
    );
    await tester.pumpAndSettle();

    final view = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    expect(view.value.getMaxScaleOnAxis(), 1);

    Future<void> doubleTap() async {
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();
    }

    // The crown and pinch are the other two ways in; the double tap is the one
    // every Wear device has.
    await doubleTap();
    expect(view.value.getMaxScaleOnAxis(), greaterThan(1));

    await doubleTap();
    // Fit is the way back out, so the double tap has to reach it exactly —
    // short of it, the leading edge stays a pan and the wearer is stuck.
    expect(view.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a double tap travels rather than cutting', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoRoute(photo: photos.first, houseId: 1)),
    );
    await tester.pumpAndSettle();

    final view = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byType(InteractiveViewer));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    // Caught in flight: a cut between two magnifications leaves the eye to
    // work out where in the photo it has landed.
    final midway = view.value.getMaxScaleOnAxis();
    expect(midway, greaterThan(1));
    expect(midway, lessThan(2.5));

    await tester.pumpAndSettle();
    expect(view.value.getMaxScaleOnAxis(), closeTo(2.5, 0.001));
  });

  testWidgets('the zoom badge tracks the zoom it names', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoRoute(photo: photos.first, houseId: 1)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InteractiveViewer));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byType(InteractiveViewer));
    await tester.pumpAndSettle();

    // The route itself rebuilds only when the zoom crosses a threshold, so a
    // badge that read the transform at build time would stop at whatever the
    // last crossing left behind and go on claiming it.
    expect(find.text('2.5×'), findsOneWidget);
  });

  testWidgets('a tile asks for a tile, and a screen for a screen', (
    tester,
  ) async {
    sizeToWatch(tester);
    late int tileSize;
    late int fitSize;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            tileSize = WearPreviewSize.tile(context);
            fitSize = WearPreviewSize.fit(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // Two tiles to a row, so a tile is worth about half a screen — and the
    // ladder is what keeps the falloff's own scaling from inventing a new URL
    // per frame.
    expect(tileSize, lessThan(fitSize));
    expect(fitSize, lessThanOrEqualTo(WearPreviewSize.max));
    for (final size in [tileSize, fitSize, WearPreviewSize.zoomed]) {
      expect(size & (size - 1), 0, reason: '$size is not a rung');
    }
  });
}
