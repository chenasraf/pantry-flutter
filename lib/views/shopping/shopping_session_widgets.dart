import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/views/shopping/shopping_item_row.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/member_avatar.dart';

/// Horizontal, scrollable row of store pills. The active pill is filled; past
/// pills (lower position) are dimmed. Each pill carries the avatars of other
/// shoppers currently at that store.
class ShoppingStoreBar extends StatelessWidget {
  final ShoppingSessionController controller;
  final void Function(int storeId) onJumpToStore;

  const ShoppingStoreBar({
    super.key,
    required this.controller,
    required this.onJumpToStore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activePos = controller.activePosition;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        children: [
          for (final leg in controller.orderedStores)
            Builder(
              builder: (context) {
                final store = controller.stores[leg.storeId];
                final isActive =
                    leg.storeId == controller.session.activeStoreId;
                final isPast = activePos >= 0 && leg.position < activePos;
                final others = controller.presenceAt(leg.storeId);
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Opacity(
                    opacity: isPast ? 0.5 : 1,
                    child: Material(
                      color: isActive
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => onJumpToStore(leg.storeId),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                storeIcon(store?.icon),
                                size: 18,
                                color:
                                    parseHexColor(store?.color) ??
                                    (isActive
                                        ? cs.onPrimaryContainer
                                        : cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                store?.name ?? '',
                                textDirection: detectTextDirection(store?.name),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isActive
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                ),
                              ),
                              if (others.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                ShoppingAvatarStack(
                                  controller: controller,
                                  userIds: others,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Overlapping avatars for up to three shoppers, resolved against the
/// controller's member map. Used on the store pills and wherever a shared trip
/// needs to show who is on it.
class ShoppingAvatarStack extends StatelessWidget {
  final ShoppingSessionController controller;
  final List<String> userIds;

  const ShoppingAvatarStack({
    super.key,
    required this.controller,
    required this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const overlap = 12.0;
    final shown = userIds.take(3).toList();
    return SizedBox(
      width: size + (shown.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            PositionedDirectional(
              start: i * overlap,
              child: Builder(
                builder: (context) {
                  final userId = shown[i];
                  final member = controller.members[userId];
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: MemberAvatar(
                      userId: userId,
                      displayName: member?.displayName ?? userId,
                      size: size,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ShoppingProgressRow extends StatelessWidget {
  final ShoppingSessionController controller;

  const ShoppingProgressRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companions = controller.companions;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Text(
            m.shopping.inCart(controller.inCartCount),
            style: theme.textTheme.labelLarge,
          ),
          // A storeless trip has no store bar to carry the avatars, so the
          // shared-trip signal lives here instead.
          if (companions.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Tooltip(
                message: m.shopping.shoppingWith(companions.length),
                child: ShoppingAvatarStack(
                  controller: controller,
                  userIds: companions,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: controller.progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: Colors.green,
              ),
            ),
          ),
          if (controller.session.isPrivate)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Icon(
                Icons.visibility_off,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class ShoppingItemArea extends StatelessWidget {
  final ShoppingSessionController controller;
  final Future<void> Function(ListItem) onCheck;
  final void Function(ListItem) onSkip;
  final void Function(ListItem) onView;
  final Future<void> Function() onRefresh;

  const ShoppingItemArea({
    super.key,
    required this.controller,
    required this.onCheck,
    required this.onSkip,
    required this.onView,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final groups = controller.groupedItems;
    final headerExtent = _categoryHeaderExtent(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: groups.isEmpty
          // Keep the pull gesture available even with nothing to buy: an empty
          // Center can't scroll, so wrap it so it always overscrolls.
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _EmptyState(controller: controller),
                ),
              ),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                for (final group in groups)
                  // Grouping header + rows pins the header only for as long as
                  // its own items are on screen — the next group pushes it off.
                  SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _CategoryHeaderDelegate(
                          category: group.category,
                          count: group.items.length,
                          extent: headerExtent,
                        ),
                      ),
                      SliverList.builder(
                        itemCount: group.items.length,
                        itemBuilder: (context, index) {
                          final item = group.items[index];
                          return ShoppingItemRow(
                            // Key by item id so the Dismissible tracks the
                            // right row as the list shifts when items above it
                            // are checked or removed.
                            key: ValueKey(item.id),
                            item: item,
                            controller: controller,
                            onCheck: () => onCheck(item),
                            onSkip: () => onSkip(item),
                            onView: () => onView(item),
                          );
                        },
                      ),
                    ],
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
              ],
            ),
    );
  }
}

/// A pinned header needs its height up front, so the text line is measured
/// against the user's text scale rather than assumed. Rounded to a whole
/// pixel: a fractional extent trips the sliver geometry assertions.
double _categoryHeaderExtent(BuildContext context) {
  final style = Theme.of(context).textTheme.labelLarge;
  final line = (style?.fontSize ?? 14) * (style?.height ?? 1.45);
  final scaled = MediaQuery.textScalerOf(context).scale(line);
  return (math.max(scaled, 18) + 12).ceilToDouble();
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Category? category;
  final int count;
  final double extent;

  const _CategoryHeaderDelegate({
    required this.category,
    required this.count,
    required this.extent,
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
    child: _CategoryHeader(category: category, count: count),
  );

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.category != category ||
      oldDelegate.count != count ||
      oldDelegate.extent != extent;
}

class _CategoryHeader extends StatelessWidget {
  final Category? category;
  final int count;

  const _CategoryHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = parseHexColor(category?.color) ?? theme.colorScheme.primary;
    final name = category?.name ?? m.shopping.uncategorized;
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Row(
        children: [
          Icon(categoryIcon(category?.icon), size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              textDirection: detectTextDirection(name),
              style: theme.textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
          Text('$count', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ShoppingSessionController controller;

  const _EmptyState({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNext = controller.session.nextStoreId != null;
    final title = hasNext ? m.shopping.allCheckedHere : m.shopping.allDone;
    final subtitle = hasNext
        ? m.shopping.moveOnToNext
        : m.shopping.everythingInCart;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasNext ? Icons.check_circle_outline : Icons.done_all,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Done-today drawer (collapsible) stacked above the Next-store / Finish
/// action button.
class ShoppingBottomBar extends StatelessWidget {
  final ShoppingSessionController controller;
  final bool doneExpanded;
  final VoidCallback onToggleDone;
  final Future<void> Function(ListItem) onUncheck;
  final bool removedExpanded;
  final VoidCallback onToggleRemoved;
  final Future<void> Function(ListItem) onRestore;
  final bool busy;
  final bool hasNext;
  final VoidCallback onProceed;

  const ShoppingBottomBar({
    super.key,
    required this.controller,
    required this.doneExpanded,
    required this.onToggleDone,
    required this.onUncheck,
    required this.removedExpanded,
    required this.onToggleRemoved,
    required this.onRestore,
    required this.busy,
    required this.hasNext,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneItems = controller.doneItems;
    final doneCount = doneItems.length;
    final estimate = formatShoppingEstimate(controller.doneEstimate);
    final removedItems = controller.removedItems;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (doneCount > 0) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onToggleDone,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      doneExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.shopping.doneToday(doneCount),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (estimate != null)
                      Text(
                        estimate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (doneExpanded)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in doneItems)
                      ListTile(
                        dense: true,
                        onTap: () => onUncheck(item),
                        leading: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        title: Text(
                          item.name,
                          textDirection: detectTextDirection(item.name),
                        ),
                        trailing: item.formattedPrice != null
                            ? Text(item.formattedPrice!)
                            : null,
                      ),
                  ],
                ),
              ),
          ],
          if (removedItems.isNotEmpty) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onToggleRemoved,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      removedExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.shopping.removedSection(removedItems.length),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (removedExpanded)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in removedItems)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.remove_shopping_cart_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        title: Text(
                          item.name,
                          textDirection: detectTextDirection(item.name),
                        ),
                        trailing: TextButton.icon(
                          onPressed: () => onRestore(item),
                          icon: const Icon(Icons.restore, size: 18),
                          label: Text(m.shopping.restore),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onProceed,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(hasNext ? Icons.arrow_forward : Icons.flag),
                label: Text(hasNext ? m.shopping.nextStore : m.shopping.finish),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
