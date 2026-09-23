import 'package:pantry_core/i18n.dart';

/// The photo board's sort choices, in display order.
List<({String key, String label})> photoSortOptions() => [
  (key: 'newest', label: m.photoBoard.sort.newestFirst),
  (key: 'oldest', label: m.photoBoard.sort.oldestFirst),
  (key: 'description_asc', label: m.photoBoard.sort.captionAZ),
  (key: 'description_desc', label: m.photoBoard.sort.captionZA),
  (key: 'custom', label: m.photoBoard.sort.custom),
];

/// Human label for the current sort — shown on the collapsed "Sort" overflow
/// row so the active choice is visible without opening it.
String photoSortLabel(String sortBy) {
  for (final o in photoSortOptions()) {
    if (o.key == sortBy) return o.label;
  }
  return m.photoBoard.sort.newestFirst;
}
