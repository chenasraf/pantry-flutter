import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/focus_list.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'checklists_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
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
    if (mounted) setState(() {});
  }

  /// Resolve every open undo window at once. The mode transition calls this
  /// before the pager swaps, so nothing is left half-committed against a page
  /// set that no longer exists.
  void resolvePending({required bool commit}) =>
      _pending.resolveAll(commit: commit);

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
            builder: (context, d) => ItemCard(
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
      itemExtent: WearMetrics.of(context).itemExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.rotary,
      horizontalInset: WearMetrics.sideInset,
      geometry: widget.geometry,
      underRail: true,
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
