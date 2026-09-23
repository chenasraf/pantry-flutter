import 'package:pantry_core/i18n.dart';

/// The notes wall's sort choices, in display order.
List<({String key, String label})> noteSortOptions() => [
  (key: 'newest', label: m.notesWall.sort.newestFirst),
  (key: 'oldest', label: m.notesWall.sort.oldestFirst),
  (key: 'title_asc', label: m.notesWall.sort.titleAZ),
  (key: 'title_desc', label: m.notesWall.sort.titleZA),
  (key: 'custom', label: m.notesWall.sort.custom),
];

/// Human label for the current sort — shown on the collapsed "Sort" overflow
/// row so the active choice is visible without opening it.
String noteSortLabel(String sortBy) {
  for (final o in noteSortOptions()) {
    if (o.key == sortBy) return o.label;
  }
  return m.notesWall.sort.newestFirst;
}
