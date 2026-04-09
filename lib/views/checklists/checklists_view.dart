import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:provider/provider.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'checklist_item_tile.dart';
import 'checklists_controller.dart';
import 'item_detail_view.dart';
import 'item_form_view.dart';

class ChecklistsView extends StatefulWidget {
  final int houseId;

  const ChecklistsView({super.key, required this.houseId});

  @override
  State<ChecklistsView> createState() => _ChecklistsViewState();
}

class _ChecklistsViewState extends State<ChecklistsView> {
  late final _controller = ChecklistsController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _ChecklistsBody(),
    );
  }
}

class _ChecklistsBody extends StatelessWidget {
  const _ChecklistsBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChecklistsController>();

    if (controller.isLoading && controller.lists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.lists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.lists.isEmpty) {
      return Center(child: Text(m.checklists.noChecklists));
    }

    Widget itemsArea;
    if (controller.isLoading) {
      itemsArea = const Center(child: CircularProgressIndicator());
    } else if (controller.error != null) {
      itemsArea = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    } else {
      itemsArea = RefreshIndicator(
        onRefresh: controller.refresh,
        child: _ItemList(controller: controller),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ListSelector(
                    lists: controller.lists,
                    currentList: controller.currentList,
                    onSelected: controller.selectList,
                  ),
                ),
                _SortButton(
                  currentSort: controller.sortBy,
                  onSelected: controller.setSortBy,
                ),
              ],
            ),
            Expanded(child: itemsArea),
          ],
        ),
        if (controller.currentList != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final added = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ItemFormView(controller: controller),
                  ),
                );
                if (added == true) {
                  controller.refresh();
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}

class _ListSelector extends StatelessWidget {
  final List<ChecklistList> lists;
  final ChecklistList? currentList;
  final ValueChanged<ChecklistList> onSelected;

  const _ListSelector({
    required this.lists,
    required this.currentList,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: DropdownButtonFormField<int>(
        initialValue: currentList?.id,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: lists
            .map(
              (list) => DropdownMenuItem(
                value: list.id,
                child: Row(
                  children: [
                    Icon(checklistIcon(list.icon), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(list.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => lists
            .map(
              (list) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 8),
                  Text(list.name, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
            .toList(),
        onChanged: (id) {
          if (id == null) return;
          final list = lists.firstWhere((l) => l.id == id);
          onSelected(list);
        },
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final ChecklistsController controller;

  const _ItemList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final unchecked = controller.items.where((i) => !i.done).toList();
    final checked = controller.items.where((i) => i.done).toList();

    if (controller.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(m.checklists.noItems)),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        _ReorderablePartition(items: unchecked, controller: controller),
        if (checked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Text(
                    m.checklists.completedCount(checked.length),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ReorderablePartition(items: checked, controller: controller),
        ],
      ],
    );
  }
}

class _ReorderablePartition extends StatelessWidget {
  final List<ListItem> items;
  final ChecklistsController controller;

  const _ReorderablePartition({required this.items, required this.controller});

  void _viewItem(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailView(
          item: item,
          category: item.categoryId != null
              ? controller.categories[item.categoryId]
              : null,
          houseId: controller.houseId,
          controller: controller,
        ),
      ),
    );
  }

  void _editItem(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormView(controller: controller, item: item),
      ),
    );
  }

  void _deleteItem(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.itemForm.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await controller.deleteItem(item);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(m.checklists.itemForm.deleteFailed)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverReorderableList(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        controller.reorderItems(items, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(item.id),
          index: index,
          child: ChecklistItemTile(
            item: item,
            category: item.categoryId != null
                ? controller.categories[item.categoryId]
                : null,
            houseId: controller.houseId,
            onToggle: controller.toggleItem,
            onView: (item) => _viewItem(context, controller, item),
            onEdit: (item) => _editItem(context, controller, item),
            onDelete: (item) => _deleteItem(context, controller, item),
          ),
        );
      },
    );
  }
}

class _SortButton extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelected;

  const _SortButton({required this.currentSort, required this.onSelected});

  static const _sortKeys = [
    'newest',
    'oldest',
    'name_asc',
    'name_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.checklists.sort.newestFirst,
    'oldest' => m.checklists.sort.oldestFirst,
    'name_asc' => m.checklists.sort.nameAZ,
    'name_desc' => m.checklists.sort.nameZA,
    'custom' => m.checklists.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final key in _sortKeys)
          PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(
                  key == currentSort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: key == currentSort
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_label(key)),
              ],
            ),
          ),
      ],
    );
  }
}
