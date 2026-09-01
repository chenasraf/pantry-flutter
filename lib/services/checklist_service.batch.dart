part of 'checklist_service.dart';

// -- Batch (group) item operations --
//
// House-scoped: a selection can span multiple source lists, so the server
// resolves each item's own source list. All return a [PantryBatchResult]
// envelope; `skipped` carries ids the server refused for access reasons.

extension ChecklistServiceBatch on ChecklistService {
  Future<PantryBatchResult> batchMoveItems(
    int houseId, {
    required List<int> itemIds,
    required int targetListId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/move',
      body: {'itemIds': itemIds, 'targetListId': targetListId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchCopyItems(
    int houseId, {
    required List<int> itemIds,
    required int targetListId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/copy',
      body: {'itemIds': itemIds, 'targetListId': targetListId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchDeleteItems(
    int houseId, {
    required List<int> itemIds,
    bool permanent = false,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/delete',
      body: {'itemIds': itemIds, if (permanent) 'permanent': true},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchArchiveItems(
    int houseId, {
    required List<int> itemIds,
    bool archive = true,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/archive',
      body: {'itemIds': itemIds, 'archive': archive},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchSetCategory(
    int houseId, {
    required List<int> itemIds,
    required int? categoryId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/category',
      body: {'itemIds': itemIds, 'categoryId': categoryId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchSetStores(
    int houseId, {
    required List<int> itemIds,
    required List<int> storeIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/stores',
      body: {'itemIds': itemIds, 'storeIds': storeIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  /// Replaces the label set on every item (an empty list clears them),
  /// mirroring `batch/stores`. Returns the [PantryBatchResult] envelope.
  Future<PantryBatchResult> batchSetLabels(
    int houseId, {
    required List<int> itemIds,
    required List<int> labelIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/labels',
      body: {'itemIds': itemIds, 'labelIds': labelIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  /// Clears the done-state on every checked item in one request.
  /// Idempotent: already-unchecked items are left alone and omitted from the
  /// returned `items`. Permission `canCheckItems`.
  Future<PantryBatchResult> batchUncheckItems(
    int houseId, {
    required List<int> itemIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/uncheck',
      body: {'itemIds': itemIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }
}
