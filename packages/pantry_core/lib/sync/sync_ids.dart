/// Local-only id generators for the sync layer. No external dependencies.
///
/// `tempEntityId`s are negative ints so they never collide with positive
/// server ids. `uuid`s are time-based with a per-process counter — unique
/// across an installation, not globally unique, which is all we need to
/// address ops within a single device's queue.
class SyncIds {
  SyncIds._();

  static int _opCounter = 0;
  static int _tempCounter = -1;

  /// Generates a stable, non-cryptographic id for a SyncOp.
  static String newOpUuid() {
    _opCounter++;
    final t = DateTime.now().microsecondsSinceEpoch;
    return 'op_${t.toRadixString(36)}_${_opCounter.toRadixString(36)}';
  }

  /// Returns the next negative temp id. Seeded once at startup from the
  /// smallest negative id already present in the queue so a relaunch
  /// can't recycle an in-flight temp id.
  static int newTempEntityId() {
    final id = _tempCounter;
    _tempCounter--;
    return id;
  }

  /// Seed the temp-id counter to one below the smallest temp id seen so
  /// far in persisted state. Idempotent.
  static void seedTempIds(Iterable<int> existing) {
    var min = -1;
    for (final id in existing) {
      if (id < min) min = id;
    }
    if (min - 1 < _tempCounter) {
      _tempCounter = min - 1;
    }
  }
}
