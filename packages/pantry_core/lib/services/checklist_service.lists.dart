part of 'checklist_service.dart';

extension ChecklistServiceLists on ChecklistService {
  Future<List<ChecklistList>> getLists(
    int houseId, {
    ListKind kind = ListKind.checklist,
  }) async {
    return _rememberAll(
      await ApiClient.instance.get<List, List<ChecklistList>>(
        kindPath(houseId, kind),
        fromJson: (data) => data
            .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  /// Active lists of every kind the server has, checklists first. Needs
  /// [ServerFeature.listKinds] for anything beyond checklists.
  Future<List<ChecklistList>> getListsOfEveryKind(int houseId) async {
    if (!ServerFeature.listKinds) return getLists(houseId);
    final perKind = await Future.wait([
      for (final kind in ListKind.values) getLists(houseId, kind: kind),
    ]);
    return [for (final lists in perKind) ...lists];
  }

  /// Sort order is shared across kinds, so [order] may hold ids of any kind.
  Future<void> reorderLists(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/lists/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  Future<ChecklistList> createList(
    int houseId, {
    ListKind kind = ListKind.checklist,
    required String name,
    String? description,
    String? icon,
    String? color,
    ListRecurrenceMode? defaultRecurrenceMode,
    String? defaultRrule,
    bool? defaultRepeatFromCompletion,
  }) async {
    return _remember(
      await ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
        kindPath(houseId, kind),
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
          if (kind.isChecklist) ...{
            'defaultRecurrenceMode': ?defaultRecurrenceMode?.wire,
            'defaultRrule': ?defaultRrule,
            'defaultRepeatFromCompletion': ?defaultRepeatFromCompletion,
          },
        },
        fromJson: (data) => ChecklistList.fromJson(data),
      ),
    );
  }

  Future<void> deleteList(int houseId, int listId) async {
    await ApiClient.instance.delete(listPath(houseId, listId));
  }

  Future<List<ChecklistList>> getDeletedLists(
    int houseId, {
    ListKind kind = ListKind.checklist,
    int limit = 200,
    int offset = 0,
  }) async {
    return _rememberAll(
      await ApiClient.instance.get<List, List<ChecklistList>>(
        '${kindPath(houseId, kind)}/trash',
        query: {'limit': limit.toString(), 'offset': offset.toString()},
        fromJson: (data) => data
            .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Future<ChecklistList> restoreList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '${listPath(houseId, listId)}/restore',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<void> permanentlyDeleteList(int houseId, int listId) async {
    await ApiClient.instance.delete('${listPath(houseId, listId)}/permanent');
  }

  Future<void> emptyListsTrash(
    int houseId, {
    ListKind kind = ListKind.checklist,
  }) async {
    await ApiClient.instance.delete('${kindPath(houseId, kind)}/trash');
  }

  Future<List<ChecklistList>> getArchivedLists(
    int houseId, {
    ListKind kind = ListKind.checklist,
    int limit = 200,
    int offset = 0,
  }) async {
    return _rememberAll(
      await ApiClient.instance.get<List, List<ChecklistList>>(
        '${kindPath(houseId, kind)}/archive',
        query: {'limit': limit.toString(), 'offset': offset.toString()},
        fromJson: (data) => data
            .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }

  Future<ChecklistList> archiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '${listPath(houseId, listId)}/archive',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<ChecklistList> unarchiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '${listPath(houseId, listId)}/unarchive',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  /// Copies list [listId] into a new list of the same kind. [resetDone] only
  /// applies to checklists.
  Future<ChecklistList> duplicateList(
    int houseId,
    int listId, {
    required String name,
    required bool resetDone,
  }) async {
    final kind = kindOf(listId);
    return _remember(
      await ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
        '${listPath(houseId, listId)}/duplicate',
        body: {'name': name, if (kind.isChecklist) 'resetDone': resetDone},
        fromJson: (data) => ChecklistList.fromJson(data),
      ),
    );
  }

  /// Copies list [listId], of any kind, into a new list of [kind]. What the
  /// target kind has no room for is dropped. [resetDone] only applies when
  /// both are checklists.
  Future<ChecklistList> duplicateListAs(
    int houseId,
    int listId, {
    required ListKind kind,
    required String name,
    required bool resetDone,
  }) async {
    return _remember(
      await ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
        '${kindPath(houseId, kind)}/from/$listId',
        body: {'name': name, if (kind.isChecklist) 'resetDone': resetDone},
        fromJson: (data) => ChecklistList.fromJson(data),
      ),
    );
  }

  Future<ChecklistList> updateList(
    int houseId,
    int listId, {
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    bool? deleteOnDoneDefault,
    ListRecurrenceMode? defaultRecurrenceMode,
    ListRecurrenceKind? defaultRecurrenceKind,
    String? defaultRrule,
    bool? defaultRepeatFromCompletion,
    int? expiryLeadDays,
    int? restockChecklistId,
    bool? stockSummary,
  }) async {
    final isChecklist = kindOf(listId).isChecklist;
    return ApiClient.instance.patch<Map<String, dynamic>, ChecklistList>(
      listPath(houseId, listId),
      body: {
        'name': ?name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'sortOrder': ?sortOrder,
        if (isChecklist) ...{
          'deleteOnDoneDefault': ?deleteOnDoneDefault,
          'defaultRecurrenceMode': ?defaultRecurrenceMode?.wire,
          'defaultRecurrenceKind': ?defaultRecurrenceKind?.wire,
          'defaultRrule': ?defaultRrule,
          'defaultRepeatFromCompletion': ?defaultRepeatFromCompletion,
        },
        if (kindOf(listId) == ListKind.inventory) ...{
          'expiryLeadDays': ?expiryLeadDays,
          'restockChecklistId': ?restockChecklistId,
          'stockSummary': ?stockSummary,
        },
      },
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  /// Merge [patch] into a list's item defaults. Needs
  /// [ServerFeature.listItemDefaults].
  Future<ChecklistList> updateItemDefaults(
    int houseId,
    int listId,
    ItemDefaultsPatch patch,
  ) async {
    final body = patch.toJson();
    final kind = kindOf(listId);
    if (!kind.hasRecurrence) body.remove(ItemDefaults.recurrenceKey);
    // Templates are drawn from, never into.
    if (kind == ListKind.template) {
      body.remove(ItemDefaultsPatch.fillFromDefaultsKey);
    }
    return ApiClient.instance.patch<Map<String, dynamic>, ChecklistList>(
      '${listPath(houseId, listId)}/item-defaults',
      body: body,
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }
}
