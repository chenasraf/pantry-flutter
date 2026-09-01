part of 'checklists_body_controller.dart';

extension ChecklistsBodyNavigation on ChecklistsBodyController {
  /// Open the shopping flow: resume the live session, or run the start screen
  /// (which returns a freshly created session to navigate into). Refreshes the
  /// banner / FAB on return.
  Future<void> openShopping(BuildContext context) async {
    final existing = shoppingSession;
    if (existing != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShoppingSessionView(session: existing),
        ),
      );
    } else {
      final currentId = domain.currentList?.id;
      final created = await Navigator.of(context).push<ShoppingSession?>(
        MaterialPageRoute(
          builder: (_) => ShoppingStartView(
            houseId: domain.houseId,
            preselectListId: (currentId != null && currentId > 0)
                ? currentId
                : null,
          ),
        ),
      );
      if (created != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShoppingSessionView(session: created),
          ),
        );
      }
    }
    await refreshShoppingSession();
  }

  Future<void> openShoppingHistory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingHistoryView(houseId: domain.houseId),
      ),
    );
    await refreshShoppingSession();
  }

  Future<void> openManageCategories(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoriesView(houseId: domain.houseId),
      ),
    );
    await domain.onCategoriesChanged();
  }

  Future<void> openManageCustomFields(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomFieldsView(houseId: domain.houseId),
      ),
    );
  }

  /// Opens the create-category dialog inline from the compose bar's category
  /// tray. On success, refreshes the controller's category list (so the new
  /// option shows up in the tray) and returns the new Category so compose bar
  /// can auto-select it on the draft.
  Future<models.Category?> createCategory(
    BuildContext context, {
    int? defaultListId,
  }) async {
    final created = await Navigator.of(context).push<models.Category>(
      itemModalRoute(
        CategoryFormView(houseId: domain.houseId, defaultListId: defaultListId),
      ),
    );
    if (created != null) {
      await domain.onCategoriesChanged();
    }
    return created;
  }

  Future<void> openManageStores(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoresView(houseId: domain.houseId)),
    );
    await domain.onStoresChanged();
  }

  Future<void> openManageLabels(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LabelsView(houseId: domain.houseId)),
    );
    await domain.onLabelsChanged();
  }

  /// Opens the create-store dialog inline from the compose bar's store tray. On
  /// success, refreshes the controller's store list (so the new option shows up
  /// in the tray) and returns the new Store so compose bar can auto-select it.
  Future<models.Store?> createStore(BuildContext context) async {
    final created = await showDialog<models.Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: domain.houseId),
    );
    if (created != null) {
      await domain.onStoresChanged();
    }
    return created;
  }

  /// Opens the create-label dialog inline from the compose bar's label tray. On
  /// success, refreshes the controller's label list (so the new option shows up
  /// in the tray) and returns the new Label so compose bar can auto-select it.
  Future<models.Label?> createLabel(
    BuildContext context, {
    int? defaultListId,
  }) async {
    final created = await showDialog<models.Label>(
      context: context,
      builder: (_) => CreateLabelDialog(
        houseId: domain.houseId,
        defaultListId: defaultListId,
      ),
    );
    if (created != null) {
      await domain.onLabelsChanged();
    }
    return created;
  }
}
