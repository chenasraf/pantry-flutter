part of 'checklist_service.dart';

// Templates feed checklists and inventories: their items are suggested in the
// add box, drawn one at a time, or applied whole. Needs
// [ServerFeature.templates].
extension ChecklistServiceTemplates on ChecklistService {
  /// The items of the templates attached to a checklist or inventory, one row
  /// per name. Matching what was typed is up to the caller.
  Future<List<TemplateSuggestion>> getTemplateSuggestions(
    int houseId,
    int listId,
  ) async {
    return ApiClient.instance
        .get<Map<String, dynamic>, List<TemplateSuggestion>>(
          '${listPath(houseId, listId)}/suggestions',
          query: {'archived': 'false'},
          fromJson: (data) => [
            for (final row in (data['templates'] as List?) ?? const [])
              TemplateSuggestion.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
          ],
        );
  }

  /// Copies template item [templateItemId] onto a checklist or inventory, or
  /// brings back the same-name item already there.
  Future<DrawResult> drawTemplateItem(
    int houseId,
    int listId,
    int templateItemId,
  ) async {
    return ApiClient.instance.post<Map<String, dynamic>, DrawResult>(
      '${listPath(houseId, listId)}/items/draw',
      body: {'templateItemId': templateItemId},
      fromJson: (data) => DrawResult.fromJson(data),
    );
  }

  Future<AttachedTemplates> getAttachedTemplates(
    int houseId,
    int listId,
  ) async {
    return ApiClient.instance.get<Map<String, dynamic>, AttachedTemplates>(
      '${listPath(houseId, listId)}/templates',
      fromJson: (data) => AttachedTemplates.fromJson(data),
    );
  }

  /// Replaces the templates attached to a checklist or inventory by name.
  /// Templates attached to every list stay attached regardless.
  Future<AttachedTemplates> setAttachedTemplates(
    int houseId,
    int listId,
    List<int> templateIds,
  ) async {
    return ApiClient.instance.put<Map<String, dynamic>, AttachedTemplates>(
      '${listPath(houseId, listId)}/templates',
      body: {'templateIds': templateIds},
      fromJson: (data) => AttachedTemplates.fromJson(data),
    );
  }

  Future<TemplateLists> getTemplateLists(int houseId, int templateId) async {
    return ApiClient.instance.get<Map<String, dynamic>, TemplateLists>(
      '${kindPath(houseId, ListKind.template)}/$templateId/lists',
      fromJson: (data) => TemplateLists.fromJson(data),
    );
  }

  Future<TemplateLists> setTemplateLists(
    int houseId,
    int templateId,
    TemplateLists value,
  ) async {
    return ApiClient.instance.put<Map<String, dynamic>, TemplateLists>(
      '${kindPath(houseId, ListKind.template)}/$templateId/lists',
      body: value.toJson(),
      fromJson: (data) => TemplateLists.fromJson(data),
    );
  }

  Future<FillFromItemDefaults> getFillFromItemDefaultsPref(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, FillFromItemDefaults>(
      '/houses/$houseId/prefs',
      fromJson: (data) =>
          FillFromItemDefaults.parse(data['fillFromItemDefaults']),
    );
  }

  Future<void> setFillFromItemDefaultsPref(
    int houseId,
    FillFromItemDefaults value,
  ) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'fillFromItemDefaults': value.wire},
      fromJson: (_) {},
    );
  }
}
