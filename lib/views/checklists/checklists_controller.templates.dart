part of 'checklists_controller.dart';

extension ChecklistsControllerTemplates on ChecklistsController {
  /// Whether [listId]'s add box draws from templates: checklists and
  /// inventories do, templates themselves don't.
  bool drawsFromTemplates(int listId) =>
      ServerFeature.templates &&
      listId > 0 &&
      _checklistService.kindOf(listId) != ListKind.template;

  /// Items of the templates attached to [listId], as loaded so far. Pair with
  /// [ensureTemplateSuggestionsLoaded] to trigger the fetch.
  List<TemplateSuggestion> templateSuggestions(int listId) =>
      _templateSuggestions[listId] ?? const [];

  /// Kick off the one-time lazy fetch of [listId]'s template suggestions. A
  /// no-op once requested, until the cache is reset.
  void ensureTemplateSuggestionsLoaded(int listId) {
    if (!drawsFromTemplates(listId)) return;
    if (!_templateSuggestionsRequested.add(listId)) return;
    unawaited(_fetchTemplateSuggestions(listId));
  }

  Future<void> _fetchTemplateSuggestions(int listId) async {
    try {
      final rows = await _checklistService.getTemplateSuggestions(
        houseId,
        listId,
      );
      if (_disposed) return;
      _templateSuggestions[listId] = rows;
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load suggestions: $e');
      // Allow a later search to retry.
      _templateSuggestionsRequested.remove(listId);
    }
  }

  /// Forget every loaded template suggestion, so the next search refetches
  /// what templates are attached and what they hold.
  void _resetTemplateSuggestions() {
    _templateSuggestions.clear();
    _templateSuggestionsRequested.clear();
  }

  /// Draws template item [templateItemId] onto [targetListId]. Online only:
  /// the server decides whether a same-name item is brought back and mints
  /// the copy's id and any scoped categories, labels and fields it copies.
  Future<DrawResult> drawTemplateItem(
    int templateItemId, {
    required int targetListId,
  }) async {
    final result = await _checklistService.drawTemplateItem(
      houseId,
      targetListId,
      templateItemId,
    );
    await _refreshScopedTaxonomies();
    _mergeServerItems(targetListId, [result.item]);
    return result;
  }

  /// Copies the template items [itemIds] onto [target]. Same-name items
  /// already there are brought back rather than duplicated.
  Future<PantryBatchResult> applyTemplate(
    List<int> itemIds,
    ChecklistList target,
  ) async {
    final result = await _checklistService.batchCopyItems(
      houseId,
      itemIds: itemIds,
      targetListId: target.id,
    );
    await _refreshScopedTaxonomies();
    _mergeServerItems(target.id, result.items);
    return result;
  }

  /// Copies of template items may point at categories, labels and fields the
  /// server just copied onto the target list.
  Future<void> _refreshScopedTaxonomies() => Future.wait([
    _refreshCategories(),
    if (ServerFeature.labels) _refreshLabels(),
    if (ServerFeature.customFields) _refreshCustomFields(),
  ]);

  /// Shows [incoming] items fresh from the server on [listId]: rows already
  /// shown are replaced, new ones join. A list that isn't on screen refetches
  /// when next opened.
  void _mergeServerItems(int listId, List<ListItem> incoming) {
    for (final item in incoming) {
      _removeFromArchivedReuse(item);
    }
    final visible =
        !isSoftView &&
        (isMetaMode
            ? _checklistService.kindOf(listId) == kind
            : _currentList?.id == listId);
    if (!visible) {
      _checklistService.invalidateItemsFor(listId);
      notifyListeners();
      return;
    }
    for (final item in incoming) {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item;
      } else {
        _items.insert(_insertIndexFor(item), item);
      }
    }
    _cacheVisibleItems(listId);
    notifyListeners();
  }

  Future<AttachedTemplates> loadAttachedTemplates(int listId) =>
      _checklistService.getAttachedTemplates(houseId, listId);

  Future<AttachedTemplates> setAttachedTemplates(
    int listId,
    List<int> templateIds,
  ) async {
    final saved = await _checklistService.setAttachedTemplates(
      houseId,
      listId,
      templateIds,
    );
    _resetTemplateSuggestions();
    return saved;
  }

  Future<TemplateLists> loadTemplateLists(int templateId) =>
      _checklistService.getTemplateLists(houseId, templateId);

  Future<TemplateLists> setTemplateLists(
    int templateId,
    TemplateLists value,
  ) async {
    final saved = await _checklistService.setTemplateLists(
      houseId,
      templateId,
      value,
    );
    _resetTemplateSuggestions();
    return saved;
  }

  /// Whether [list] can take part in applying a template: as the template
  /// applied, or as a checklist or inventory it is applied to.
  bool canApplyTemplate(ChecklistList list) =>
      ServerFeature.templates &&
      permissions.canCopyItems &&
      list.id > 0 &&
      (list.kind == ListKind.template || list.isWritable);
}
