import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/store_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/create_store_dialog.dart';

class StoresView extends StatefulWidget {
  final int houseId;

  const StoresView({super.key, required this.houseId});

  @override
  State<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<StoresView> {
  List<Store> _stores = [];
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
      final stores = await StoreService.instance.getStores(widget.houseId);
      if (!mounted) return;
      setState(() {
        _stores = StoreService.sortStores(stores);
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

  Future<void> _create() async {
    final created = await showDialog<Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: widget.houseId),
    );
    if (created != null) {
      setState(() {
        _stores = StoreService.sortStores([..._stores, created]);
      });
    }
  }

  Future<void> _edit(Store store) async {
    final updated = await showDialog<Store>(
      context: context,
      builder: (_) =>
          CreateStoreDialog(houseId: widget.houseId, existing: store),
    );
    if (updated != null) {
      setState(() {
        final index = _stores.indexWhere((s) => s.id == updated.id);
        if (index != -1) {
          _stores[index] = updated;
          _stores = StoreService.sortStores(_stores);
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.stores.manageTitle),
        actions: [
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
              child: ListView.builder(
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
        ],
      ),
      onTap: () => _edit(store),
    );
  }
}
