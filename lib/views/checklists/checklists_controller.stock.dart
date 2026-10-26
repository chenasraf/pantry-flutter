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
    final after = await updateItem(item, quantity: quantity);
    _offerRenewal(item, after);
  }

  Future<void> setStockLevel(ListItem item, StockLevel level) async {
    if (level == item.stockLevel) return;
    final after = await updateItem(item, stockLevel: level);
    _offerRenewal(item, after);
  }

  /// The date the open renew offer on [item] would set its expiry to.
  int? renewOfferFor(ListItem item) => _renewOffers[item.id];

  void _offerRenewal(ListItem before, ListItem after) {
    if (!ServerFeature.inventoryStock) return;
    final date = renewOffer(
      before.stockFields,
      after.stockFields,
      todayEpoch(),
    );
    if (date == null) return;
    _renewOffers[before.id] = date;
    notifyListeners();
  }

  Future<void> renewExpiry(ListItem item) async {
    final date = _renewOffers[item.id];
    if (date == null) return;
    await updateItem(item, expiresAt: date);
  }

  /// Whether [item]'s stock link can be changed from here: an inventory item
  /// the server already knows.
  bool canLinkStock(ListItem item) =>
      ServerFeature.inventoryStock &&
      item.id > 0 &&
      _isInventoryList(item.listId) &&
      isItemWritable(item) &&
      permissions.canEditLists;

  void linkStock(ListItem item, StockLinkRow row) => _patchStockLink(
    item,
    (i) => i.copyWith(stockLink: row, linkCandidates: const []),
    {stockLinkTargetKey: row.itemId},
  );

  /// Unlinking also stops the item finding a row by name again.
  void unlinkStock(ListItem item) => _patchStockLink(
    item,
    (i) => i.copyWith(clearStockLink: true, autoLink: false),
    {stockLinkTargetKey: 0, 'autoLink': false},
  );

  void setAutoLink(ListItem item, bool value) => _patchStockLink(
    item,
    (i) => i.copyWith(autoLink: value),
    {'autoLink': value},
  );

  /// Lets stock set a checklist item's quantity again after a member set it
  /// by hand.
  void unpinQuantity(ListItem row) {
    if (!row.quantityPinned) return;
    _patchStockLink(row, (i) => i.copyWith(quantityPinned: false), {
      'quantityPinned': false,
    });
  }

  /// [change] applies to the item as the list holds it now: a control built
  /// from an older copy must not take back what changed since.
  void _patchStockLink(
    ListItem item,
    ListItem Function(ListItem) change,
    Map<String, dynamic> body,
  ) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) item = _items[index];
    if (index != -1) {
      _items[index] = change(item);
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
    final opUuid = SyncIds.newOpUuid();
    _trackStockFeedback(opUuid, item);
    _sync.enqueue(
      SyncOp(
        uuid: opUuid,
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.update,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id,
        body: body,
        createdAt: _now(),
      ),
    );
  }

  /// Checklist items [item] can be linked to, matching [search].
  Future<List<StockLinkRow>> stockLinkTargets(ListItem item, String search) =>
      _checklistService.linkTargets(houseId, item.listId, search: search);

  /// The checklist inventory [listId] puts what it needs on, while it has one.
  ChecklistList? restockChecklistOf(int listId) {
    final id = _lists
        .where((l) => l.id == listId)
        .firstOrNull
        ?.restockChecklistId;
    return id == null ? null : _lists.where((l) => l.id == id).firstOrNull;
  }

  void _trackStockFeedback(String opUuid, ListItem before) {
    if (!ServerFeature.inventoryStock) return;
    _stockFeedback.track(opUuid, before);
  }

  /// Tells the member what the answer to their own write did to stock and
  /// shopping lists, while the list they made it on is still in view.
  void _onStockWriteApplied(SyncOpApplied applied) {
    final entity = applied.entity;
    if (entity is! ListItem) return;
    if (entity.restocked.isNotEmpty || entity.restockUndone.isNotEmpty) {
      _stockChangedElsewhere = true;
      // The queue's length drops before its answer arrives here, so the last
      // write of a drain has to check on its own.
      _refreshStockOnceDrained();
    }
    final before = _stockFeedback.claim(applied.op.uuid);
    if (before == null) return;
    if (_currentList?.id != before.listId && !isMetaMode) return;
    showRestockFeedback(itemWriteMessages(applied.op, before, entity));
  }

  void _refreshStockOnceDrained() {
    if (!_stockChangedElsewhere || _sync.pendingCount.value > 0) return;
    _stockChangedElsewhere = false;
    if (_currentList?.kind == ListKind.inventory && !isSoftView) {
      unawaited(refresh());
    }
  }

  /// A new restock checklist links the inventory's items on the server, which
  /// the rows in view only show after a reload.
  void _onInventorySettingsApplied(SyncOpApplied applied) {
    final op = applied.op;
    if (op.op != SyncOpKind.update ||
        !op.body.containsKey('restockChecklistId')) {
      return;
    }
    if (_currentList?.id == op.effectiveEntityId) unawaited(refresh());
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
    int? restockChecklistId,
    bool? stockSummary,
  }) {
    final trimmed = name.trim();
    final nameChanged = trimmed.isNotEmpty && trimmed != list.name;
    final leadChanged =
        expiryLeadDays != (list.expiryLeadDays ?? defaultExpiryLeadDays);
    final restockChanged =
        ServerFeature.inventoryStock &&
        restockChecklistId != list.restockChecklistId;
    final summaryChanged =
        ServerFeature.inventoryStock &&
        stockSummary != null &&
        stockSummary != (list.stockSummary ?? true);
    if (!nameChanged && !leadChanged && !restockChanged && !summaryChanged) {
      return;
    }

    final optimistic = list.copyWith(
      name: nameChanged ? trimmed : null,
      expiryLeadDays: expiryLeadDays,
      restockChecklistId: restockChecklistId,
      clearRestockChecklistId: restockChecklistId == null,
      stockSummary: stockSummary,
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
          // 0 clears it.
          if (restockChanged) 'restockChecklistId': restockChecklistId ?? 0,
          if (summaryChanged) 'stockSummary': stockSummary,
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
