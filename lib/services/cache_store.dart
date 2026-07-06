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

  /// The write currently draining to disk, or null when idle. All mutations
  /// funnel through it so writes never overlap.
  Future<void>? _writing;

  /// Set whenever [_data] changes while a write is already in flight, so the
  /// drain loop knows to encode-and-write one more time with the latest state.
  bool _dirty = false;

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

  /// Persist [_data] to disk, serializing concurrent callers.
  ///
  /// Mutations fire many un-awaited [_save] calls in bursts (e.g. warming
  /// every list's item cache on load). Writing them concurrently to the same
  /// file raced: each call encodes a snapshot at its own start, and whichever
  /// `writeAsString` *finished last* won — so an earlier, smaller snapshot
  /// could clobber a newer one and silently drop just-cached keys (issue #92).
  /// Funnelling every write through a single drain loop guarantees writes never
  /// overlap and the final on-disk copy always reflects the latest [_data].
  Future<void> _save() {
    _dirty = true;
    return _writing ??= _drain();
  }

  /// Completes once every pending mutation has been written to disk. Useful to
  /// guarantee durability at a checkpoint (e.g. app pause) and to await the
  /// serialized drain in tests.
  Future<void> flush() => _writing ?? Future<void>.value();

  Future<void> _drain() async {
    try {
      while (_dirty) {
        _dirty = false;
        try {
          final file = await _file;
          await file.writeAsString(jsonEncode(_data));
        } catch (e) {
          debugPrint('[CacheStore:$fileName] Failed to save: $e');
        }
      }
    } finally {
      _writing = null;
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
