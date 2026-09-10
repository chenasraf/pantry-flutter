import 'package:flutter/material.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../checklists/checklists_controller.dart';
import '../checklists/item_card.dart';
import '../widgets/focus_list.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_metrics.dart';

/// What a trip has behind it: the items bought at it, or the ones passed over.
///
/// Both pages are the checklist page with one verb instead of two — the same
/// card, the same falloff, the same centre line, and a tap that puts an item
/// back on the list. They are the checklist's own rows in a different state,
/// so drawing them as a different kind of row would say they were a different
/// kind of thing.
///
/// The tap works here as everywhere else: an off-centre tap scrolls that row to
/// the centre line and writes nothing, so a mis-aim costs a scroll. The undo
/// window behind the write is the second protection, not the first.
class TripCollectionPage extends StatefulWidget {
  final ChecklistsController controller;
  final List<ListItem> items;

  /// Said in place of the list when the trip has nothing here yet.
  final String empty;

  /// The glyph that names the state these rows are in — a tick for bought, a
  /// struck-through trolley for passed over.
  final IconData markedIcon;

  /// What a committed tap does: put the item back on the list.
  final void Function(ListItem item) onTap;

  /// Whether the crown is this list's to steer: the page in front, and only
  /// while turning it scrolls rather than turns pages.
  final bool rotary;

  const TripCollectionPage({
    super.key,
    required this.controller,
    required this.items,
    required this.empty,
    required this.markedIcon,
    required this.onTap,
    required this.rotary,
  });

  @override
  State<TripCollectionPage> createState() => _TripCollectionPageState();
}

class _TripCollectionPageState extends State<TripCollectionPage>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  late final UndoWindows<int> _pending;

  @override
  void initState() {
    super.initState();
    _pending = UndoWindows(
      vsync: this,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _pending.dispose();
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  /// The checklists page's rule: a card that is not on the centre line scrolls
  /// there and nothing happens. The distance is checked as well as the index —
  /// "nearest snappable" is not "on the line", and acting on a row the wearer
  /// can see is not in charge is the failure the rule exists to prevent.
  void _tap(int index, ListItem item) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    // False is where the row is heading: off this page and back onto the list,
    // which is what the card draws while the window drains.
    _pending.fire(item.id, target: false, commit: (_) => widget.onTap(item));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: WearMetrics.bandInsets(context),
          child: Text(
            widget.empty,
            textAlign: TextAlign.center,
            textDirection: detectTextDirection(widget.empty),
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
        ),
      );
    }
    final metrics = WearMetrics.of(context);
    return SnapFocusList(
      key: _listKey,
      controller: _scroll,
      itemExtent: metrics.itemExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.rotary,
      horizontalInset: WearMetrics.sideInset,
      geometry: _geometry,
      underRail: true,
      elements: [
        for (var i = 0; i < items.length; i++)
          FocusElement(
            extent: metrics.itemExtent,
            builder: (context, d) => ItemCard(
              item: items[i],
              d: d,
              controller: widget.controller,
              // Every row here is in the state the page is about, until a
              // window takes one of them out of it.
              marked: _pending.targetOf(items[i].id) ?? true,
              markedIcon: widget.markedIcon,
              pending: _pending.controllerOf(items[i].id),
              onTap: () => _tap(i, items[i]),
            ),
          ),
      ],
    );
  }
}
