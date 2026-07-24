import 'package:pantry/models/store.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

class StoreService {
  StoreService._();
  static final StoreService instance = StoreService._();

  final cache = CacheStore('store_cache.json');

  static const _prefix = 'stores';

  List<Store>? getCached(int houseId) =>
      cache.getKeyedList(_prefix, '$houseId', Store.fromJson);

  Future<List<Store>> getStores(int houseId) async {
    final stores = await ApiClient.instance.get<List, List<Store>>(
      '/houses/$houseId/stores',
      fromJson: (data) =>
          data.map((e) => Store.fromJson(e as Map<String, dynamic>)).toList(),
    );
    cache.setKeyedList(_prefix, '$houseId', stores, (s) => s.toJson());
    return stores;
  }

  /// Sort stores by name A→Z. Stores have no custom sort; the server always
  /// returns them name-ordered, but re-sorting after an optimistic create keeps
  /// the local list consistent. Returns a new list; the input is not mutated.
  static List<Store> sortStores(Iterable<Store> stores) {
    final list = stores.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<Store> createStore(
    int houseId, {
    required String name,
    required String icon,
    required String color,
    String? location,
    List<OpeningHoursInterval>? openingHours,
    String? contact,
    String? responsible,
    String? notes,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, Store>(
      '/houses/$houseId/stores',
      body: {
        'name': name,
        'icon': icon,
        'color': color,
        'location': ?location,
        'openingHours': ?openingHours?.map((e) => e.toJson()).toList(),
        'contact': ?contact,
        'responsible': ?responsible,
        'notes': ?notes,
      },
      fromJson: (data) => Store.fromJson(data),
    );
  }

  Future<Store> updateStore(
    int houseId,
    int storeId, {
    String? name,
    String? icon,
    String? color,
    String? location,
    List<OpeningHoursInterval>? openingHours,
    String? contact,
    String? responsible,
    String? notes,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, Store>(
      '/houses/$houseId/stores/$storeId',
      body: {
        'name': ?name,
        'icon': ?icon,
        'color': ?color,
        'location': ?location,
        'openingHours': ?openingHours?.map((e) => e.toJson()).toList(),
        'contact': ?contact,
        'responsible': ?responsible,
        'notes': ?notes,
      },
      fromJson: (data) => Store.fromJson(data),
    );
  }

  Future<void> deleteStore(int houseId, int storeId) async {
    await ApiClient.instance.delete('/houses/$houseId/stores/$storeId');
  }
}
