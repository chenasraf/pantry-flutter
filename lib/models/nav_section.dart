/// Identifies the three primary navigation destinations. Used both for
/// in-app ordering (which the user can customize) and for resolving
/// notification deep links to a tab.
enum NavSection {
  checklists,
  photoBoard,
  notesWall;

  /// Serialized form persisted in prefs and emitted by [encodeList].
  String get id => switch (this) {
    NavSection.checklists => 'checklists',
    NavSection.photoBoard => 'photoBoard',
    NavSection.notesWall => 'notesWall',
  };

  static NavSection? fromId(String? id) => switch (id) {
    'checklists' => NavSection.checklists,
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
  NavSection.photoBoard,
  NavSection.notesWall,
];

/// Parse a comma-separated list of section ids into a complete ordered list.
/// Unknown ids are dropped, missing sections are appended in their default
/// order so the result always contains every [NavSection] exactly once.
List<NavSection> decodeNavOrder(String? raw) {
  if (raw == null || raw.isEmpty) return List.of(kDefaultNavOrder);
  final seen = <NavSection>{};
  final order = <NavSection>[];
  for (final part in raw.split(',')) {
    final s = NavSection.fromId(part.trim());
    if (s != null && seen.add(s)) order.add(s);
  }
  for (final s in kDefaultNavOrder) {
    if (seen.add(s)) order.add(s);
  }
  return order;
}

String encodeNavOrder(List<NavSection> order) =>
    order.map((s) => s.id).join(',');
