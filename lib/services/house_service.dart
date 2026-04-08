import 'package:pantry/models/house.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

class HouseService {
  HouseService._();
  static final HouseService instance = HouseService._();

  final cache = CacheStore('house_cache.json');

  static const _housesKey = 'houses';

  List<House>? getCached() => cache.getList(_housesKey, House.fromJson);

  Future<List<House>> getHouses() async {
    final houses = await ApiClient.instance.get<List, List<House>>(
      '/houses',
      fromJson: (data) =>
          data.map((e) => House.fromJson(e as Map<String, dynamic>)).toList(),
    );
    cache.setList(_housesKey, houses, (h) => h.toJson());
    return houses;
  }
}
