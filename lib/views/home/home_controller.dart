import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';

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
        _currentHouse = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // The account's last-opened house has to land before the selection is
      // restored: falling back to the first house writes that fallback
      // locally, and a device with a house of its own no longer adopts
      // anything. Bounded because the home screen waits on it.
      if (PrefsService.instance.lastHouseId == null ||
          PrefsService.instance.syncLastHouse) {
        await AuthService.instance.fetchUserPrefs().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }

      _restoreSelection();
      await _persistSelection();

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

  /// Records the open house on this device, and — for a device following the
  /// account — tells the account, so the web app and the user's other devices
  /// open the same one. Only a house this device actually moved to is worth
  /// publishing; one it just adopted is already the account's. The publish is
  /// not awaited: nothing on screen depends on it, and it is allowed to fail.
  Future<void> _persistSelection() async {
    final id = _currentHouse!.id;
    final moved = PrefsService.instance.lastHouseId != id;
    await PrefsService.instance.setLastHouseId(id);
    if (moved && PrefsService.instance.syncLastHouse) {
      unawaited(AuthService.instance.publishLastHouseId(id));
    }
  }

  Future<void> selectHouse(House house) async {
    _currentHouse = house;
    await _persistSelection();
    notifyListeners();
  }

  Future<House> addHouse({required String name, String? description}) async {
    final house = await HouseService.instance.createHouse(
      name: name,
      description: description,
    );
    _houses = [..._houses, house];
    HouseService.instance.cache.setList('houses', _houses, (h) => h.toJson());
    _currentHouse = house;
    _serverAppMissing = false;
    _error = null;
    await _persistSelection();
    notifyListeners();
    return house;
  }
}
