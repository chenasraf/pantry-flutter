import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/stock_rules.dart';

/// One inventory a bought item goes to. A null [amount] fills a count item to
/// its target, or takes a level item to Full.
class PutAwayStorage {
  final int listId;
  final double? amount;

  const PutAwayStorage({required this.listId, this.amount});

  PutAwayStorage withAmount(double? amount) =>
      PutAwayStorage(listId: listId, amount: amount);

  Map<String, dynamic> toJson() => {'listId': listId, 'amount': amount};

  @override
  bool operator ==(Object other) =>
      other is PutAwayStorage &&
      other.listId == listId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(listId, amount);
}

/// Where one bought item goes when the trip is finished.
class PutAwayEntry {
  final int itemId;
  final List<PutAwayStorage> storages;

  const PutAwayEntry({required this.itemId, required this.storages});

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'storages': [for (final s in storages) s.toJson()],
  };
}

/// Item id → where it is put away, as the review edits it.
typedef PutAwayDraft = Map<int, List<PutAwayStorage>>;

/// Where the tick put [item], from its restock record: an amount per
/// inventory, or null for a level item it took to Full.
List<PutAwayStorage> putAwayFromRecord(ListItem item) {
  final out = <PutAwayStorage>[];
  for (final entry in item.restock ?? const <RestockEntry>[]) {
    if (entry.onlyRenewedDate) continue;
    final amount = entry.added != null ? firstNumber(entry.added) : null;
    final index = out.indexWhere((s) => s.listId == entry.listId);
    if (index == -1) {
      out.add(PutAwayStorage(listId: entry.listId, amount: amount));
      continue;
    }
    final existing = out[index].amount;
    out[index] = out[index].withAmount(
      existing == null || amount == null ? null : existing + amount,
    );
  }
  return out;
}

/// A draft seeded with where each item's tick put it.
PutAwayDraft putAwayDraft(Iterable<ListItem> items) => {
  for (final item in items) item.id: putAwayFromRecord(item),
};

/// How much of [item] is still to put away: what was bought less what is
/// placed.
double amountLeft(ListItem item, List<PutAwayStorage> storages) {
  final bought = firstNumber(item.quantity) ?? 1;
  final placed = storages.fold<double>(0, (sum, s) => sum + (s.amount ?? 0));
  return bought - placed > 0 ? bought - placed : 0;
}

bool _sameStorages(List<PutAwayStorage> a, List<PutAwayStorage> b) {
  String key(List<PutAwayStorage> list) =>
      (list.map((s) => '${s.listId}:${s.amount ?? 'full'}').toList()..sort())
          .join('|');
  return key(a) == key(b);
}

/// The entries to send: only items whose storages differ from where their tick
/// put them, so an untouched item keeps exactly what was restocked.
List<PutAwayEntry> changedPutAway(
  Iterable<ListItem> items,
  PutAwayDraft draft,
) => [
  for (final item in items)
    if (draft[item.id] case final storages?
        when !_sameStorages(storages, putAwayFromRecord(item)))
      PutAwayEntry(itemId: item.id, storages: storages),
];
