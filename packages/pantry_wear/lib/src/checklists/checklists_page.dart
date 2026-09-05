import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_chip.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_metrics.dart';
import 'checklists_controller.dart';
import 'item_detail_page.dart';

/// The checklists page, in both shells.
///
/// Tap the centred card to check it; tapping an off-centre card scrolls it to
/// the centre instead, so a mis-aim costs a scroll rather than a write.
/// Long-press the centred card for the read-only detail.
///
/// A check does not leave immediately: the card stays put with a stroke
/// running down its border, and a second tap inside that window takes it back.
/// Only when the stroke runs out is the write queued — to the completed
/// section in browse, or off to the done page in a session.
class ChecklistsPage extends StatefulWidget {
  final ChecklistsController controller;
  final ValueNotifier<FocusGeometry> geometry;

  /// Only the page being looked at may steer from the crown.
  final bool active;

  const ChecklistsPage({
    super.key,
    required this.controller,
    required this.geometry,
    required this.active,
  });

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage>
    with TickerProviderStateMixin {
  final _listKey = GlobalKey<SnapFocusListState>();
  late ScrollController _controller;

  /// Checks that have fired but not yet run out their undo window, keyed by
  /// item id. The controller drives the border stroke and the clock.
  final _pending = <int, AnimationController>{};

  var _doneCollapsed = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    widget.controller.addListener(_onData);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onData);
    for (final window in _pending.values) {
      window.dispose();
    }

    _controller.dispose();
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  /// Resolve every open undo window at once. The mode transition calls this
  /// before the pager swaps, so nothing is left half-committed against a page
  /// set that no longer exists.
  void resolvePending({required bool commit}) {
    for (final entry in _pending.entries.toList()) {
      entry.value.stop();
      entry.value.dispose();
      if (commit) _write(_itemById(entry.key), true);
    }
    _pending.clear();
    if (mounted) setState(() {});
  }

  ListItem? _itemById(int id) {
    for (final item in widget.controller.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _tapCentred(ListItem item) {
    final open = _pending[item.id];
    if (open != null) {
      // Second tap inside the window takes it back. Nothing was ever written.
      open.stop();
      open.dispose();
      setState(() => _pending.remove(item.id));
      return;
    }
    if (item.done) {
      _write(item, false);
      return;
    }
    final window = AnimationController(
      vsync: this,
      duration: WearMetrics.undoWindow,
    );
    window.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      window.dispose();
      if (!mounted) return;
      setState(() => _pending.remove(item.id));
      _write(item, true);
    });
    setState(() => _pending[item.id] = window);
    window.forward();
  }

  void _write(ListItem? item, bool done) {
    if (item == null) return;
    final controller = widget.controller;
    if (controller.mode == ChecklistMode.session) {
      done ? controller.checkItem(item) : controller.uncheckItem(item);
      return;
    }
    controller.setDone(item, done);
  }

  Future<void> _openDetail(ListItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ItemDetailPage(item: item, controller: widget.controller),
      ),
    );
  }

  void _onCardTap(ListItem item, int index) {
    if (_scrollTo(index)) return;
    _tapCentred(item);
  }

  void _onCardLongPress(ListItem item, int index) {
    if (_scrollTo(index)) return;
    unawaited(_openDetail(item));
  }

  /// Brings an off-centre card to the centre line and reports that it did, so
  /// the gesture stops there rather than acting on a row the wearer was only
  /// aiming at.
  ///
  /// The row's own index, not its item's: grouping by store repeats an item in
  /// every store it belongs to, so an id names several rows.
  bool _scrollTo(int index) {
    if (index == widget.geometry.value.centredIndex) return false;
    _listKey.currentState?.centreOn(index);
    return true;
  }

  // -- Building the list -----------------------------------------------------

  /// Ordered groups, then the elements the list draws. Headers are short and
  /// unsnappable; the falloff leaves them alone.
  List<FocusElement> _elements() {
    final controller = widget.controller;
    final elements = <FocusElement>[];

    void addItems(
      List<ListItem> items, {
      required String? group,
      IconData? icon,
      Color? color,
    }) {
      for (final item in items) {
        final index = elements.length;
        elements.add(
          FocusElement(
            extent: WearMetrics.itemExtent,
            groupLabel: group,
            groupIcon: icon,
            groupColor: color,
            builder: (context, d) => _ItemCard(
              item: item,
              d: d,
              controller: controller,
              pending: _pending[item.id],
              onTap: () => _onCardTap(item, index),
              onLongPress: () => _onCardLongPress(item, index),
            ),
          ),
        );
      }
    }

    void addHeader(
      String label, {
      IconData? icon,
      Color? color,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      elements.add(
        FocusElement(
          extent: WearMetrics.headerExtent,
          snappable: false,
          isHeader: true,
          groupLabel: label,
          builder: (context, _) => _GroupHeader(
            label: label,
            icon: icon,
            color: color,
            trailing: trailing,
            onTap: onTap,
          ),
        ),
      );
    }

    for (final group in _groups(controller.items, controller)) {
      addHeader(group.label, icon: group.icon, color: group.color);
      addItems(
        group.items,
        group: group.label,
        icon: group.icon,
        color: group.color,
      );
    }

    // Browse keeps the phone's collapsible completed section. A session has a
    // whole page for it instead, so nothing is appended here.
    if (controller.mode == ChecklistMode.browse && controller.done.isNotEmpty) {
      final label = m.checklists.completedCount(controller.done.length);
      addHeader(
        label,
        icon: Icons.check_circle_outline,
        trailing: Icon(
          _doneCollapsed ? Icons.expand_more : Icons.expand_less,
          size: 14,
          color: Colors.white38,
        ),
        onTap: () => setState(() => _doneCollapsed = !_doneCollapsed),
      );
      if (!_doneCollapsed) {
        addItems(
          controller.done,
          group: label,
          icon: Icons.check_circle_outline,
          color: Colors.white54,
        );
      }
    }

    return elements;
  }

  /// Items bucketed by category, categories in their own sort order and
  /// uncategorised last — the phone's grouping, with the header carrying the
  /// category's icon and colour.
  List<_Group> _groups(List<ListItem> items, ChecklistsController controller) =>
      controller.grouping == ChecklistGrouping.store
      ? _storeGroups(items, controller)
      : _categoryGroups(items, controller);

  /// Categories in the house's own order, uncategorised last, each item in
  /// exactly one bucket.
  List<_Group> _categoryGroups(
    List<ListItem> items,
    ChecklistsController controller,
  ) {
    final buckets = <int?, List<ListItem>>{};
    for (final item in items) {
      buckets.putIfAbsent(item.categoryId, () => []).add(item);
    }
    final groups = <_Group>[];
    for (final category in controller.sortedCategories) {
      final bucket = buckets.remove(category.id);
      if (bucket == null) continue;
      groups.add(
        _Group(
          label: category.name,
          icon: categoryIcon(category.icon),
          color: parseHexColor(category.color) ?? Colors.white54,
          items: bucket..sort(_byOrder),
        ),
      );
    }
    // Whatever is left names a category this house no longer has, which reads
    // the same way to a wearer as having none.
    final uncategorised = [for (final bucket in buckets.values) ...bucket];
    if (uncategorised.isNotEmpty) {
      groups.add(
        _Group(
          label: m.checklists.filters.noCategory,
          icon: defaultCategoryIcon,
          color: Colors.white54,
          items: uncategorised..sort(_byOrder),
        ),
      );
    }
    return groups;
  }

  /// Stores in the house's own order, unassigned last. An item belonging to
  /// several stores appears under **each** of them — the phone's rule, and the
  /// only one that answers "what do I pick up here" at every stop.
  List<_Group> _storeGroups(
    List<ListItem> items,
    ChecklistsController controller,
  ) {
    final stores = controller.sortedStores;
    final known = {for (final s in stores) s.id};
    final groups = <_Group>[];
    for (final store in stores) {
      final bucket = [
        for (final item in items)
          if (item.storeIds.contains(store.id)) item,
      ]..sort(_byOrder);
      if (bucket.isEmpty) continue;
      groups.add(
        _Group(
          label: store.name,
          icon: storeIcon(store.icon),
          color: parseHexColor(store.color) ?? Colors.white54,
          items: bucket,
        ),
      );
    }
    final unassigned = [
      for (final item in items)
        if (!item.storeIds.any(known.contains)) item,
    ]..sort(_byOrder);
    if (unassigned.isNotEmpty) {
      groups.add(
        _Group(
          label: m.checklists.noStore,
          icon: EntityIcons.store,
          color: Colors.white54,
          items: unassigned,
        ),
      );
    }
    return groups;
  }

  int _byOrder(ListItem a, ListItem b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  /// Nothing to draw has three causes, and only one of them is an empty list.
  String _emptyMessage(ChecklistsController controller) {
    if (!AuthService.instance.isLoggedIn) return m.wear.notSignedIn;
    if (controller.hasNoScope) return m.wear.noLists;
    return controller.mode == ChecklistMode.session
        ? m.shopping.nothingToBuyHere
        : m.checklists.noItems;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.items.isEmpty &&
        (controller.mode == ChecklistMode.session || controller.done.isEmpty)) {
      return _Empty(message: _emptyMessage(controller));
    }
    return SnapFocusList(
      key: _listKey,
      controller: _controller,
      elements: _elements(),
      itemExtent: WearMetrics.itemExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.active,
      horizontalInset: WearMetrics.sideInset,
      geometry: widget.geometry,
    );
  }
}

class _Group {
  final String label;
  final IconData icon;
  final Color color;
  final List<ListItem> items;

  const _Group({
    required this.label,
    required this.icon,
    required this.color,
    required this.items,
  });
}

/// A group header, in the phone's language: the category icon and name in that
/// category's colour, over a hairline rule. Short, unfocusable, and it scrolls
/// like anything else — the rail picks the label up when it slides under.
class _GroupHeader extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _GroupHeader({
    required this.label,
    this.icon,
    this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white54;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: tint.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: tint),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: detectTextDirection(label),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                    color: tint,
                  ),
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ListItem item;
  final double d;
  final ChecklistsController controller;
  final AnimationController? pending;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ItemCard({
    required this.item,
    required this.d,
    required this.controller,
    required this.pending,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A pending check reads as done straight away: the write is the thing
    // being delayed, not the feedback.
    final checked = item.done || pending != null;

    // The centre card is the only one that can afford a second line: every
    // other card is already scaled below 1 and leaving slack inside its
    // extent, so nothing has to grow for this to fit.
    final expansion = (1 - (d / 0.4)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(expansion);

    // A round screen wants a round row: at the corners of a card the glass is
    // already curving away, so a pill follows the bezel instead of fighting
    // it. A square watch keeps the rectangle it shares an edge with.
    final radius = WearShape.isRound ? WearMetrics.cardHeight / 2 : 14.0;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(
          scheme.surfaceContainerHighest,
          const Color(0xFF121215),
          d,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        // Tight enough that the centre card's second line still fits inside
        // the row extent: the expansion has to come out of slack the card
        // already has, or the fixed extent turns it into a gap.
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: WearShape.isRound ? 15 : 11,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  checked ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: checked ? scheme.primary : Colors.white38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(item.name),
                    style: TextStyle(
                      fontSize: 15,
                      // Pinned rather than left to the font's own metrics: the
                      // card has to fit inside a fixed row extent, and an
                      // unpinned line height is the difference between fitting
                      // and the striped overflow banner.
                      height: 1.1,
                      // Weight is the one thing the scale cannot carry: a
                      // scaled regular is still a regular.
                      fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                      color: checked ? Colors.white38 : Colors.white,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (item.quantity != null && expansion < 0.5)
                  Text(
                    item.quantity!,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
              ],
            ),
            if (expansion > 0)
              // The slot and the content shrink by the *same* factor, so the
              // chips zoom away rather than being sliced off by the edge of a
              // collapsing box.
              Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: eased,
                child: Transform.scale(
                  scale: eased,
                  alignment: AlignmentDirectional.topStart.resolve(
                    Directionality.of(context),
                  ),
                  child: Opacity(
                    opacity: eased,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: 3),
                      child: _MetaLine(item: item, controller: controller),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Center(
        // Fixed, not content-sized: a card that shrinks to its one line leaves
        // the difference as dead space inside its row rather than closing the
        // list up, so every card claims its extent less the gap.
        child: SizedBox(
          height: WearMetrics.cardHeight,
          child: pending == null
              ? card
              : AnimatedBuilder(
                  animation: pending!,
                  builder: (context, child) => CustomPaint(
                    foregroundPainter: _UndoStrokePainter(
                      // Counts down, so the ring draining is the window
                      // draining.
                      remaining: 1 - pending!.value,
                      color: scheme.primary,
                      radius: radius,
                    ),
                    child: child,
                  ),
                  child: card,
                ),
        ),
      ),
    );
  }
}

/// The second line the centre card earns.
///
/// Chips are filtered by `hiddenItemChips`, which the phone seeds once at
/// pairing and never overrides — and by what the grouping already says:
/// whichever chip names the current grouping repeats its own header, so it is
/// the one chip that never draws.
class _MetaLine extends StatelessWidget {
  final ListItem item;
  final ChecklistsController controller;

  const _MetaLine({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    const neutral = Color(0xFFB6B6BE);
    final prefs = PrefsService.instance;
    final grouping = controller.grouping;
    final parts = <Widget>[];

    void chip(ItemChipKind kind, Widget child) {
      if (!prefs.isItemChipVisible(kind.key)) return;
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 5));
      parts.add(child);
    }

    final category = controller.categoryOf(item);
    if (grouping != ChecklistGrouping.category && category != null) {
      final tint = parseHexColor(category.color) ?? neutral;
      chip(
        ItemChipKind.category,
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: category.name,
          leading: Icon(categoryIcon(category.icon), size: 9, color: tint),
        ),
      );
    }

    final store = controller.storeOf(item);
    if (grouping != ChecklistGrouping.store && store != null) {
      final tint = parseHexColor(store.color) ?? neutral;
      chip(
        ItemChipKind.store,
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: store.name,
          leading: Icon(storeIcon(store.icon), size: 9, color: tint),
        ),
      );
    }
    if (item.quantity != null) {
      chip(
        ItemChipKind.quantity,
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: item.quantity!,
        ),
      );
    }
    final resolved = resolveItemPrice(
      item.prices,
      controller.session?.activeStoreId,
    );
    final price = resolved == null
        ? null
        : formatPrice(
            priceType: resolved.priceType,
            priceMin: resolved.priceMin,
            priceMax: resolved.priceMax,
            priceCurrency: resolved.priceCurrency,
          );
    if (price != null) {
      chip(
        ItemChipKind.price,
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: price,
        ),
      );
    }
    if ((item.description ?? '').isNotEmpty) {
      chip(
        ItemChipKind.note,
        const EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          leading: Icon(Icons.sticky_note_2_outlined, size: 9, color: neutral),
        ),
      );
    }
    if (item.rrule != null) {
      chip(
        ItemChipKind.recurring,
        const EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          leading: Icon(Icons.repeat, size: 9, color: neutral),
        ),
      );
    }

    return SizedBox(
      height: 16,
      // Never scrolled — it is here so a row of chips wider than the card
      // clips at the edge instead of raising an overflow.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(mainAxisSize: MainAxisSize.min, children: parts),
      ),
    );
  }
}

/// The undo window, drawn as a stroke running down the card's own border. The
/// card already has this edge; nothing new is introduced to carry the clock.
class _UndoStrokePainter extends CustomPainter {
  final double remaining;
  final Color color;
  final double radius;

  const _UndoStrokePainter({
    required this.remaining,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (remaining <= 0) return;
    // A pill radius is quoted against the row extent, but the card is shorter
    // than its extent — an unclamped radius here draws a malformed path rather
    // than being scaled down the way a BorderRadius would be.
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius.clamp(0.0, size.shortestSide / 2)),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * remaining.clamp(0.0, 1.0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_UndoStrokePainter old) =>
      old.remaining != remaining || old.color != color || old.radius != radius;
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: detectTextDirection(message),
        style: const TextStyle(fontSize: 12, color: Colors.white38),
      ),
    ),
  );
}
