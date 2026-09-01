import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/store_icons.dart';

/// Sticky-header delegate for a store group. Fixed extent so the pinned header
/// keeps a stable height as it sticks and releases. Mirrors
/// [ChecklistsCategoryHeaderDelegate].
class ChecklistsStoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  final models.Store? store;

  const ChecklistsStoreHeaderDelegate({required this.store});

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _StoreHeader(store: store);

  @override
  bool shouldRebuild(ChecklistsStoreHeaderDelegate oldDelegate) =>
      oldDelegate.store?.id != store?.id ||
      oldDelegate.store?.color != store?.color ||
      oldDelegate.store?.name != store?.name ||
      oldDelegate.store?.icon != store?.icon;
}

/// Grouped-list header shown above each store run when sorting by store. Mirrors
/// [_CategoryHeader]: real stores render their icon + name in the store color;
/// the "No store" group falls back to muted default text.
class _StoreHeader extends StatelessWidget {
  final models.Store? store;

  const _StoreHeader({required this.store});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = store != null
        ? (parseHexColor(store!.color) ?? cs.onSurfaceVariant)
        : cs.onSurfaceVariant;
    final name = store?.name ?? m.checklists.noStore;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Icon(storeIcon(store?.icon), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky-header delegate for a category group. Fixed extent so the pinned
/// header keeps a stable height as it sticks and releases.
class ChecklistsCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final models.Category? category;

  const ChecklistsCategoryHeaderDelegate({required this.category});

  static const double _extent = 40;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => _CategoryHeader(category: category);

  @override
  bool shouldRebuild(ChecklistsCategoryHeaderDelegate oldDelegate) =>
      oldDelegate.category?.id != category?.id ||
      oldDelegate.category?.color != category?.color ||
      oldDelegate.category?.name != category?.name ||
      oldDelegate.category?.icon != category?.icon;
}

/// Grouped-list header shown above each category run when sorting by category.
/// Real categories render their icon + name in the category color; the
/// uncategorised group falls back to muted default text and label. Fills the
/// fixed height its pinned-header delegate reserves, with an opaque background
/// so item rows don't show through while it's stuck to the top.
class _CategoryHeader extends StatelessWidget {
  final models.Category? category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category != null
        ? (parseHexColor(category!.color) ?? cs.onSurfaceVariant)
        : cs.onSurfaceVariant;
    final name = category?.name ?? m.checklists.noCategory;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Icon(categoryIcon(category?.icon), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
