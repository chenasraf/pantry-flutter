import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
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
}) => ListItem(
  id: id,
  listId: listId,
  name: name,
  categoryId: categoryId,
  storeIds: storeIds,
  quantity: quantity,
  done: done,
  repeatFromCompletion: false,
  deleteOnDone: false,
  sortOrder: id,
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
ShoppingSession testSession({int? activeStoreId}) => ShoppingSession(
  id: 12,
  houseId: 1,
  userId: 'casraf',
  listIds: const [4],
  stores: [
    if (activeStoreId != null)
      ShoppingSessionStore(storeId: activeStoreId, position: 0),
  ],
  activeStoreId: activeStoreId,
  includeUnassigned: true,
  isPrivate: false,
  lastSeenAt: 0,
  live: true,
  createdAt: 0,
  updatedAt: 0,
);
