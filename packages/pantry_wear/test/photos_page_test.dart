import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/prototype/focus_list.dart';
import 'package:pantry_wear/src/prototype/photos_page.dart';
import 'package:pantry_wear/src/prototype/proto_photo_data.dart';
import 'package:pantry_wear/src/prototype/proto_tuning.dart';
import 'package:pantry_wear/src/wear_shape.dart';

/// The checks the photos page earned.
///
/// Everything here analysed clean before it was pumped, which is the whole
/// reason the page has tests at all: a watch layout fails by drawing the wrong
/// thing quietly, not by throwing.
void main() {
  Widget host(ProtoTuning tuning) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: PhotosPage(tuning: tuning, active: true),
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
      await tester.pumpWidget(host(ProtoTuning()));
      await tester.pumpAndSettle();

      // Folders come first, then the photos that sit outside any of them.
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
      expect(tile(1), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('an off-centre tap scrolls, and the centred row opens', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(ProtoTuning()));
    await tester.pumpAndSettle();

    // The board opens on the first folder, so the first photo row is below the
    // centre line and carries no caption — eight captions at once is the thing
    // being avoided.
    expect(find.text('Fridge shelf'), findsNothing);

    await tester.tap(tile(1));
    await tester.pumpAndSettle();

    // A mis-aim costs a scroll, never a write or a route.
    expect(find.byType(PhotoRoute), findsNothing);
    // Having arrived on the centre line, the row now says what it holds.
    expect(find.text('Fridge shelf'), findsOneWidget);

    await tester.tap(tile(1));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoRoute), findsOneWidget);
  });

  testWidgets('the tapped tile opens, not the row', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(host(ProtoTuning()));
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
    await tester.pumpWidget(host(ProtoTuning()));
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
    await tester.pumpWidget(host(ProtoTuning()..offline = true));
    await tester.pumpAndSettle();

    // Hiding a photo the watch cannot draw would move every tile after it
    // between online and offline, so the grid keeps the slot and marks it.
    final uncached = protoPhotosIn(null).where((p) => !p.cached).toList();
    expect(uncached, isNotEmpty);
    for (final photo in uncached) {
      expect(tile(photo.id), findsOneWidget);
    }
    expect(
      find.byIcon(Icons.cloud_off_outlined),
      findsNWidgets(uncached.length),
    );
    expect(find.byIcon(Icons.image_outlined), findsNWidgets(uncached.length));
  });

  testWidgets('a photo opens at fit and double-taps back to it', (
    tester,
  ) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(home: PhotoRoute(photo: protoPhotos.first, available: true)),
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
      MaterialApp(home: PhotoRoute(photo: protoPhotos.first, available: true)),
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
}
