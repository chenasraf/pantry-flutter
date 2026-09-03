import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';

/// The sort choices, in display order. `custom` is suppressed in the meta
/// (All-lists) view — there's no coherent custom order across lists, so the
/// effective sort falls back to "newest".
List<({String key, String label})> checklistSortOptions({
  required bool showCustom,
}) {
  return [
    (key: 'newest', label: m.checklists.sort.newestFirst),
    (key: 'oldest', label: m.checklists.sort.oldestFirst),
    (key: 'name_asc', label: m.checklists.sort.nameAZ),
    (key: 'name_desc', label: m.checklists.sort.nameZA),
    (key: 'category', label: m.checklists.sort.category),
    if (hasFeature('store-sort'))
      (key: 'store', label: m.checklists.sort.store),
    if (showCustom) (key: 'custom', label: m.checklists.sort.custom),
  ];
}

/// Human label for the currently effective sort — shown on the collapsed
/// "Sort" overflow row so the active choice is visible without opening it.
String checklistSortLabel(String effective) {
  for (final o in checklistSortOptions(showCustom: true)) {
    if (o.key == effective) return o.label;
  }
  return m.checklists.sort.newestFirst;
}
