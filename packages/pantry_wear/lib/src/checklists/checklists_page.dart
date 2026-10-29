import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/focus_list.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_empty.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'checklists_controller.dart';
import 'inventory_card.dart';
import 'item_card.dart';
import 'item_detail_page.dart';

/// The checklists page, in both shells.
///
/// Tap a card to check it. On a round screen that means the centred card, and
/// tapping any other scrolls it to the centre instead, so a mis-aim costs a
/// scroll rather than a write; on a square screen, where no row is in charge,
/// any card the wearer can see all of acts where it lies. Long-press is the
/// read-only detail, under the same rule.
///
/// Neither direction leaves immediately: the card stays put with a stroke
/// running down its border, and a second tap inside that window takes it back.
/// Only when the stroke runs out is the write queued — to the completed
/// section in browse, or off to the done page in a session. Unchecking earns
/// the same window as checking, since it is the one of the two that undoes
/// work already done.
///
/// An inventory's rows adjust stock instead (see [InventoryCard]): a tap opens
/// the row's controls, and closing it — its ✓, or scrolling it away — queues
/// the net change behind the same window.
class ChecklistsPage extends StatefulWidget {
  final ChecklistsController controller;
  final ValueNotifier<FocusGeometry> geometry;

  /// Whether the crown is this list's to steer: only the page being looked at
  /// may read it, and only while turning it scrolls rather than turns pages.
  final bool rotary;

  const ChecklistsPage({
    super.key,
    required this.controller,
    required this.geometry,
    required this.rotary,
  });

  @override
  ChecklistsPageState createState() => ChecklistsPageState();
}

class ChecklistsPageState extends State<ChecklistsPage>
    with TickerProviderStateMixin {
  final _listKey = GlobalKey<SnapFocusListState>();
  late ScrollController _controller;

  /// Taps that have fired but not yet run out their undo window, keyed by item
  /// id.
  late final UndoWindows<int> _pending;

  var _doneCollapsed = true;

  /// The inventory row whose controls are swapped in, and where the list was
  /// scrolled to when it opened — scrolling it away is one of the ways it
  /// closes.
  int? _openId;
  double _openOffset = 0;

  /// What each closed row's undo window would write, and what it says.
  final _stockChanges = <int, StockChange>{};

  /// Only the rows that need restock, in the same groups.
  var _restockOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    _pending = UndoWindows(
      vsync: this,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    widget.controller.addListener(_onData);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onData);
    _pending.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onData() {
    if (!mounted) return;
    // The row was taken out from under its controls — scope moved, or the
    // item went away. What the wearer stepped to still stands.
    final open = _openId;
    if (open != null && !widget.controller.items.any((i) => i.id == open)) {
      closeStock(window: false);
    }
    setState(() {});
  }

  /// Resolve every open undo window at once. The mode transition calls this
  /// before the pager swaps, so nothing is left half-committed against a page
  /// set that no longer exists.
  void resolvePending({required bool commit}) {
    final open = _openId;
    if (open != null) {
      _openId = null;
      final change = widget.controller.closeStock(open);
      if (change != null) {
        commit
            ? widget.controller.commitStock(change)
            : widget.controller.revertStock(change);
      }
    }
    _pending.resolveAll(commit: commit);
    if (!commit) {
      for (final change in _stockChanges.values) {
        widget.controller.revertStock(change);
      }
    }
    _stockChanges.clear();
  }

  // -- Adjusting stock -------------------------------------------------------

  /// Close the open row and queue what it changed. Behind the undo window,
  /// unless the app is going away: a paused process may never come back to
  /// finish draining it.
  void closeStock({bool window = true}) {
    final id = _openId;
    if (id == null) return;
    if (mounted) setState(() => _openId = null);
    final controller = widget.controller;
    final change = controller.closeStock(id);
    if (change == null) return;
    if (!window) return controller.commitStock(change);
    _stockChanges[id] = change;
    _pending.fire(
      id,
      target: true,
      commit: (_) {
        _stockChanges.remove(id);
        controller.commitStock(change);
      },
    );
  }

  void _openStock(ListItem item) {
    closeStock();
    setState(() {
      _openId = item.id;
      _openOffset = _controller.hasClients ? _controller.offset : 0;
    });
  }

  /// A tap inside the window takes the change back, and nothing is written.
  void _undoStock(int id) {
    _pending.fire(id, target: true, commit: (_) {});
    final change = _stockChanges.remove(id);
    if (change != null) widget.controller.revertStock(change);
  }

  /// The crown turns the list through the same scroll, so this is also how
  /// turning it closes a row.
  void _onScroll() {
    if (_openId == null || !_controller.hasClients) return;
    final moved = (_controller.offset - _openOffset).abs();
    if (moved <= WearMetrics.of(context).itemExtent / 2) return;
    // Scroll positions move during layout as well as on input, and closing
    // rebuilds the list.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) closeStock();
      });
      return;
    }
    closeStock();
  }

  void _onInventoryTap(ListItem item, int index) {
    if (_scrollTo(index)) return;
    if (_pending.targetOf(item.id) != null) return _undoStock(item.id);
    if (_openId == item.id) return;
    _openStock(item);
  }

  void _onInventoryLongPress(ListItem item, int index) {
    if (_scrollTo(index)) return;
    closeStock();
    unawaited(_openDetail(item));
  }

  /// The item a row's window is holding, as the controller now has it.
  ///
  /// Both collections, because both are drawn: an uncheck is fired from the
  /// completed section, where the item is precisely the one [items] does not
  /// hold.
  ListItem? _itemById(int id) {
    for (final item in [
      ...widget.controller.items,
      ...widget.controller.done,
    ]) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _tapCentred(ListItem item) => _pending.fire(
    item.id,
    target: !item.done,
    // Resolved again at commit rather than captured: a snapshot landing while
    // the stroke drains replaces the item this tap was aimed at.
    commit: (done) => _write(_itemById(item.id), done),
  );

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
      wearRoute<void>(
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

  /// The rows the filter lets through. A row being adjusted, or waiting out
  /// its window, stays put even once it no longer needs restock, so it is not
  /// pulled out from under the wearer's finger.
  List<ListItem> _visibleItems() {
    final items = widget.controller.items;
    if (!widget.controller.isInventory || !_restockOnly) return items;
    return [
      for (final item in items)
        if (item.needsStockRestock ||
            item.id == _openId ||
            _pending.targetOf(item.id) != null)
          item,
    ];
  }

  /// Brings a card the wearer was only aiming at within reach and reports that
  /// it did, so the gesture stops there rather than acting on it. What counts
  /// as aimed at is the list's to say — see `SnapFocusListState.canActOn`.
  ///
  /// The row's own index, not its item's: grouping by store repeats an item in
  /// every store it belongs to, so an id names several rows.
  bool _scrollTo(int index) {
    final list = _listKey.currentState;
    if (list != null && list.canActOn(index)) return false;
    list?.reveal(index);
    return true;
  }

  // -- Building the list -----------------------------------------------------

  /// Ordered groups, then the elements the list draws. Headers are short and
  /// unsnappable; the falloff leaves them alone.
  List<FocusElement> _elements() {
    final controller = widget.controller;
    final metrics = WearMetrics.of(context);
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
            extent: metrics.itemExtent,
            groupLabel: group,
            groupIcon: icon,
            groupColor: color,
            builder: (context, d) => controller.isInventory
                ? InventoryCard(
                    item: item,
                    d: d,
                    controller: controller,
                    open: _openId == item.id,
                    pending: _pending.controllerOf(item.id),
                    pendingLabel: _stockChanges[item.id]?.label,
                    onTap: () => _onInventoryTap(item, index),
                    onLongPress: () => _onInventoryLongPress(item, index),
                    onSetOnHand: (q) => controller.stepStock(item, quantity: q),
                    onSetLevel: (l) => controller.stepStock(item, level: l),
                    onClose: closeStock,
                  )
                : ItemCard(
                    item: item,
                    d: d,
                    controller: controller,
                    marked: _pending.targetOf(item.id) ?? item.done,
                    pending: _pending.controllerOf(item.id),
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
          extent: metrics.headerExtent,
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

    if (controller.isInventory) {
      elements.add(
        FocusElement(
          extent: metrics.headerExtent + metrics.cardGap,
          snappable: false,
          isHeader: true,
          builder: (context, _) => _RestockToggle(
            on: _restockOnly,
            onTap: () => setState(() => _restockOnly = !_restockOnly),
          ),
        ),
      );
    }

    final visible = _visibleItems();
    if (controller.isInventory && visible.isEmpty) {
      elements.add(
        FocusElement(
          extent: metrics.noticeExtent,
          snappable: false,
          isHeader: true,
          builder: (context, _) => _Notice(m.wear.nothingNeedsRestock),
        ),
      );
    }

    for (final group in _groups(visible, controller)) {
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
      // Everything ticked off leaves the completed section as the only thing
      // on the page, which reads as a list of work outstanding until it is
      // opened. Saying so above it is what tells the two apart at a glance.
      if (controller.items.isEmpty) {
        elements.add(
          FocusElement(
            extent: metrics.noticeExtent,
            snappable: false,
            isHeader: true,
            builder: (context, _) => _Notice(m.checklists.allDone),
          ),
        );
      }
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

  /// Nothing to draw has four causes, and only one of them is an empty list.
  ///
  /// A session's checked rows live on a page of their own, so a shop the
  /// wearer cleared leaves nothing here either — and that is the opposite of
  /// arriving at a shop with nothing on its list. A shop whose rows were all
  /// passed over instead has nothing to buy in it, which is what it says.
  String _emptyMessage(ChecklistsController controller) {
    if (!AuthService.instance.isLoggedIn) return m.wear.notSignedIn;
    if (controller.hasNoScope) return m.wear.noLists;
    if (controller.mode != ChecklistMode.session) return m.checklists.noItems;
    return controller.done.isEmpty
        ? m.shopping.nothingToBuyHere
        : m.shopping.allCheckedHere;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.items.isEmpty &&
        (controller.mode == ChecklistMode.session || controller.done.isEmpty)) {
      return WearEmpty(message: _emptyMessage(controller));
    }
    final list = SnapFocusList(
      key: _listKey,
      controller: _controller,
      elements: _elements(),
      itemExtent: WearMetrics.of(context).itemExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.rotary,
      horizontalInset: WearMetrics.sideInset,
      geometry: widget.geometry,
      underRail: true,
    );
    if (!controller.isInventory) return list;
    final open = _openItem();
    return Stack(
      children: [
        Positioned.fill(child: list),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: RenewDrawer(
            date: open == null || controller.renewTaken(open)
                ? null
                : controller.renewOfferFor(open),
            onTap: () {
              if (open == null) return;
              // Renewing is the end of a restock, so it closes the row too.
              controller.takeRenew(open);
              closeStock();
            },
          ),
        ),
      ],
    );
  }

  ListItem? _openItem() {
    final id = _openId;
    if (id == null) return null;
    for (final item in widget.controller.items) {
      if (item.id == id) return item;
    }
    return null;
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

/// Something the list has to say where its rows were: a checklist cleared, or
/// a filter that let nothing through.
///
/// A row of the list rather than a page of its own: the completed section, or
/// the filter that would bring the rows back, is still on the page.
class _Notice extends StatelessWidget {
  final String message;

  const _Notice(this.message);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: detectTextDirection(message),
        style: const TextStyle(
          fontSize: 13,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: Colors.white60,
        ),
      ),
    ),
  );
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

/// The Needs restock filter, at the top of an inventory. It only filters:
/// rows keep their category groups either way.
class _RestockToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;

  const _RestockToggle({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = m.stock.filterNeedsRestock;
    return Center(
      child: Semantics(
        button: true,
        toggled: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: on ? scheme.primary : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.check : Icons.filter_list,
                  size: 12,
                  color: on ? scheme.onPrimary : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  textDirection: detectTextDirection(label),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: on ? scheme.onPrimary : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
