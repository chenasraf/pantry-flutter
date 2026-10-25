/// How an inventory item tracks what is on hand.
enum StockMode {
  /// `quantity` is the amount on hand, measured against `target`.
  count,

  /// `stockLevel` says Full, Low or Out, and `quantity` is the restock amount.
  level;

  String get wire => name;

  /// Anything other than `level` counts, as on the server.
  static StockMode parse(Object? raw) => raw == 'level' ? level : count;

  static StockMode? tryParse(Object? raw) => switch (raw) {
    'count' => count,
    'level' => level,
    _ => null,
  };
}

enum StockLevel {
  full,
  low,
  out;

  String get wire => name;

  static StockLevel? tryParse(Object? raw) => switch (raw) {
    'full' => full,
    'low' => low,
    'out' => out,
    _ => null,
  };
}

enum StockStatus {
  ok,
  low,
  out,

  /// On hand or the target has no number ("some"), so it never runs low.
  uncounted;

  String get wire => name;

  bool get isShort => this == low || this == out;

  static StockStatus? tryParse(Object? raw) => switch (raw) {
    'ok' => ok,
    'low' => low,
    'out' => out,
    'uncounted' => uncounted,
    _ => null,
  };
}

enum ExpiryStatus {
  /// No date, or nothing on hand to go off.
  none,
  ok,
  expiring,
  expired;

  String get wire => name;

  bool get isDue => this == expiring || this == expired;

  static ExpiryStatus? tryParse(Object? raw) => switch (raw) {
    'none' => none,
    'ok' => ok,
    'expiring' => expiring,
    'expired' => expired,
    _ => null,
  };
}
