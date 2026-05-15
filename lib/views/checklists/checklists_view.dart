import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:provider/provider.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/widgets/checklist_selector.dart';
import 'package:pantry/widgets/checklist_sort_button.dart';
import 'package:pantry/widgets/create_list_dialog.dart';
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

class _ChecklistsBody extends StatefulWidget {
  const _ChecklistsBody();

  @override
  State<_ChecklistsBody> createState() => _ChecklistsBodyState();
}

class _ChecklistsBodyState extends State<_ChecklistsBody> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final Set<int> _selectedCategoryIds = {};

  String get _query => _searchController.text.trim().toLowerCase();

  bool get _isFiltering =>
      _searchOpen && (_query.isNotEmpty || _selectedCategoryIds.isNotEmpty);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _selectedCategoryIds.clear();
      }
    });
  }

  List<ListItem> _filterItems(List<ListItem> items) {
    if (!_isFiltering) return items;

    return items.where((item) {
      // Category filter
      if (_selectedCategoryIds.isNotEmpty) {
        if (!_selectedCategoryIds.contains(item.categoryId)) return false;
      }

      // Text filter
      if (_query.isNotEmpty) {
        final nameMatch = item.name.toLowerCase().contains(_query);
        final descMatch =
            item.description?.toLowerCase().contains(_query) ?? false;
        if (!nameMatch && !descMatch) return false;
      }

      return true;
    }).toList();
  }

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

    final filteredItems = _filterItems(controller.items);

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
        child: _ItemList(
          controller: controller,
          items: filteredItems,
          isFiltering: _isFiltering,
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ChecklistSelector(
                    lists: controller.lists,
                    currentList: controller.currentList,
                    onSelected: controller.selectList,
                    onCreateNew: () => _createList(context, controller),
                  ),
                ),
                IconButton(
                  icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
                  onPressed: _toggleSearch,
                ),
                ChecklistSortButton(
                  currentSort: controller.sortBy,
                  onSelected: controller.setSortBy,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _searchOpen
                  ? _SearchPanel(
                      searchController: _searchController,
                      selectedCategoryIds: _selectedCategoryIds,
                      items: controller.items,
                      categories: controller.categories,
                      onChanged: () => setState(() {}),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(child: itemsArea),
          ],
        ),
        if (controller.currentList != null)
          PositionedDirectional(
            end: 16,
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

  Future<void> _createList(
    BuildContext context,
    ChecklistsController controller,
  ) async {
    final created = await showCreateListDialog(context, controller);
    if (created != null) {
      await controller.selectList(created);
    }
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController searchController;
  final Set<int> selectedCategoryIds;
  final List<ListItem> items;
  final Map<int, models.Category> categories;
  final VoidCallback onChanged;

  const _SearchPanel({
    required this.searchController,
    required this.selectedCategoryIds,
    required this.items,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Collect categories actually used in the current list, with counts
    final categoryCounts = <int, int>{};
    for (final item in items) {
      if (item.categoryId != null) {
        categoryCounts[item.categoryId!] =
            (categoryCounts[item.categoryId!] ?? 0) + 1;
      }
    }

    // Sort by category sortOrder
    final usedCategories =
        categoryCounts.keys.where((id) => categories.containsKey(id)).toList()
          ..sort(
            (a, b) =>
                categories[a]!.sortOrder.compareTo(categories[b]!.sortOrder),
          );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: m.checklists.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: ListenableBuilder(
                listenable: searchController,
                builder: (_, _) => searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onChanged();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
          if (usedCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: m.checklists.allCategories,
                    count: items.length,
                    selected: selectedCategoryIds.isEmpty,
                    color: theme.colorScheme.primary,
                    onTap: () {
                      selectedCategoryIds.clear();
                      onChanged();
                    },
                  ),
                  const SizedBox(width: 6),
                  ...usedCategories.map((catId) {
                    final cat = categories[catId]!;
                    final count = categoryCounts[catId]!;
                    final color = _parseColor(cat.color, theme);
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: _CategoryChip(
                        icon: categoryIcon(cat.icon),
                        label: cat.name,
                        count: count,
                        selected: selectedCategoryIds.contains(catId),
                        color: color,
                        onTap: () {
                          if (selectedCategoryIds.contains(catId)) {
                            selectedCategoryIds.remove(catId);
                          } else {
                            selectedCategoryIds.add(catId);
                          }
                          onChanged();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _parseColor(String hex, ThemeData theme) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(value | 0xFF000000);
    } catch (_) {
      return theme.colorScheme.primary;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = selected ? color : theme.colorScheme.onSurfaceVariant;

    return FilterChip(
      avatar: icon != null ? Icon(icon, size: 16, color: fgColor) : null,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 6),
          _CountBadge(count: count, color: fgColor),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.2),
      showCheckmark: false,
      labelStyle: TextStyle(fontSize: 12, color: selected ? color : null),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: count < 100 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: count >= 100 ? BorderRadius.circular(10) : null,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final ChecklistsController controller;
  final List<ListItem> items;
  final bool isFiltering;

  const _ItemList({
    required this.controller,
    required this.items,
    required this.isFiltering,
  });

  @override
  Widget build(BuildContext context) {
    final unchecked = items.where((i) => !i.done).toList();
    final checked = items.where((i) => i.done).toList();

    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              isFiltering ? m.checklists.noSearchResults : m.checklists.noItems,
            ),
          ),
        ],
      );
    }

    final spacingPref = context.watch<PrefsService>().checklistCategorySpacing;
    final categorySpacing = controller.sortBy == 'category'
        ? spacingPref
        : 'disabled';

    return CustomScrollView(
      slivers: [
        _ReorderablePartition(
          items: unchecked,
          controller: controller,
          categorySpacing: categorySpacing,
        ),
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
          _ReorderablePartition(
            items: checked,
            controller: controller,
            categorySpacing: categorySpacing,
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _ReorderablePartition extends StatelessWidget {
  final List<ListItem> items;
  final ChecklistsController controller;
  final String categorySpacing;

  const _ReorderablePartition({
    required this.items,
    required this.controller,
    this.categorySpacing = 'disabled',
  });

  void _toggleItem(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    final wasDone = item.done;
    controller.toggleItem(item);
    if (wasDone) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(m.checklists.itemMarkedDone),
        action: SnackBarAction(
          label: m.checklists.undo,
          onPressed: () {
            final current = controller.items.firstWhere(
              (i) => i.id == item.id,
              orElse: () => item.copyWith(done: true),
            );
            if (current.done) controller.toggleItem(current);
          },
        ),
      ),
    );
  }

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

  void _moveItem(
    BuildContext context,
    ChecklistsController controller,
    ListItem item,
  ) {
    final otherLists = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .toList();

    showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.moveItem),
        children: [
          ...otherLists.map(
            (list) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Text(list.name),
                ],
              ),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              final created = await showCreateListDialog(context, controller);
              if (created != null && context.mounted) {
                try {
                  await controller.moveItem(item, created.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(m.checklists.moveFailed)),
                    );
                  }
                }
              }
            },
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  m.checklists.createList,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).then((targetListId) async {
      if (targetListId == null) return;
      try {
        await controller.moveItem(item, targetListId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.checklists.moveFailed)));
        }
      }
    });
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
        final showSeparator =
            categorySpacing != 'disabled' &&
            index > 0 &&
            items[index - 1].categoryId != item.categoryId;
        final tile = ChecklistItemTile(
          item: item,
          category: item.categoryId != null
              ? controller.categories[item.categoryId]
              : null,
          houseId: controller.houseId,
          onToggle: (item) => _toggleItem(context, controller, item),
          onView: (item) => _viewItem(context, controller, item),
          onEdit: (item) => _editItem(context, controller, item),
          onMove: (item) => _moveItem(context, controller, item),
          onDelete: (item) => _deleteItem(context, controller, item),
        );
        return ReorderableDelayedDragStartListener(
          key: ValueKey(item.id),
          index: index,
          child: showSeparator
              ? Column(
                  children: [
                    if (categorySpacing == 'divider')
                      const Divider(height: 25)
                    else
                      const SizedBox(height: 20),
                    tile,
                  ],
                )
              : tile,
        );
      },
    );
  }
}
