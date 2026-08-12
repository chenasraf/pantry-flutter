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

  Future<void> setStoreSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'storeSort': sort},
      fromJson: (_) {},
    );
  }

  Future<void> reorderStores(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/stores/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  /// Sort stores according to a sort mode (name_asc, name_desc, custom).
  /// Returns a new list; the input is not mutated.
  static List<Store> sortStores(Iterable<Store> stores, String sort) {
    final list = stores.toList();
    // Fall back to id (creation order) as a final tiebreaker: fresh stores
    // share the same sortOrder until reordered, so without it the custom list
    // would reshuffle unpredictably as stores are added.
    switch (sort) {
      case 'name_desc':
        list.sort((a, b) {
          final c = b.name.toLowerCase().compareTo(a.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'custom':
        list.sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'name_asc':
      default:
        list.sort((a, b) {
          final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    }
    return list;
  }

  Future<Store> createStore(
    int houseId, {
    required String name,
    required String icon,
    required String color,
    String? brand,
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
        'brand': ?brand,
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
    String? brand,
    String? location,
    List<OpeningHoursInterval>? openingHours,
    String? contact,
    String? responsible,
    String? notes,
    int? sortOrder,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, Store>(
      '/houses/$houseId/stores/$storeId',
      body: {
        'name': ?name,
        'icon': ?icon,
        'color': ?color,
        'brand': ?brand,
        'location': ?location,
        'openingHours': ?openingHours?.map((e) => e.toJson()).toList(),
        'contact': ?contact,
        'responsible': ?responsible,
        'notes': ?notes,
        'sortOrder': ?sortOrder,
      },
      fromJson: (data) => Store.fromJson(data),
    );
  }

  Future<void> deleteStore(int houseId, int storeId) async {
    await ApiClient.instance.delete('/houses/$houseId/stores/$storeId');
  }
}
