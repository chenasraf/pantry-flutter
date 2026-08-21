import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/services/store_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
import 'package:pantry/widgets/store_detail_dialog.dart';

class StoresView extends StatefulWidget {
  final int houseId;

  const StoresView({super.key, required this.houseId});

  @override
  State<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<StoresView> {
  static const _allSortKeys = ['custom', 'name_asc', 'name_desc'];
  List<String> get _sortKeys => hasFeature('store-sort')
      ? _allSortKeys
      : _allSortKeys.where((k) => k != 'custom').toList();

  List<Store> _stores = [];
  String _sort = 'name_asc';
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
      final storesFuture = StoreService.instance.getStores(widget.houseId);
      final results = await Future.wait([prefsFuture, storesFuture]);
      if (!mounted) return;
      final prefs = results[0] as Map<String, dynamic>;
      final list = results[1] as List<Store>;
      setState(() {
        var sort = prefs['storeSort'] as String? ?? 'name_asc';
        if (sort == 'custom' && !hasFeature('store-sort')) {
          sort = 'name_asc';
        }
        _sort = sort;
        _stores = StoreService.sortStores(list, _sort);
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
      _stores = StoreService.sortStores(_stores, _sort);
    });
    try {
      await StoreService.instance.setStoreSortPref(widget.houseId, value);
    } catch (e) {
      debugPrint('[StoresView] Failed to persist sort: $e');
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_sort != 'custom') return;
    setState(() {
      final item = _stores.removeAt(oldIndex);
      _stores.insert(newIndex, item);
    });

    final order = <Map<String, int>>[];
    for (var i = 0; i < _stores.length; i++) {
      order.add({'id': _stores[i].id, 'sortOrder': i});
    }

    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.store,
        op: SyncOpKind.reorder,
        houseId: widget.houseId,
        body: {'order': order},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _create() async {
    final created = await showDialog<Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: widget.houseId),
    );
    if (created != null) {
      setState(() {
        _stores = StoreService.sortStores([..._stores, created], _sort);
      });
    }
  }

  Future<void> _edit(Store store) async {
    final updated = await showDialog<Store>(
      context: context,
      builder: (_) =>
          CreateStoreDialog(houseId: widget.houseId, existing: store),
    );
    _applyUpdated(updated);
  }

  Future<void> _view(Store store) async {
    final updated = await showStoreDetails(context, store);
    _applyUpdated(updated);
  }

  void _applyUpdated(Store? updated) {
    if (updated == null) return;
    setState(() {
      final index = _stores.indexWhere((s) => s.id == updated.id);
      if (index != -1) {
        _stores[index] = updated;
        _stores = StoreService.sortStores(_stores, _sort);
      }
    });
  }

  Future<void> _delete(Store store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.stores.deleteConfirm),
        content: Text(m.stores.deleteConfirmBody),
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
      _stores = _stores.where((s) => s.id != store.id).toList();
    });
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.store,
        op: SyncOpKind.delete,
        houseId: widget.houseId,
        entityId: store.id < 0 ? null : store.id,
        tempEntityId: store.id < 0 ? store.id : null,
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
    'name_asc' => m.stores.sort.nameAZ,
    'name_desc' => m.stores.sort.nameZA,
    _ => m.stores.sort.custom,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.stores.manageTitle),
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
          : _stores.isEmpty
          ? Center(child: Text(m.stores.noStores))
          : RefreshIndicator(
              onRefresh: _load,
              child: _sort == 'custom'
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _stores.length,
                      onReorderItem: _reorder,
                      itemBuilder: (context, index) =>
                          _buildTile(theme, _stores[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: _stores.length,
                      itemBuilder: (context, index) =>
                          _buildTile(theme, _stores[index]),
                    ),
            ),
    );
  }

  Widget _buildTile(ThemeData theme, Store store) {
    final color = _parseColor(store.color) ?? theme.colorScheme.primary;
    return ListTile(
      key: ValueKey(store.id),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Icon(storeIcon(store.icon), color: color),
      ),
      title: Text(store.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _edit(store),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _delete(store),
          ),
          if (_sort == 'custom')
            ReorderableDragStartListener(
              index: _stores.indexOf(store),
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      onTap: () => _view(store),
    );
  }
}
