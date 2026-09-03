part of 'checklist_service.dart';

extension ChecklistServiceLists on ChecklistService {
  Future<List<ChecklistList>> getLists(int houseId) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists',
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
        if (color != null && color.isNotEmpty) 'color': color,
      },
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<void> deleteList(int houseId, int listId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/$listId');
  }

  Future<List<ChecklistList>> getDeletedLists(
    int houseId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists/trash',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChecklistList> restoreList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/restore',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<void> permanentlyDeleteList(int houseId, int listId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/$listId/permanent');
  }

  Future<void> emptyListsTrash(int houseId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/trash');
  }

  Future<List<ChecklistList>> getArchivedLists(
    int houseId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists/archive',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChecklistList> archiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/archive',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<ChecklistList> unarchiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/unarchive',
      fromJson: (data) => ChecklistList.fromJson(data),
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
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId',
      body: {
        'name': ?name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'sortOrder': ?sortOrder,
        'deleteOnDoneDefault': ?deleteOnDoneDefault,
      },
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }
}
