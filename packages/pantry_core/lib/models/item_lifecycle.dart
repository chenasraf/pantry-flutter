import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_recurrence.dart';

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

extension ItemLifecycleRecurrence on ItemLifecycle {
  /// This lifecycle in the terms a list's recurrence default is stated in.
  ListRecurrenceKind get recurrenceKind => switch (this) {
    ItemLifecycle.staple => ListRecurrenceKind.none,
    ItemLifecycle.once => ListRecurrenceKind.once,
    ItemLifecycle.recurring => ListRecurrenceKind.recurring,
  };
}

extension ListRecurrenceKindLifecycle on ListRecurrenceKind {
  ItemLifecycle get lifecycle => switch (this) {
    ListRecurrenceKind.none => ItemLifecycle.staple,
    ListRecurrenceKind.once => ItemLifecycle.once,
    ListRecurrenceKind.recurring => ItemLifecycle.recurring,
  };
}
