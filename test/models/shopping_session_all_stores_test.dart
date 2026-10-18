import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/shopping_session.dart';

void main() {
  Map<String, dynamic> sessionJson({bool? allStores}) => {
    'id': 12,
    'houseId': 1,
    'userId': 'dana',
    'listIds': [4],
    'stores': [
      {'storeId': 7, 'position': 0},
      {'storeId': 8, 'position': 1},
    ],
    'activeStoreId': null,
    'includeUnassigned': true,
    'isPrivate': false,
    'lastSeenAt': 0,
    'live': true,
    'createdAt': 0,
    'updatedAt': 0,
    'allStores': ?allStores,
  };

  test('reads an all-stores trip', () {
    expect(
      ShoppingSession.fromJson(sessionJson(allStores: true)).allStores,
      isTrue,
    );
  });

  test('a server that never sends the flag walks store by store', () {
    expect(ShoppingSession.fromJson(sessionJson()).allStores, isFalse);
  });

  test('round-trips the flag through the cache', () {
    final session = ShoppingSession.fromJson(sessionJson(allStores: true));

    expect(ShoppingSession.fromJson(session.toJson()).allStores, isTrue);
  });

  test('an all-stores trip has no next store to move to', () {
    expect(
      ShoppingSession.fromJson(sessionJson(allStores: true)).nextStoreId,
      isNull,
    );
  });

  test('a store-by-store trip not yet at a store starts at its first', () {
    expect(ShoppingSession.fromJson(sessionJson()).nextStoreId, 7);
  });
}
