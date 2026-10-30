import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/utils/app_toast.dart';

/// One line of stock feedback. [rowId] names the checklist item it is about,
/// so a newer line about the same item replaces the toast on screen.
typedef RestockMessage = ({String text, ToastKind kind, int? rowId});

String _part(RestockEntry e) {
  final added = e.added;
  if (e.replaced) {
    return added == null
        ? m.stock.restock.partReplacedFull(e.itemName, e.listName)
        : m.stock.restock.partReplaced(e.itemName, e.listName, added);
  }
  return added == null
      ? m.stock.restock.partFull(e.itemName, e.listName)
      : m.stock.restock.partAdded(e.itemName, e.listName, added);
}

({String? restock, String? replace}) _parts(List<RestockEntry> entries) {
  final shown = entries.where((e) => !e.onlyRenewedDate);
  String? join(Iterable<RestockEntry> of) =>
      of.isEmpty ? null : of.map(_part).join(', ');
  return (
    restock: join(shown.where((e) => !e.replaced)),
    replace: join(shown.where((e) => e.replaced)),
  );
}

/// "Restocked Eggs (Kitchen) +8, replaced Milk (Kitchen) ×2", or null when the
/// tick only renewed dates.
String? restockText(List<RestockEntry> entries) {
  final (:restock, :replace) = _parts(entries);
  if (restock != null && replace != null) {
    return m.stock.restock.restockedReplaced(restock, replace);
  }
  if (restock != null) return m.stock.restock.restocked(restock);
  if (replace != null) return m.stock.restock.replaced(replace);
  return null;
}

/// "Undid: restocked Eggs (Kitchen) +8", or null when there is nothing to name.
String? restockUndoneText(List<RestockEntry> entries) {
  final (:restock, :replace) = _parts(entries);
  if (restock != null && replace != null) {
    return m.stock.restock.undidRestockedReplaced(restock, replace);
  }
  if (restock != null) return m.stock.restock.undidRestocked(restock);
  if (replace != null) return m.stock.restock.undidReplaced(replace);
  return null;
}

/// "Restocks Eggs (Kitchen), Soda (Garage)".
String restocksText(List<StockLinkSource> sources) => m.stock.restock.restocks(
  sources.map((s) => m.stock.restock.source(s.name, s.listName)).join(', '),
);

String _q(String? quantity) => quantity?.trim() ?? '';

RestockMessage syncEventMessage(RestockSyncEvent e) {
  final quantity = _q(e.quantity);
  final r = m.stock.restock;
  final (text, kind) = switch (e.kind) {
    RestockSyncKind.added => (
      r.added(quantity.isEmpty ? e.rowName : quantity, e.listName),
      ToastKind.success,
    ),
    RestockSyncKind.revived => (
      quantity.isEmpty
          ? r.revived(e.listName, e.rowName)
          : r.revivedQuantity(e.listName, e.rowName, quantity),
      ToastKind.success,
    ),
    RestockSyncKind.changed => (
      r.changed(e.listName, e.rowName, quantity),
      ToastKind.info,
    ),
    RestockSyncKind.pinned => (
      quantity.isEmpty
          ? r.pinned(e.rowName, e.listName)
          : r.pinnedAt(e.rowName, e.listName, quantity),
      ToastKind.info,
    ),
    RestockSyncKind.recovered => (
      r.recovered(e.rowName, e.listName),
      ToastKind.info,
    ),
  };
  return (text: text, kind: kind, rowId: e.rowId);
}

/// Every message a checklist item's tick or uncheck answer carries.
List<RestockMessage> checkMessages({
  required int rowId,
  required List<RestockEntry> restocked,
  required List<RestockEntry> restockUndone,
  required List<RestockSyncEvent> restockSync,
}) {
  final restock = restockText(restocked);
  final undone = restockUndoneText(restockUndone);
  return [
    if (restock != null) (text: restock, kind: ToastKind.success, rowId: rowId),
    if (undone != null) (text: undone, kind: ToastKind.info, rowId: rowId),
    ...restockSync.map(syncEventMessage),
  ];
}

/// What the answer [after] to [op], a write to [before], has to tell the
/// member who made it.
List<RestockMessage> itemWriteMessages(
  SyncOp op,
  ListItem before,
  ListItem after,
) {
  final r = m.stock.restock;
  final link = after.stockLink;
  final target = op.body[stockLinkTargetKey];
  final previous = before.stockLink;
  final candidates = after.linkCandidates;
  return [
    if (target is int && target > 0 && link != null)
      (
        text: r.linked(after.name, link.name, link.listName),
        kind: ToastKind.success,
        rowId: link.itemId,
      ),
    if (target == 0 && previous != null)
      (
        text: r.unlinked(after.name, previous.name, previous.listName),
        kind: ToastKind.info,
        rowId: previous.itemId,
      ),
    ...checkMessages(
      rowId: after.id,
      restocked: after.restocked,
      restockUndone: after.restockUndone,
      restockSync: after.restockSync,
    ),
    if (link == null && candidates.isNotEmpty && before.linkCandidates.isEmpty)
      (
        text: r.severalMatches(
          after.name,
          candidates.length,
          candidates.first.listName,
        ),
        kind: ToastKind.warning,
        rowId: null,
      ),
  ];
}

/// The word for where a linked checklist item stands: "open", "× 4", ….
String stockLinkStateText(StockLinkRow row) {
  final l = m.stock.links;
  return switch (row.state) {
    StockLinkState.open =>
      _q(row.quantity).isEmpty
          ? l.stateOpen
          : l.stateQuantity(_q(row.quantity)),
    StockLinkState.checked => l.stateChecked,
    StockLinkState.archived => l.stateArchived,
    StockLinkState.trashed => l.stateTrashed,
  };
}

/// Holds which writes were a member's own action, for as long as their answer
/// still reads as a reply to it.
///
/// Feedback only makes sense while the member is still looking at what they
/// did: an answer that takes longer, or that comes from a write replayed later
/// from the offline queue, would be news about something they have moved on
/// from, so it shows nothing.
class RestockFeedbackTracker<T> {
  RestockFeedbackTracker({this.window = const Duration(seconds: 5)});

  final Duration window;
  final Map<String, ({DateTime at, T context})> _ops = {};

  void track(String opUuid, T context) {
    final now = DateTime.now();
    _ops.removeWhere((_, v) => now.difference(v.at) > window);
    _ops[opUuid] = (at: now, context: context);
  }

  /// The context [opUuid] was tracked with, when its answer arrived in time.
  /// Each op is claimed once.
  T? claim(String opUuid) {
    final entry = _ops.remove(opUuid);
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > window) return null;
    return entry.context;
  }
}

final Map<int, ToastFuture> _onScreen = {};

/// Shows [messages] as one toast, in the most pressing tone among them. A
/// toast still up about one of the same checklist items is replaced.
void showRestockFeedback(List<RestockMessage> messages) {
  if (messages.isEmpty) return;
  final kinds = messages.map((m) => m.kind).toSet();
  final kind = kinds.contains(ToastKind.warning)
      ? ToastKind.warning
      : kinds.contains(ToastKind.success)
      ? ToastKind.success
      : ToastKind.info;
  final rows = {for (final msg in messages) ?msg.rowId};
  for (final id in rows) {
    _onScreen.remove(id)?.dismiss(showAnim: false);
  }
  final handle = showAppToast(
    message: messages.map((m) => m.text).join('\n'),
    kind: kind,
    duration: Duration(seconds: 4 + messages.length),
  );
  if (handle == null) return;
  for (final id in rows) {
    _onScreen[id] = handle;
  }
}
