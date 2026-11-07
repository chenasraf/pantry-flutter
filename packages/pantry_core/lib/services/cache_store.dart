import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// How much a store owes the user if the process dies before its next write.
enum CacheDurability {
  /// A rendering that can be rebuilt — from the server, or from the sync queue
  /// laid back over it. Writes coalesce behind a short debounce and are
  /// flushed at a lifecycle checkpoint.
  cache,

  /// The durable record of the user's intent, which nothing can rebuild.
  /// Every mutation goes straight to disk.
  queue,
}

/// Persistent key-value cache that serializes to a JSON file.
///
/// Stores values by string key, with optional scoping (e.g. by houseId).
/// All mutations auto-persist to disk.
class CacheStore {
  final String fileName;

  /// Which durability class this store belongs to. It decides whether a
  /// mutation may wait behind [_debounce] — a lost cache write is rebuilt on
  /// the next read, and a lost queue write is simply gone.
  final CacheDurability durability;

  Map<String, dynamic> _data = {};

  /// The write currently draining to disk, or null when idle. All mutations
  /// funnel through it so writes never overlap.
  Future<void>? _writing;

  /// Set whenever [_data] changes while a write is already in flight, so the
  /// drain loop knows to encode-and-write one more time with the latest state.
  bool _dirty = false;

  /// Pending debounce for a cache-class store, or null when nothing is waiting.
  Timer? _debounceTimer;

  /// Completes when the debounced write has reached disk. Held so [flush] and
  /// a caller awaiting [_save] see the same future the timer will satisfy.
  Completer<void>? _debounced;

  /// Long enough to swallow the trickle of mutations a settings screen or a
  /// scroll-driven cache refresh produces, short enough that a process killed
  /// without a lifecycle callback loses at most one beat. Bursts already
  /// coalesce inside [_drain]; this catches the spaced-out case it cannot.
  static const _debounce = Duration(milliseconds: 500);

  /// Every store built so far, so a lifecycle checkpoint can flush them
  /// without each owner remembering to register itself.
  static final List<CacheStore> _live = [];

  static _CacheCheckpoint? _checkpoint;

  CacheStore(this.fileName, {this.durability = CacheDurability.cache}) {
    _live.add(this);
  }

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
  /// Mutations fire many un-awaited [_save] calls in bursts. Writing them
  /// concurrently raced — each encodes its own snapshot and whichever
  /// `writeAsString` finished last won, so an older snapshot could clobber a
  /// newer one. A single drain loop guarantees writes never overlap and the
  /// on-disk copy always reflects the latest [_data].
  Future<void> _save() {
    _dirty = true;
    if (durability == CacheDurability.queue) return _writing ??= _drain();
    final completer = _debounced ??= Completer<void>();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _writeDebounced);
    return completer.future;
  }

  void _writeDebounced() {
    _debounceTimer = null;
    final completer = _debounced;
    _debounced = null;
    final write = _writing ??= _drain();
    if (completer != null && !completer.isCompleted) {
      completer.complete(write);
    }
  }

  /// Completes once every pending mutation has been written to disk. Cancels
  /// any waiting debounce first, so a checkpoint (app pause, sign-out, a test
  /// awaiting the drain) never returns while a mutation is still only in
  /// memory.
  Future<void> flush() {
    if (_debounceTimer != null) _writeDebounced();
    return _writing ?? Future<void>.value();
  }

  /// Flush every live store. Wired to the lifecycle checkpoint so a debounced
  /// cache write cannot be lost to a process the system kills while the app is
  /// in the background.
  static Future<void> flushAll() =>
      Future.wait([for (final store in _live) store.flush()]);

  /// Start flushing every store when the app leaves the foreground. Called
  /// once per entrypoint, after the binding exists.
  static void installPauseCheckpoint() {
    _checkpoint ??= _CacheCheckpoint();
  }

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
    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    final completer = _debounced;
    _debounced = null;
    final write = _writing ??= _drain();
    if (completer != null && !completer.isCompleted) {
      completer.complete(write);
    }
    await write;
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

/// Turns the app leaving the foreground into the durability checkpoint
/// [CacheStore.flush] documents. Without it a debounced write is only ever a
/// promise: a watch process is killed far more readily than a phone's, and the
/// kill arrives after the pause, not before it.
class _CacheCheckpoint with WidgetsBindingObserver {
  _CacheCheckpoint() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    unawaited(CacheStore.flushAll());
  }
}
