/// Identifies the primary navigation destinations. Used both for in-app
/// ordering (which the user can customize) and for resolving notification
/// deep links to a tab.
enum NavSection {
  checklists,

  /// The house's inventories, on servers with inventory stock.
  inventories,
  photoBoard,
  notesWall;

  /// Serialized form persisted in prefs and emitted by [encodeList].
  String get id => switch (this) {
    NavSection.checklists => 'checklists',
    NavSection.inventories => 'inventories',
    NavSection.photoBoard => 'photoBoard',
    NavSection.notesWall => 'notesWall',
  };

  static NavSection? fromId(String? id) => switch (id) {
    'checklists' => NavSection.checklists,
    'inventories' => NavSection.inventories,
    'photoBoard' => NavSection.photoBoard,
    'notesWall' => NavSection.notesWall,
    _ => null,
  };

  /// Deep links serialize tab index as 0=checklists, 1=photos, 2=notes —
  /// notification payloads written before the user could reorder still
  /// resolve through this fixed mapping.
  static NavSection? fromDeepLinkIndex(int index) => switch (index) {
    0 => NavSection.checklists,
    1 => NavSection.photoBoard,
    2 => NavSection.notesWall,
    _ => null,
  };
}

/// The default order, used when the user hasn't reordered yet or when the
/// persisted value is missing entries (e.g. after upgrading to a build that
/// added a new section).
const List<NavSection> kDefaultNavOrder = [
  NavSection.checklists,
  NavSection.inventories,
  NavSection.photoBoard,
  NavSection.notesWall,
];

/// Parse a comma-separated list of section ids into a complete ordered list.
/// Unknown ids are dropped, so the result always contains every [NavSection]
/// exactly once.
///
/// A section missing from [raw] goes right after the one it follows by
/// default, so a section a build adds lands beside its neighbour rather than
/// at the end of an order the user arranged.
List<NavSection> decodeNavOrder(String? raw) {
  if (raw == null || raw.isEmpty) return List.of(kDefaultNavOrder);
  final order = <NavSection>[];
  for (final part in raw.split(',')) {
    final s = NavSection.fromId(part.trim());
    if (s != null && !order.contains(s)) order.add(s);
  }
  for (var i = 0; i < kDefaultNavOrder.length; i++) {
    final s = kDefaultNavOrder[i];
    if (order.contains(s)) continue;
    // Every default section before this one is in the order by now.
    final at = i == 0 ? 0 : order.indexOf(kDefaultNavOrder[i - 1]) + 1;
    order.insert(at, s);
  }
  return order;
}

String encodeNavOrder(List<NavSection> order) =>
    order.map((s) => s.id).join(',');

/// Parse a comma-separated list of section ids into the set of sections the
/// user has hidden. Unknown ids are dropped.
Set<NavSection> decodeNavDisabled(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final disabled = <NavSection>{};
  for (final part in raw.split(',')) {
    final s = NavSection.fromId(part.trim());
    if (s != null) disabled.add(s);
  }
  return disabled;
}

String encodeNavDisabled(Set<NavSection> disabled) =>
    disabled.map((s) => s.id).join(',');
