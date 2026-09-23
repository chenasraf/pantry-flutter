import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/store_icons.dart';

/// Arrange one store's categories into the order its aisles are walked.
///
/// Deliberately flat where the category manager groups by list scope: a store
/// is walked by aisle and doesn't care which list an item came from, so a drag
/// moves a category anywhere in the sequence.
class StoreCategoryOrderView extends StatefulWidget {
  final int houseId;

  const StoreCategoryOrderView({super.key, required this.houseId});

  @override
  State<StoreCategoryOrderView> createState() => _StoreCategoryOrderViewState();
}

class _StoreCategoryOrderViewState extends State<StoreCategoryOrderView> {
  List<Store> _stores = [];
  List<Category> _categories = [];

  int? _storeId;

  /// The categories in the order the picked store is walked — what the list
  /// renders and what a drop persists.
  List<Category> _ordered = [];

  /// The store's arrangement as stored. Empty means it follows the house-wide
  /// order, which [_ordered] renders identically — so this is what tells the
  /// two apart for the "use the shared order" action.
  List<int> _arrangedIds = const [];

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
      final results = await Future.wait([
        StoreService.instance.getStores(widget.houseId),
        CategoryService.instance.getCategories(widget.houseId),
      ]);
      if (!mounted) return;
      final stores = StoreService.sortStores(
        results[0] as List<Store>,
        'custom',
      );
      setState(() {
        _stores = stores;
        _categories = results[1] as List<Category>;
        if (!stores.any((s) => s.id == _storeId)) {
          _storeId = stores.isEmpty ? null : stores.first.id;
        }
      });
      await _loadOrder();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrder() async {
    final storeId = _storeId;
    if (storeId == null) {
      setState(() {
        _arrangedIds = const [];
        _ordered = [];
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      // Draw the cached arrangement while the read is in flight, so switching
      // store doesn't blank a list that is almost always already known.
      _applyArrangement(
        CategoryService.instance.getCachedStoreCategoryOrder(
              widget.houseId,
              storeId,
            ) ??
            const [],
      );
    });
    try {
      final ids = await CategoryService.instance.getStoreCategoryOrder(
        widget.houseId,
        storeId,
      );
      if (!mounted || storeId != _storeId) return;
      setState(() {
        _applyArrangement(ids);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || storeId != _storeId) return;
      setState(() {
        _error = m.categories.storeOrder.loadFailed;
        _isLoading = false;
      });
    }
  }

  void _applyArrangement(List<int> ids) {
    _arrangedIds = ids;
    _ordered = CategoryService.orderForStore(_categories, ids);
  }

  Future<void> _pickStore(int? storeId) async {
    if (storeId == null || storeId == _storeId) return;
    setState(() => _storeId = storeId);
    await _loadOrder();
  }

  void _reorder(int oldIndex, int newIndex) {
    final storeId = _storeId;
    if (storeId == null || oldIndex == newIndex) return;
    setState(() {
      final moved = _ordered.removeAt(oldIndex);
      _ordered.insert(newIndex, moved);
      // Every category now has a place in this store, whether or not it had one
      // before — the whole sequence is what the endpoint stores.
      _arrangedIds = [for (final c in _ordered) c.id];
    });
    CategoryService.instance.cacheStoreCategoryOrder(
      widget.houseId,
      storeId,
      _arrangedIds,
    );
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.storeCategoryOrder,
        op: SyncOpKind.reorder,
        houseId: widget.houseId,
        entityId: storeId < 0 ? null : storeId,
        tempEntityId: storeId < 0 ? storeId : null,
        body: {'order': _arrangedIds},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _useSharedOrder() {
    final storeId = _storeId;
    if (storeId == null) return;
    setState(() => _applyArrangement(const []));
    CategoryService.instance.cacheStoreCategoryOrder(
      widget.houseId,
      storeId,
      const [],
    );
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.storeCategoryOrder,
        op: SyncOpKind.delete,
        houseId: widget.houseId,
        entityId: storeId < 0 ? null : storeId,
        tempEntityId: storeId < 0 ? storeId : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(m.categories.storeOrder.title),
        actions: [
          if (PlatformInfo.isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: m.common.refresh,
              onPressed: _load,
            ),
        ],
      ),
      // The picker reads its selection once, at build, so nothing is drawn
      // until the stores have landed and one of them is picked.
      body: _stores.isEmpty
          ? _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildMessage(theme, _error!, onRetry: _load)
                : _buildMessage(theme, m.categories.storeOrder.noStores)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                  child: Text(
                    m.categories.storeOrder.hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  child: _buildStorePicker(theme),
                ),
                if (_arrangedIds.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                      child: TextButton.icon(
                        icon: const Icon(Icons.restore, size: 20),
                        label: Text(m.categories.storeOrder.useSharedOrder),
                        onPressed: _useSharedOrder,
                      ),
                    ),
                  ),
                Expanded(child: _buildBody(theme)),
              ],
            ),
    );
  }

  Widget _buildStorePicker(ThemeData theme) => DropdownButtonFormField<int>(
    initialValue: _storeId,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: m.categories.storeOrder.store,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final store in _stores)
        DropdownMenuItem<int>(
          value: store.id,
          child: Row(
            children: [
              Icon(
                storeIcon(store.icon),
                size: 20,
                color: parseHexColor(store.color) ?? theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(store.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
    ],
    onChanged: _pickStore,
  );

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _ordered.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessage(theme, _error!, onRetry: _loadOrder);
    }
    if (_ordered.isEmpty) {
      return _buildMessage(theme, m.categories.noCategories);
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: _ordered.length,
      buildDefaultDragHandles: false,
      onReorderItem: _reorder,
      itemBuilder: (context, index) =>
          _buildTile(theme, _ordered[index], index),
    );
  }

  Widget _buildTile(ThemeData theme, Category category, int index) {
    final color = parseHexColor(category.color) ?? theme.colorScheme.primary;
    return ListTile(
      key: ValueKey(category.id),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Icon(categoryIcon(category.icon), color: color),
      ),
      title: Text(category.name),
      trailing: ReorderableDragStartListener(
        index: index,
        child: Padding(
          // Touch-sized: the handle is the only way to move a row here.
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
          child: Icon(
            Icons.drag_handle,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(
    ThemeData theme,
    String message, {
    VoidCallback? onRetry,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ],
      ),
    ),
  );
}
