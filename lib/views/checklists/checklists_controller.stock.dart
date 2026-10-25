part of 'checklists_controller.dart';

extension ChecklistsControllerStock on ChecklistsController {
  bool get isInventoryKind => kind == ListKind.inventory;

  bool _isInventoryList(int listId) =>
      _checklistService.kindOf(listId) == ListKind.inventory;

  int expiryLeadDaysFor(int listId) =>
      _lists.where((l) => l.id == listId).firstOrNull?.expiryLeadDays ??
      defaultExpiryLeadDays;

  Future<void> setOnHand(ListItem item, String quantity) async {
    if (quantity == (item.quantity ?? '')) return;
    await updateItem(item, quantity: quantity);
  }

  Future<void> setStockLevel(ListItem item, StockLevel level) async {
    if (level == item.stockLevel) return;
    await updateItem(item, stockLevel: level);
  }

  /// [after] as the server will answer it: the expiry pair settled the way the
  /// server settles a one-sided write, a raise from empty renewing the date,
  /// and the status fields recomputed.
  ListItem _withLocalStock(
    ListItem before,
    ListItem after, {
    int? sentExpiresAt,
    int? sentShelfLifeDays,
    bool raisesFromEmpty = false,
  }) {
    final today = todayEpoch();
    var next = after;
    if (sentShelfLifeDays != null &&
        sentShelfLifeDays > 0 &&
        sentExpiresAt == null) {
      next = next.copyWith(expiresAt: addDays(today, sentShelfLifeDays));
    } else if (sentExpiresAt != null &&
        sentExpiresAt > 0 &&
        sentShelfLifeDays == null &&
        daysUntil(sentExpiresAt, today) > 0) {
      next = next.copyWith(shelfLifeDays: daysUntil(sentExpiresAt, today));
    }
    if (raisesFromEmpty &&
        sentExpiresAt == null &&
        sentShelfLifeDays == null &&
        isStockEmpty(before.stockFields) &&
        !isStockEmpty(next.stockFields)) {
      final renewed = renewedExpiry(next.shelfLifeDays, today);
      next = next.copyWith(expiresAt: renewed, clearExpiresAt: renewed == null);
    }
    return next.withLocalStock(
      leadDays: expiryLeadDaysFor(next.listId),
      today: today,
    );
  }

  /// Keeps the navigation counter in step with the rows on screen, which only
  /// a concrete inventory's active view holds in full.
  void _recountNeedsRestock() {
    final list = _currentList;
    if (list == null ||
        list.kind != ListKind.inventory ||
        isMetaMode ||
        isSoftView) {
      return;
    }
    final count = _items
        .where(
          (i) =>
              i.listId == list.id &&
              i.deletedAt == null &&
              i.archivedAt == null &&
              i.needsStockRestock,
        )
        .length;
    if (count == list.needsRestock) return;
    final recounted = list.copyWith(needsRestock: count);
    _currentList = recounted;
    _lists = [for (final l in _lists) l.id == list.id ? recounted : l];
    _checklistService.cacheListsOfEveryKind(houseId, _lists);
  }

  void saveInventorySettings(
    ChecklistList list, {
    required String name,
    required int expiryLeadDays,
  }) {
    final trimmed = name.trim();
    final nameChanged = trimmed.isNotEmpty && trimmed != list.name;
    final leadChanged =
        expiryLeadDays != (list.expiryLeadDays ?? defaultExpiryLeadDays);
    if (!nameChanged && !leadChanged) return;

    final optimistic = list.copyWith(
      name: nameChanged ? trimmed : null,
      expiryLeadDays: expiryLeadDays,
      updatedAt: _now(),
    );
    _lists = [for (final l in _lists) l.id == list.id ? optimistic : l];
    if (_currentList?.id == list.id) {
      _currentList = optimistic;
      if (leadChanged) {
        _items = [
          for (final i in _items)
            i.listId == list.id
                ? i.withLocalStock(leadDays: expiryLeadDays)
                : i,
        ];
        _cacheVisibleItems();
      }
    }
    _checklistService.cacheListsOfEveryKind(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.update,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        body: {
          if (nameChanged) 'name': trimmed,
          if (leadChanged) 'expiryLeadDays': expiryLeadDays,
        },
        createdAt: _now(),
      ),
    );
  }

  /// A stock edit shows as final the moment it is made, so a write the server
  /// refuses has to be taken back: the inventory reloads to what the server
  /// holds. The queue already reports drops it did not expect; a conflict or a
  /// vanished item is reported here.
  void _onSyncSkipped(SyncOpSkipped event) {
    final op = event.op;
    if (op.houseId != houseId || op.entity != SyncEntity.checklistItem) return;
    if (op.op != SyncOpKind.update && op.op != SyncOpKind.create) return;
    final listId = op.parentId;
    if (listId == null || !_isInventoryList(listId)) return;
    if (!event.isUnexpected) {
      showAppToast(message: m.stock.writeRefused, kind: ToastKind.error);
    }
    if (_currentList?.id == listId || isMetaMode) unawaited(refresh());
  }
}
