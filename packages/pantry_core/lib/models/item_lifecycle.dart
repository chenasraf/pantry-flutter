import 'package:pantry_core/models/checklist.dart';

/// Pointer to an item's parent list; the All-lists view renders it as a chip.
class ItemListBadge {
  final String name;
  final String icon;
  final String? color;
  const ItemListBadge({required this.name, required this.icon, this.color});
}

/// Item lifecycle as expressed by the design's chip:
/// - staple: stays on list after completion (no rrule, deleteOnDone=false)
/// - once: removed once completed (no rrule, deleteOnDone=true)
/// - recurring: returns on a schedule (rrule set; deleteOnDone preserved as-is)
enum ItemLifecycle { staple, once, recurring }

ItemLifecycle lifecycleOf(ListItem item) {
  if (item.rrule != null && item.rrule!.isNotEmpty) {
    return ItemLifecycle.recurring;
  }
  if (item.deleteOnDone) return ItemLifecycle.once;
  return ItemLifecycle.staple;
}
