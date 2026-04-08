import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrefsService {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  static const _lastHouseKey = 'last_house_id';
  final _storage = const FlutterSecureStorage();

  int? _lastHouseId;
  int? get lastHouseId => _lastHouseId;

  Future<void> load() async {
    final value = await _storage.read(key: _lastHouseKey);
    if (value != null) {
      _lastHouseId = int.tryParse(value);
    }
  }

  Future<void> setLastHouseId(int id) async {
    _lastHouseId = id;
    await _storage.write(key: _lastHouseKey, value: id.toString());
  }

  Future<void> clear() async {
    _lastHouseId = null;
    await _storage.delete(key: _lastHouseKey);
  }
}
