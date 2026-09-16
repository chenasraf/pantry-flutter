import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

/// Pick which of the trip's items to actually shop, grouped by category.
///
/// Edits a draft of the exclusions and hands it back only on Done, so backing
/// out leaves the plan the caller already had. Returns the excluded item ids,
/// or null when dismissed.
Future<Set<int>?> pickShoppingItems(
  BuildContext context, {
  required List<ListItem> items,
  required Map<int, models.Category> categories,
  required Set<int> excludedItemIds,
}) {
  return Navigator.of(context).push<Set<int>>(
    itemModalRoute(
      _ShoppingItemPickerView(
        items: items,
        categories: categories,
        excludedItemIds: excludedItemIds,
      ),
    ),
  );
}

class _ShoppingItemPickerView extends StatefulWidget {
  final List<ListItem> items;
  final Map<int, models.Category> categories;
  final Set<int> excludedItemIds;

  const _ShoppingItemPickerView({
    required this.items,
    required this.categories,
    required this.excludedItemIds,
  });

  @override
  State<_ShoppingItemPickerView> createState() =>
      _ShoppingItemPickerViewState();
}

class _ShoppingItemPickerViewState extends State<_ShoppingItemPickerView> {
  late final Set<int> _excluded = {...widget.excludedItemIds};
  late final List<ShoppingItemGroup> _groups = groupShoppingItemsByCategory(
    widget.items,
    widget.categories,
  );

  bool _isPicked(ListItem item) => !_excluded.contains(item.id);

  int get _pickedCount => widget.items.where(_isPicked).length;

  void _setPicked(Iterable<ListItem> items, bool picked) {
    setState(() {
      for (final item in items) {
        if (picked) {
          _excluded.remove(item.id);
        } else {
          _excluded.add(item.id);
        }
      }
    });
  }

  void _invert() {
    setState(() {
      final scope = {for (final item in widget.items) item.id};
      final inverted = widget.items.where(_isPicked).map((i) => i.id).toSet();
      // Exclusions carried in for items outside this scope belong to lists the
      // shopper unchecked, and survive so re-checking a list restores both its
      // items and the choices already made about them.
      _excluded
        ..removeWhere(scope.contains)
        ..addAll(inverted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.items.length;
    final picked = _pickedCount;
    // A trip covering nothing has no representation on the wire, so an empty
    // pick is refused here rather than at the far end of the start screen.
    final nothingPicked = picked == 0 && total > 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: m.common.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(m.shopping.itemsToShop),
        actions: [
          TextButton(
            onPressed: nothingPicked
                ? null
                : () => Navigator.of(context).pop(_excluded),
            child: Text(m.common.closeDialog),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => _setPicked(widget.items, true),
                      icon: const Icon(Icons.select_all, size: 18),
                      label: Text(m.shopping.selectAll),
                    ),
                    TextButton.icon(
                      onPressed: () => _setPicked(widget.items, false),
                      icon: const Icon(Icons.deselect, size: 18),
                      label: Text(m.shopping.selectNone),
                    ),
                    TextButton.icon(
                      onPressed: _invert,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(m.shopping.selectInvert),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: Text(
                    nothingPicked
                        ? m.shopping.pickAtLeastOneItem
                        : m.shopping.someItemsPicked(picked, total),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: nothingPicked
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CustomScrollView(
              slivers: [
                for (final group in _groups)
                  // Header + rows as one group pins the header only while its
                  // own items are on screen — the next group pushes it off.
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoryToggleHeaderDelegate(
                          category: group.category,
                          picked: group.items.where(_isPicked).length,
                          total: group.items.length,
                          extent: _categoryHeaderExtent(context),
                          onToggle: (v) => _setPicked(group.items, v),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: group.items.length,
                        itemBuilder: (context, index) {
                          final item = group.items[index];
                          return CheckboxListTile(
                            value: _isPicked(item),
                            onChanged: (v) => _setPicked([item], v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            // Line the row's box up with the one in the
                            // category header above it.
                            contentPadding: const EdgeInsetsDirectional.only(
                              start: 4,
                              end: 16,
                            ),
                            title: Text(
                              item.name,
                              textDirection: detectTextDirection(item.name),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A pinned header needs its height up front, so the text line is measured
/// against the user's text scale rather than assumed, and floored at the
/// checkbox's tap target. Rounded to a whole pixel: a fractional extent trips
/// the sliver geometry assertions.
double _categoryHeaderExtent(BuildContext context) {
  final style = Theme.of(context).textTheme.labelLarge;
  final line = (style?.fontSize ?? 14) * (style?.height ?? 1.45);
  final scaled = MediaQuery.textScalerOf(context).scale(line);
  return math.max(scaled + 12, kMinInteractiveDimension).ceilToDouble();
}

class _CategoryToggleHeaderDelegate extends SliverPersistentHeaderDelegate {
  final models.Category? category;
  final int picked;
  final int total;
  final double extent;
  final ValueChanged<bool> onToggle;

  const _CategoryToggleHeaderDelegate({
    required this.category,
    required this.picked,
    required this.total,
    required this.extent,
    required this.onToggle,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(
    // The header is laid out loosely, so it has to be held at exactly the
    // extent it declares or the sliver geometry disagrees with itself.
    height: extent,
    child: _CategoryToggleHeader(
      category: category,
      picked: picked,
      total: total,
      onToggle: onToggle,
    ),
  );

  @override
  bool shouldRebuild(_CategoryToggleHeaderDelegate oldDelegate) =>
      oldDelegate.category != category ||
      oldDelegate.picked != picked ||
      oldDelegate.total != total ||
      oldDelegate.extent != extent;
}

class _CategoryToggleHeader extends StatelessWidget {
  final models.Category? category;
  final int picked;
  final int total;
  final ValueChanged<bool> onToggle;

  const _CategoryToggleHeader({
    required this.category,
    required this.picked,
    required this.total,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(category?.color) ?? theme.colorScheme.primary;
    final name = category?.name ?? m.shopping.uncategorized;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => onToggle(picked != total),
        child: Padding(
          // A bare checkbox centres inside a wider tap target than a list
          // tile's does, so the header starts flush to line its box up with
          // the rows'.
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Row(
            children: [
              Checkbox(
                value: picked == 0
                    ? false
                    : picked == total
                    ? true
                    : null,
                tristate: true,
                onChanged: (_) => onToggle(picked != total),
              ),
              Icon(categoryIcon(category?.icon), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  textDirection: detectTextDirection(name),
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              Text('$picked/$total', style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
