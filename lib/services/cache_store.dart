import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Persistent key-value cache that serializes to a JSON file.
///
/// Stores values by string key, with optional scoping (e.g. by houseId).
/// All mutations auto-persist to disk.
class CacheStore {
  final String fileName;
  Map<String, dynamic> _data = {};

  CacheStore(this.fileName);

  // -- Disk I/O --

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<void> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      _data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CacheStore:$fileName] Failed to load: $e');
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(_data));
    } catch (e) {
      debugPrint('[CacheStore:$fileName] Failed to save: $e');
    }
  }

  Future<void> clear() async {
    _data.clear();
    await _save();
  }

  // -- Scalar values --

  T? get<T>(String key) => _data[key] as T?;

  void set<T>(String key, T? value) {
    _data[key] = value;
    _save();
  }

  // -- Single object cache --

  Map<String, dynamic>? getObject(String key) {
    final val = _data[key];
    return val is Map<String, dynamic> ? val : null;
  }

  // -- List cache --

  List<T>? getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final val = _data[key];
    if (val is! List) return null;
    return val.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  void setList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    _data[key] = items.map(toJson).toList();
    _save();
  }

  // -- Keyed list cache (e.g. items per listId) --

  List<T>? getKeyedList<T>(
    String prefix,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return getList<T>('$prefix:$key', fromJson);
  }

  void setKeyedList<T>(
    String prefix,
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    setList('$prefix:$key', items, toJson);
  }

  void removeKeyed(String prefix, {String? keepKey}) {
    final keysToRemove = _data.keys
        .where((k) => k.startsWith('$prefix:') && k != '$prefix:$keepKey')
        .toList();
    for (final k in keysToRemove) {
      _data.remove(k);
    }
    _save();
  }

  void removeKey(String key) {
    _data.remove(key);
    _save();
  }
}
