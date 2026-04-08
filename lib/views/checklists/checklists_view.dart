import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'checklist_item_tile.dart';
import 'checklists_controller.dart';

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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.lists.isEmpty) {
      return const Center(child: Text('No checklists yet.'));
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
                child: const Text('Retry'),
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

    return Column(
      children: [
        _ListSelector(
          lists: controller.lists,
          currentList: controller.currentList,
          onSelected: controller.selectList,
        ),
        Expanded(child: itemsArea),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No items in this list.')),
        ],
      );
    }

    return ListView(
      children: [
        for (final item in unchecked)
          ChecklistItemTile(
            key: ValueKey(item.id),
            item: item,
            category: item.categoryId != null
                ? controller.categories[item.categoryId]
                : null,
            houseId: controller.houseId,
            onToggle: controller.toggleItem,
          ),
        if (checked.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Completed (${checked.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in checked)
            ChecklistItemTile(
              key: ValueKey(item.id),
              item: item,
              category: item.categoryId != null
                  ? controller.categories[item.categoryId]
                  : null,
              houseId: controller.houseId,
              onToggle: controller.toggleItem,
            ),
        ],
      ],
    );
  }
}
