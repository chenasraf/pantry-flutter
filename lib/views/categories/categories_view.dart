import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/create_category_dialog.dart';

class CategoriesView extends StatefulWidget {
  final int houseId;

  const CategoriesView({super.key, required this.houseId});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  static const _allSortKeys = ['custom', 'name_asc', 'name_desc'];
  List<String> get _sortKeys => hasFeature('category-sort')
      ? _allSortKeys
      : _allSortKeys.where((k) => k != 'custom').toList();

  List<Category> _categories = [];
  String _sort = 'custom';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefsFuture = ChecklistService.instance.getHousePrefs(
        widget.houseId,
      );
      final categoriesFuture = CategoryService.instance.getCategories(
        widget.houseId,
      );
      final results = await Future.wait([prefsFuture, categoriesFuture]);
      if (!mounted) return;
      final prefs = results[0] as Map<String, dynamic>;
      final list = results[1] as List<Category>;
      setState(() {
        var sort = prefs['categorySort'] as String? ?? 'custom';
        if (sort == 'custom' && !hasFeature('category-sort')) {
          sort = 'name_asc';
        }
        _sort = sort;
        _categories = CategoryService.sortCategories(list, _sort);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setSort(String? value) async {
    if (value == null || value == _sort) return;
    setState(() {
      _sort = value;
      _categories = CategoryService.sortCategories(_categories, _sort);
    });
    try {
      await CategoryService.instance.setCategorySortPref(widget.houseId, value);
    } catch (e) {
      debugPrint('[CategoriesView] Failed to persist sort: $e');
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_sort != 'custom') return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    final order = <Map<String, int>>[];
    for (var i = 0; i < _categories.length; i++) {
      order.add({'id': _categories[i].id, 'sortOrder': i});
    }

    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.category,
        op: SyncOpKind.reorder,
        houseId: widget.houseId,
        body: {'order': order},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _create() async {
    final created = await showDialog<Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(houseId: widget.houseId),
    );
    if (created != null) {
      setState(() {
        _categories = CategoryService.sortCategories([
          ..._categories,
          created,
        ], _sort);
      });
    }
  }

  Future<void> _edit(Category category) async {
    final updated = await showDialog<Category>(
      context: context,
      builder: (_) =>
          CreateCategoryDialog(houseId: widget.houseId, existing: category),
    );
    if (updated != null) {
      setState(() {
        final index = _categories.indexWhere((c) => c.id == updated.id);
        if (index != -1) {
          _categories[index] = updated;
          _categories = CategoryService.sortCategories(_categories, _sort);
        }
      });
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.categories.deleteConfirm),
        content: Text(m.categories.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _categories = _categories.where((c) => c.id != category.id).toList();
    });
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.category,
        op: SyncOpKind.delete,
        houseId: widget.houseId,
        entityId: category.id < 0 ? null : category.id,
        tempEntityId: category.id < 0 ? category.id : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  String _sortLabel(String key) => switch (key) {
    'name_asc' => m.categories.sort.nameAZ,
    'name_desc' => m.categories.sort.nameZA,
    _ => m.categories.sort.custom,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.categories.manageTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '',
            onSelected: _setSort,
            itemBuilder: (context) => [
              for (final key in _sortKeys)
                PopupMenuItem<String>(
                  value: key,
                  child: Row(
                    children: [
                      Icon(
                        key == _sort
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: key == _sort ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(_sortLabel(key)),
                    ],
                  ),
                ),
            ],
          ),
          if (PlatformInfo.isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: m.common.refresh,
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(m.common.retry)),
                  ],
                ),
              ),
            )
          : _categories.isEmpty
          ? Center(child: Text(m.categories.noCategories))
          : RefreshIndicator(
              onRefresh: _load,
              child: _sort == 'custom'
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _categories.length,
                      onReorder: _reorder,
                      itemBuilder: (context, index) =>
                          _buildTile(theme, _categories[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) =>
                          _buildTile(theme, _categories[index]),
                    ),
            ),
    );
  }

  Widget _buildTile(ThemeData theme, Category cat) {
    final color = _parseColor(cat.color) ?? theme.colorScheme.primary;
    return ListTile(
      key: ValueKey(cat.id),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Icon(categoryIcon(cat.icon), color: color),
      ),
      title: Text(cat.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _edit(cat),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _delete(cat),
          ),
          if (_sort == 'custom')
            ReorderableDragStartListener(
              index: _categories.indexOf(cat),
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      onTap: () => _edit(cat),
    );
  }
}
