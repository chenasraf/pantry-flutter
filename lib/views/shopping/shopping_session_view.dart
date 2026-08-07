import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/shopping_estimate.dart';
import 'package:pantry/models/shopping_presence_entry.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/shopping/shopping_reminders_view.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/member_avatar.dart';

/// The live, dense shopping screen. Owns the ~1-min poll (items + heartbeat +
/// done-today), paused while the app is backgrounded and fired on resume.
class ShoppingSessionView extends StatefulWidget {
  final ShoppingSession session;

  const ShoppingSessionView({super.key, required this.session});

  @override
  State<ShoppingSessionView> createState() => _ShoppingSessionViewState();
}

class _ShoppingSessionViewState extends State<ShoppingSessionView> {
  late final _controller = ShoppingSessionController(session: widget.session);

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
      child: const _SessionBody(),
    );
  }
}

class _SessionBody extends StatefulWidget {
  const _SessionBody();

  @override
  State<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends State<_SessionBody>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 60);
  Timer? _timer;
  bool _doneExpanded = false;
  bool _busy = false;

  ShoppingSessionController get _c => context.read<ShoppingSessionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _c.poll());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _c.poll();
        _startTimer();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stopTimer();
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _check(ListItem item) async {
    try {
      await _c.checkItem(item);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.shopping.checkFailed)));
    }
  }

  /// Swipe removed [item] from this trip. Optimistic + queued (survives
  /// offline); an Undo toast unskips it.
  void _skip(ListItem item) {
    _c.skipItem(item);
    showUndoSnackBar(
      message: m.shopping.removedFromTrip,
      undoLabel: m.shopping.undo,
      onUndo: () => _c.unskipItem(item.id),
      undoFailedMessage: m.shopping.undoRemoveFailed,
    );
  }

  Future<void> _jumpToStore(int storeId) async {
    if (storeId == _c.session.activeStoreId) return;
    try {
      await _c.advance(storeId);
    } catch (_) {
      /* poll will reconcile */
    }
  }

  Future<void> _togglePrivacy() async {
    try {
      await _c.setPrivacy(!_c.session.isPrivate);
    } catch (_) {
      /* reverted in controller */
    }
  }

  Future<void> _openReminders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingRemindersView(houseId: _c.houseId),
      ),
    );
  }

  /// FAB action: review the current store, then advance to the next store or
  /// finish the trip.
  Future<void> _reviewAndProceed() async {
    if (_busy) return;
    final controller = _c;
    final session = controller.session;
    final nextStoreId = session.nextStoreId;
    final isAdvance = nextStoreId != null;
    final mode = isAdvance
        ? ShoppingReviewMode.advance
        : ShoppingReviewMode.close;
    final moment = isAdvance
        ? ShoppingReminderMoment.onStoreAdvance
        : ShoppingReminderMoment.onClose;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShoppingReviewView(
          houseId: controller.houseId,
          sessionId: controller.sessionId,
          mode: mode,
          activeStoreId: session.activeStoreId,
          stores: controller.stores,
          reminders: controller.remindersFor(moment),
          onManageReminders: _openReminders,
        ),
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      // Billed edits may have landed — refresh the session DTO.
      await controller.refreshSession();
      return;
    }

    setState(() => _busy = true);
    try {
      if (isAdvance) {
        await controller.advance(nextStoreId);
      } else {
        await controller.close();
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.shopping.loadFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShoppingSessionController>();
    final session = controller.session;
    final activeStore = session.activeStoreId != null
        ? controller.stores[session.activeStoreId]
        : null;
    final hasNext = session.nextStoreId != null;

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(activeStore?.name ?? m.shopping.startTitle),
        actions: [
          IconButton(
            icon: Icon(
              session.isPrivate ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: session.isPrivate
                ? m.shopping.makePublic
                : m.shopping.makePrivate,
            onPressed: _togglePrivacy,
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (session.stores.isNotEmpty)
                  _StoreBar(controller: controller),
                _ProgressRow(controller: controller),
                Expanded(
                  child: _ItemArea(
                    controller: controller,
                    onCheck: _check,
                    onSkip: _skip,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: controller.isLoading
          ? null
          : _BottomBar(
              controller: controller,
              doneExpanded: _doneExpanded,
              onToggleDone: () =>
                  setState(() => _doneExpanded = !_doneExpanded),
              busy: _busy,
              hasNext: hasNext,
              onProceed: _reviewAndProceed,
            ),
    );
  }
}

/// Horizontal, scrollable row of store pills. The active pill is filled; past
/// pills (lower position) are dimmed. Each pill carries the avatars of other
/// shoppers currently at that store.
class _StoreBar extends StatelessWidget {
  final ShoppingSessionController controller;

  const _StoreBar({required this.controller});

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
                        onTap: () =>
                            (context
                                    .findAncestorStateOfType<
                                      _SessionBodyState
                                    >())
                                ?._jumpToStore(leg.storeId),
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
                                _AvatarStack(
                                  controller: controller,
                                  entries: others,
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

class _AvatarStack extends StatelessWidget {
  final ShoppingSessionController controller;
  final List<ShoppingPresenceEntry> entries;

  const _AvatarStack({required this.controller, required this.entries});

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const overlap = 12.0;
    final shown = entries.take(3).toList();
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
                  final userId = shown[i].userId;
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

class _ProgressRow extends StatelessWidget {
  final ShoppingSessionController controller;

  const _ProgressRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

class _ItemArea extends StatelessWidget {
  final ShoppingSessionController controller;
  final Future<void> Function(ListItem) onCheck;
  final void Function(ListItem) onSkip;

  const _ItemArea({
    required this.controller,
    required this.onCheck,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final groups = controller.groupedItems;
    if (groups.isEmpty) return _EmptyState(controller: controller);

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final group in groups) ...[
          _CategoryHeader(category: group.category, count: group.items.length),
          for (final item in group.items)
            _ShoppingItemRow(
              // Key by item id so the Dismissible tracks the right row as the
              // list shifts when items above it are checked or removed.
              key: ValueKey(item.id),
              item: item,
              onCheck: () => onCheck(item),
              onSkip: () => onSkip(item),
            ),
        ],
      ],
    );
  }
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

/// A single to-buy row. Tapping anywhere on the row checks the item off;
/// swiping it aside removes it from this trip only (see [onSkip]).
class _ShoppingItemRow extends StatelessWidget {
  final ListItem item;
  final VoidCallback onCheck;
  final VoidCallback onSkip;

  const _ShoppingItemRow({
    super.key,
    required this.item,
    required this.onCheck,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = item.formattedPrice;
    return Dismissible(
      key: ValueKey('skip-${item.id}'),
      // End-to-start (trailing → leading) keeps the "swipe it away" gesture
      // distinct from the whole-row tap and is direction-aware for RTL.
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onSkip(),
      background: _skipBackground(theme),
      child: InkWell(
        onTap: onCheck,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle_outlined,
                size: 22,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      textDirection: detectTextDirection(item.name),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (item.quantity != null &&
                        item.quantity!.trim().isNotEmpty)
                      Text(
                        item.quantity!,
                        textDirection: detectTextDirection(item.quantity),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (price != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    price,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skipBackground(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.shopping.removeFromTrip,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.remove_shopping_cart_outlined, color: cs.onSurfaceVariant),
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
class _BottomBar extends StatelessWidget {
  final ShoppingSessionController controller;
  final bool doneExpanded;
  final VoidCallback onToggleDone;
  final bool busy;
  final bool hasNext;
  final VoidCallback onProceed;

  const _BottomBar({
    required this.controller,
    required this.doneExpanded,
    required this.onToggleDone,
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
