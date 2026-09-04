import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'focus_list.dart';
import 'proto_mechanics.dart';
import 'proto_checklist_data.dart';
import 'proto_tuning.dart';

/// PROTOTYPE — the checklists page.
///
/// Tap the centred card to check it; tapping an off-centre card scrolls it to
/// the centre instead, so a mis-aim costs a scroll rather than a write.
/// Long-press the centred card for the read-only detail.
///
/// A check does not leave immediately: the card stays put with a stroke
/// running down its border, and a second tap inside that window takes it back.
/// Only when the stroke runs out does the row go — to the `Done` section in
/// browse mode, or off to the done page in a session.

enum ChecklistMode { browse, session }

/// How the list is grouped. A session never groups by store, because the store
/// it is standing in is named in the rail.
enum GroupBy { category, store, none }

class ChecklistPage extends StatefulWidget {
  final ProtoTuning tuning;
  final ChecklistMode mode;

  /// Items to draw, already filtered by the harness. In browse mode this is
  /// everything; in a session it is what is still to buy.
  final List<ProtoChecklistItem> items;

  /// Browse mode only — the collapsible `Done (n)` section at the bottom.
  final List<ProtoChecklistItem> doneItems;

  final ValueNotifier<FocusGeometry> geometry;
  final bool active;

  /// Fired when a check survives its undo window.
  final void Function(int id, bool done) onCommit;
  final void Function(int id) onSkip;

  const ChecklistPage({
    super.key,
    required this.tuning,
    required this.mode,
    required this.items,
    required this.doneItems,
    required this.geometry,
    required this.active,
    required this.onCommit,
    required this.onSkip,
  });

  @override
  ChecklistPageState createState() => ChecklistPageState();
}

class ChecklistPageState extends State<ChecklistPage>
    with TickerProviderStateMixin {
  final _listKey = GlobalKey<SnapFocusListState>();
  late ScrollController _controller;

  /// Checks that have fired but not yet run out their undo window, keyed by
  /// item id. The controller drives the border stroke and the timer.
  final _pending = <int, AnimationController>{};

  var _doneCollapsed = true;

  /// [ProtoTuning] is one mutable object shared with the harness, so the two
  /// widget configurations either side of a rebuild carry the *same* instance
  /// and comparing `oldWidget.tuning` against `widget.tuning` can never see a
  /// change. The last value has to be held here instead.
  late bool _useWheel;

  @override
  void initState() {
    super.initState();
    _useWheel = widget.tuning.useWheel;
    _controller = _useWheel
        ? FixedExtentScrollController()
        : ScrollController();
  }

  @override
  void didUpdateWidget(ChecklistPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between the sliver list and the wheel swaps the controller
    // type the list needs, so it cannot be reused across the toggle.
    if (widget.tuning.useWheel != _useWheel) {
      _useWheel = widget.tuning.useWheel;
      final previous = _controller;
      _controller = _useWheel
          ? FixedExtentScrollController()
          : ScrollController();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    for (final c in _pending.values) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Resolve every open undo window at once. The mode transition calls this
  /// before the pager swaps, so nothing is left half-committed against a page
  /// set that no longer exists.
  void resolvePending({required bool commit}) {
    for (final entry in _pending.entries.toList()) {
      entry.value.stop();
      entry.value.dispose();
      if (commit) widget.onCommit(entry.key, true);
    }
    _pending.clear();
    if (mounted) setState(() {});
  }

  void _tapCentred(ProtoChecklistItem item) {
    final open = _pending[item.id];
    if (open != null) {
      // Second tap inside the window takes it back. Nothing was ever written.
      open.stop();
      open.dispose();
      setState(() => _pending.remove(item.id));
      return;
    }
    if (item.done) {
      widget.onCommit(item.id, false);
      return;
    }
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.tuning.undoMs),
    );
    controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      controller.dispose();
      if (!mounted) return;
      setState(() => _pending.remove(item.id));
      widget.onCommit(item.id, true);
    });
    setState(() => _pending[item.id] = controller);
    controller.forward();
  }

  Future<void> _openDetail(ProtoChecklistItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItemDetailPage(
          item: item,
          mode: widget.mode,
          onToggleDone: () => widget.onCommit(item.id, !item.done),
          onSkip: () => widget.onSkip(item.id),
        ),
      ),
    );
  }

  /// Ordered groups, then the elements the list draws. Headers are short and
  /// unsnappable; the falloff leaves them alone.
  List<FocusElement> _elements() {
    final tuning = widget.tuning;
    final groupBy = widget.mode == ChecklistMode.session
        ? (tuning.groupBy == GroupBy.store ? GroupBy.category : tuning.groupBy)
        : tuning.groupBy;

    final elements = <FocusElement>[];

    void addItems(
      List<ProtoChecklistItem> items,
      String? group, {
      IconData? icon,
      Color? color,
    }) {
      for (final item in items) {
        elements.add(
          FocusElement(
            extent: tuning.itemExtent,
            groupLabel: group,
            groupIcon: icon,
            groupColor: color,
            builder: (context, d) => _ItemCard(
              item: item,
              d: d,
              tuning: tuning,
              groupBy: groupBy,
              pending: _pending[item.id],
              onTap: () => _onCardTap(item),
              onLongPress: () => _onCardLongPress(item),
            ),
          ),
        );
      }
    }

    void addHeader(String label, {IconData? icon, Color? color}) {
      elements.add(
        FocusElement(
          extent: tuning.headerExtent,
          snappable: false,
          isHeader: true,
          groupLabel: label,
          builder: (context, _) =>
              _GroupHeader(label: label, icon: icon, color: color),
        ),
      );
    }

    if (groupBy == GroupBy.none) {
      addItems(widget.items, null);
    } else {
      final order = <String>[];
      final buckets = <String, List<ProtoChecklistItem>>{};
      final byCategory = groupBy == GroupBy.category;
      final icons = <String, IconData>{};
      final colors = <String, Color>{};
      for (final item in widget.items) {
        final key = byCategory ? item.category.name : item.store;
        if (!buckets.containsKey(key)) {
          order.add(key);
          buckets[key] = [];
          // Both vocabularies come from core, so the watch names a category
          // or a store with the same icon the phone does.
          icons[key] = byCategory
              ? categoryIcon(item.category.iconKey)
              : storeIcon(protoStoreIcons[key]);
          colors[key] = byCategory
              ? item.category.color
              : (protoStoreColors[key] ?? Colors.white54);
        }
        buckets[key]!.add(item);
      }
      for (final key in order) {
        addHeader(key, icon: icons[key], color: colors[key]);
        addItems(buckets[key]!, key, icon: icons[key], color: colors[key]);
      }
    }

    // Browse mode keeps the phone's collapsible Done section. A session has a
    // whole page for it instead, so nothing is appended here.
    if (widget.mode == ChecklistMode.browse && widget.doneItems.isNotEmpty) {
      elements.add(
        FocusElement(
          extent: widget.tuning.headerExtent,
          snappable: false,
          isHeader: true,
          groupLabel: 'Done',
          builder: (context, _) => _GroupHeader(
            label: 'Done (${widget.doneItems.length})',
            icon: Icons.check_circle_outline,
            trailing: Icon(
              _doneCollapsed ? Icons.expand_more : Icons.expand_less,
              size: 14,
              color: Colors.white38,
            ),
            onTap: () => setState(() => _doneCollapsed = !_doneCollapsed),
          ),
        ),
      );
      if (!_doneCollapsed) {
        addItems(
          widget.doneItems,
          'Done',
          icon: Icons.check_circle_outline,
          color: Colors.white54,
        );
      }
    }

    return elements;
  }

  /// Item per element index, with nulls where headers sit.
  List<ProtoChecklistItem?> _flat = const [];

  void _onCardTap(ProtoChecklistItem item) {
    final index = _flat.indexOf(item);
    final centred = widget.geometry.value.centredIndex;
    if (index >= 0 && index != centred) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    _tapCentred(item);
  }

  void _onCardLongPress(ProtoChecklistItem item) {
    final index = _flat.indexOf(item);
    final centred = widget.geometry.value.centredIndex;
    if (index >= 0 && index != centred) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    _openDetail(item);
  }

  @override
  Widget build(BuildContext context) {
    final elements = _elements();
    _flat = _flatten(elements);
    return SnapFocusList(
      key: _listKey,
      controller: _controller,
      elements: elements,
      itemExtent: widget.tuning.itemExtent,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      useWheel: widget.tuning.useWheel,
      rotaryActive: widget.active,
      geometry: widget.geometry,
    );
  }

  /// Rebuild the item-per-index table in the same order [_elements] emitted.
  List<ProtoChecklistItem?> _flatten(List<FocusElement> elements) {
    final out = <ProtoChecklistItem?>[];
    final queue = <ProtoChecklistItem>[..._orderedItems()];
    var cursor = 0;
    for (final e in elements) {
      if (e.isHeader) {
        out.add(null);
      } else {
        out.add(cursor < queue.length ? queue[cursor++] : null);
      }
    }
    return out;
  }

  List<ProtoChecklistItem> _orderedItems() {
    final tuning = widget.tuning;
    final groupBy = widget.mode == ChecklistMode.session
        ? (tuning.groupBy == GroupBy.store ? GroupBy.category : tuning.groupBy)
        : tuning.groupBy;
    final out = <ProtoChecklistItem>[];
    if (groupBy == GroupBy.none) {
      out.addAll(widget.items);
    } else {
      final order = <String>[];
      final buckets = <String, List<ProtoChecklistItem>>{};
      for (final item in widget.items) {
        final key = groupBy == GroupBy.category
            ? item.category.name
            : item.store;
        if (!buckets.containsKey(key)) {
          order.add(key);
          buckets[key] = [];
        }
        buckets[key]!.add(item);
      }
      for (final key in order) {
        out.addAll(buckets[key]!);
      }
    }
    if (widget.mode == ChecklistMode.browse &&
        widget.doneItems.isNotEmpty &&
        !_doneCollapsed) {
      out.addAll(widget.doneItems);
    }
    return out;
  }
}

/// A group header, in the phone's language: the category or store icon and
/// name in that entity's colour, over a hairline rule. Short, unfocusable, and
/// it scrolls like anything else — the rail picks the label up when it slides
/// under.
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
  final ProtoChecklistItem item;
  final double d;
  final ProtoTuning tuning;
  final GroupBy groupBy;
  final AnimationController? pending;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ItemCard({
    required this.item,
    required this.d,
    required this.tuning,
    required this.groupBy,
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
    final expansion = tuning.expandCentre
        ? (1 - (d / 0.4)).clamp(0.0, 1.0)
        : 0.0;
    final eased = Curves.easeOutCubic.transform(expansion);

    // A round screen wants a round row: at the corners of a card the glass is
    // already curving away, so a pill follows the bezel instead of fighting
    // it. A square watch keeps the rectangle it shares an edge with.
    final radius = WearShape.isRound ? tuning.cardHeight / 2 : 14.0;

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
                      // Pinned rather than left to the font's own metrics:
                      // the card has to fit inside a fixed row extent, and an
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
                if (item.qty != null && expansion < 0.5)
                  Text(
                    item.qty!,
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
                      child: _MetaLine(
                        item: item,
                        tuning: tuning,
                        groupBy: groupBy,
                      ),
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
        // Fixed, not content-sized: a card that shrinks to its one line
        // leaves the difference as dead space inside its row rather than
        // closing the list up, so every card claims its extent less the gap.
        child: SizedBox(
          height: tuning.cardHeight,
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
/// Chips are filtered by the watch's own [ProtoTuning.hiddenChips], which the
/// phone seeds once at pairing and never overrides — and by what the grouping
/// already says: a category chip under a category header repeats the header,
/// so the chip that names the current grouping is dropped.
class _MetaLine extends StatelessWidget {
  final ProtoChecklistItem item;
  final ProtoTuning tuning;
  final GroupBy groupBy;

  const _MetaLine({
    required this.item,
    required this.tuning,
    required this.groupBy,
  });

  @override
  Widget build(BuildContext context) {
    final neutral = const Color(0xFFB6B6BE);
    final parts = <Widget>[];

    void chip(String key, Widget child) {
      if (!tuning.isChipVisible(key)) return;
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 5));
      parts.add(child);
    }

    if (groupBy != GroupBy.category) {
      chip(
        'category',
        EntityChip(
          density: ChipDensity.dense,
          textColor: item.category.color,
          label: item.category.name,
          leading: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: item.category.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    if (groupBy != GroupBy.store) {
      final tint = protoStoreColors[item.store] ?? neutral;
      chip(
        'store',
        EntityChip(
          density: ChipDensity.dense,
          textColor: tint,
          label: item.store,
          leading: Icon(
            storeIcon(protoStoreIcons[item.store]),
            size: 9,
            color: tint,
          ),
        ),
      );
    }
    if (item.qty != null) {
      chip(
        'quantity',
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: item.qty!,
        ),
      );
    }
    if (item.price != null) {
      chip(
        'price',
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          label: item.price!,
        ),
      );
    }
    if (item.note != null) {
      chip(
        'note',
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          leading: const Icon(
            Icons.sticky_note_2_outlined,
            size: 9,
            color: Color(0xFFB6B6BE),
          ),
        ),
      );
    }
    if (item.recurring) {
      chip(
        'recurring',
        EntityChip(
          density: ChipDensity.dense,
          textColor: neutral,
          leading: const Icon(Icons.repeat, size: 9, color: Color(0xFFB6B6BE)),
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

/// Read-only. The watch writes check-state and nothing else, so the three
/// things here are the two check verbs and a hand-off to the phone.
class ItemDetailPage extends StatelessWidget {
  final ProtoChecklistItem item;
  final ChecklistMode mode;
  final VoidCallback onToggleDone;
  final VoidCallback onSkip;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.mode,
    required this.onToggleDone,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const neutral = Color(0xFFB6B6BE);
    final storeTint = protoStoreColors[item.store] ?? neutral;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 18,
            vertical: 46,
          ),
          children: [
            Text(
              item.name,
              textAlign: TextAlign.center,
              textDirection: detectTextDirection(item.name),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (item.description != null) ...[
              const SizedBox(height: 6),
              Text(
                item.description!,
                textAlign: TextAlign.center,
                textDirection: detectTextDirection(item.description!),
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
            const SizedBox(height: 14),
            if (item.qty != null)
              _fact(
                'Quantity',
                value: EntityChip(textColor: neutral, label: item.qty!),
              ),
            _fact(
              'Category',
              value: EntityChip(
                textColor: item.category.color,
                label: item.category.name,
                leading: Icon(
                  categoryIcon(item.category.iconKey),
                  size: 12,
                  color: item.category.color,
                ),
              ),
            ),
            _fact(
              'Store',
              value: EntityChip(
                textColor: storeTint,
                label: item.store,
                leading: Icon(
                  storeIcon(protoStoreIcons[item.store]),
                  size: 12,
                  color: storeTint,
                ),
              ),
            ),
            if (item.price != null)
              _fact(
                'Price',
                value: EntityChip(textColor: neutral, label: item.price!),
              ),
            // A schedule, not a flag: "recurring" alone tells you nothing you
            // could act on, so the row carries what core already knows how to
            // say about the rule.
            _fact(
              'Repeats',
              value: EntityChip(
                textColor: item.recurring ? scheme.primary : neutral,
                label: item.recurring ? formatRrule(item.rrule!) : 'One-time',
                leading: Icon(
                  item.recurring ? Icons.repeat : Icons.looks_one_outlined,
                  size: 12,
                  color: item.recurring ? scheme.primary : neutral,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _button(
              context,
              icon: item.done ? Icons.remove_done : Icons.check,
              label: item.done ? 'Mark undone' : 'Mark done',
              color: scheme.primary,
              onTap: () {
                onToggleDone();
                Navigator.of(context).pop();
              },
            ),
            if (mode == ChecklistMode.session) ...[
              const SizedBox(height: 8),
              _button(
                context,
                icon: item.skipped ? Icons.undo : Icons.block,
                label: item.skipped ? 'Unskip' : 'Skip this trip',
                color: const Color(0xFF8A8A92),
                onTap: () {
                  onSkip();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: 8),
            _button(
              context,
              icon: Icons.phone_android,
              label: 'Open on phone',
              color: const Color(0xFF8A8A92),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text(
                    'pantry://item/1/1/…',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Label over value rather than beside it. A watch is too narrow to put a
  /// caption and an arbitrary-length value on one line — a recurrence summary
  /// alone can run to "Every week on Monday, Thursday" — so the value gets the
  /// full width and wraps into it.
  Widget _fact(String label, {required Widget value}) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.7,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Align(alignment: AlignmentDirectional.centerStart, child: value),
      ],
    ),
  );

  Widget _button(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    ),
  );
}
