import 'package:pantry/models/house.dart';
import 'package:pantry/services/api_client.dart';

class HouseService {
  HouseService._();
  static final HouseService instance = HouseService._();

  Future<List<House>> getHouses() async {
    return ApiClient.instance.get<List, List<House>>(
      '/houses',
      fromJson: (data) =>
          data.map((e) => House.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
