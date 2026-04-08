import 'package:flutter/foundation.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/prefs_service.dart';

class HomeController extends ChangeNotifier {
  List<House> _houses = [];
  List<House> get houses => _houses;

  House? _currentHouse;
  House? get currentHouse => _currentHouse;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _houses = await HouseService.instance.getHouses();

      if (_houses.isEmpty) {
        _error = 'No houses found. Create one in Nextcloud first.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final lastId = PrefsService.instance.lastHouseId;
      _currentHouse =
          _houses.cast<House?>().firstWhere(
            (h) => h!.id == lastId,
            orElse: () => null,
          ) ??
          _houses.first;

      await PrefsService.instance.setLastHouseId(_currentHouse!.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[HomeController] Failed to load houses: $e');
      _error = 'Failed to load houses.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectHouse(House house) async {
    _currentHouse = house;
    await PrefsService.instance.setLastHouseId(house.id);
    notifyListeners();
  }
}
