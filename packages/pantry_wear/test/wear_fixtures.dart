import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';

/// Enough of a house to pump the checklists page against: two categories, a
/// handful of items each, and one already checked off.
ChecklistList testList({int id = 4, String name = 'Groceries'}) =>
    ChecklistList(
      id: id,
      houseId: 1,
      name: name,
      icon: 'shopping-cart',
      sortOrder: 0,
      createdAt: 0,
      updatedAt: 0,
    );

Category testCategory({
  required int id,
  required String name,
  String color = '#6FBF73',
  int sortOrder = 0,
}) => Category(
  id: id,
  houseId: 1,
  name: name,
  icon: 'vegetable',
  color: color,
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

ListItem testItem({
  required int id,
  required String name,
  int? categoryId,
  int listId = 4,
  bool done = false,
  String? quantity,
  List<int> storeIds = const [],
  List<int> labelIds = const [],
  bool deleteOnDone = false,
  String? rrule,
  int? imageFileId,
  String? imageUploadedBy,
}) => ListItem(
  id: id,
  listId: listId,
  name: name,
  categoryId: categoryId,
  storeIds: storeIds,
  labelIds: labelIds,
  quantity: quantity,
  done: done,
  rrule: rrule,
  imageFileId: imageFileId,
  imageUploadedBy: imageUploadedBy,
  repeatFromCompletion: false,
  deleteOnDone: deleteOnDone,
  sortOrder: id,
  createdAt: 0,
  updatedAt: 0,
);

/// The synthetic entry the watch scopes to when it is showing every list at
/// once — the one browse scope in which a row's own list is worth naming.
ChecklistList testAllLists() => ChecklistList(
  id: kAllListsId,
  houseId: 1,
  name: 'All lists',
  icon: 'all-lists',
  sortOrder: -1 << 30,
  createdAt: 0,
  updatedAt: 0,
);

Store testStore({
  required int id,
  required String name,
  String color = '#5BA8E0',
  int sortOrder = 0,
}) => Store(
  id: id,
  houseId: 1,
  name: name,
  icon: 'supermarket',
  color: color,
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

/// A live trip, so the pager swaps to its five sections.
///
/// [storeIds] are its legs in position order; left out, the trip has only the
/// leg it is standing at.
ShoppingSession testSession({
  int? activeStoreId,
  List<int> storeIds = const [],
  double? billedTotal,
  String? billedCurrency,
  Map<int, double> billedByStore = const {},
}) {
  final legs = storeIds.isNotEmpty ? storeIds : [?activeStoreId];
  return ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'casraf',
    listIds: const [4],
    stores: [
      for (var i = 0; i < legs.length; i++)
        ShoppingSessionStore(
          storeId: legs[i],
          position: i,
          billedTotal: billedByStore[legs[i]],
          billedCurrency: billedByStore.containsKey(legs[i]) ? 'USD' : null,
        ),
    ],
    activeStoreId: activeStoreId,
    includeUnassigned: true,
    isPrivate: false,
    billedTotal: billedTotal,
    billedCurrency: billedCurrency,
    lastSeenAt: 0,
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );
}

/// The bought log a trip's summary is drawn from, one bucket per store —
/// [storeId] null being the storeless one the session's own total covers.
ShoppingReview testReview(
  List<({int? storeId, List<ListItem> items})> buckets,
) => ShoppingReview(
  stores: [
    for (final bucket in buckets)
      ShoppingReviewStore(
        storeId: bucket.storeId,
        items: bucket.items,
        estimate: const [],
        noPriceCount: 0,
      ),
  ],
  grandTotal: const [],
  uncheckedCount: 0,
);

Photo testPhoto({
  required int id,
  String? caption,
  int? folderId,
  String uploadedBy = 'dana',
  int createdAt = 0,
}) => Photo(
  id: id,
  houseId: 1,
  folderId: folderId,
  fileId: 1000 + id,
  caption: caption,
  uploadedBy: uploadedBy,
  sortOrder: id,
  createdAt: createdAt,
  updatedAt: createdAt,
);

PhotoFolder testPhotoFolder({
  required int id,
  required String name,
  int sortOrder = 0,
}) => PhotoFolder(
  id: id,
  houseId: 1,
  name: name,
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

/// Bring the row labelled [label] within reach of a tap, and hand back its
/// finder.
///
/// Two things stand between a row and a test that taps it. A watch list opens
/// with its first row on the centre line, so all but a couple of rows start
/// below the fold and a sliver never builds one that is; and a row that has
/// scrolled into view at the edge of a round screen is drawn as narrow as the
/// glass is there, which is not yet a target. Both are what a wearer's thumb
/// does about it: scroll until it exists, then bring it in to the centre line.
Future<Finder> revealRow(WidgetTester tester, String label) async {
  final row = find.text(label);
  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(row, 54, scrollable: scrollable);
  await tester.pumpAndSettle();

  final centre = tester.getRect(scrollable).center.dy;
  for (var step = 0; step < 12; step++) {
    final dy = tester.getCenter(row).dy - centre;
    if (dy.abs() <= 27) break;
    await tester.drag(scrollable, Offset(0, dy > 0 ? -54 : 54));
    await tester.pumpAndSettle();
  }
  return row;
}
