import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/api_client.dart';
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

  /// True when the Pantry server app is not installed on the user's
  /// Nextcloud instance (API returns 404).
  bool _serverAppMissing = false;
  bool get serverAppMissing => _serverAppMissing;

  Future<void> load() async {
    _error = null;
    _serverAppMissing = false;

    // Restore from cache
    final cached = HouseService.instance.getCached();
    if (cached != null && _houses.isEmpty) {
      _houses = cached;
      _restoreSelection();
      _isLoading = false;
      notifyListeners();
    }

    if (_houses.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _houses = await HouseService.instance.getHouses();

      if (_houses.isEmpty) {
        _error = m.home.noHouses;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _restoreSelection();
      await PrefsService.instance.setLastHouseId(_currentHouse!.id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[HomeController] Failed to load houses: $e');
      if (_houses.isEmpty) {
        if (e is ApiException && e.statusCode == 404) {
          _serverAppMissing = true;
        } else {
          _error = m.home.failedToLoadHouses;
        }
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _restoreSelection() {
    final lastId = PrefsService.instance.lastHouseId;
    _currentHouse =
        (lastId != null
            ? _houses.cast<House?>().firstWhere(
                (h) => h!.id == lastId,
                orElse: () => null,
              )
            : null) ??
        _houses.first;
  }

  Future<void> selectHouse(House house) async {
    _currentHouse = house;
    await PrefsService.instance.setLastHouseId(house.id);
    notifyListeners();
  }
}
