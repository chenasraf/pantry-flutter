import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../checklists/checklists_controller.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'store_group.dart';

/// What the trip came to, and the last chance to say so.
///
/// It earns its page rather than asking "are you sure?" about a trip it
/// declines to describe: the tally, the bought items grouped by the shop they
/// came from, what each till charged, and *Finish trip* as the last row. The
/// back gesture is the cancel.
///
/// Every leg of the trip is named, bought from or not — a shop takes money for
/// things that were never on the list, and its till is the only place that
/// figure can be recorded.
///
/// Nothing here costs a request. It is drawn from the review the trip has been
/// loading every poll and from the trip itself, so it works in the dead spot a
/// till is usually in.
///
/// Pops `true` once the trip is closed, `false` when the close was refused, and
/// nothing when the wearer backs out.
class TripSummaryPage extends StatefulWidget {
  final ChecklistsController controller;

  const TripSummaryPage({super.key, required this.controller});

  @override
  State<TripSummaryPage> createState() => _TripSummaryPageState();
}

class _TripSummaryPageState extends State<TripSummaryPage> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this page takes the crown with it.
  var _covered = false;

  /// A second tap on a close already in flight would ask twice.
  var _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Closing is online-only, and whether the link is there changes without
    // the page asking anything.
    SyncManager.instance.status.addListener(_onChanged);
  }

  @override
  void dispose() {
    SyncManager.instance.status.removeListener(_onChanged);
    widget.controller.removeListener(_onChanged);
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _tap(int index, VoidCallback action) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    action();
  }

  Future<void> _editBilled(int? storeId, String storeName) async {
    setState(() => _covered = true);
    await askBilled(
      context,
      widget.controller,
      storeId: storeId,
      storeName: storeName,
    );
    if (mounted) setState(() => _covered = false);
  }

  /// The page leaves either way: closed, or carrying the refusal back to the
  /// button that asked. So [_closing] is never cleared — there is nothing left
  /// here to press.
  Future<void> _finish() async {
    if (_closing) return;
    _closing = true;
    final closed = await widget.controller.closeTrip();
    if (!mounted) return;
    Navigator.of(context).pop(closed);
  }

  // -- The list --------------------------------------------------------------

  List<FocusElement> _elements() {
    final controller = widget.controller;
    final review = controller.review;
    final elements = <FocusElement>[];

    void block(double extent, Widget child, {String? group}) => elements.add(
      FocusElement(
        extent: extent,
        snappable: false,
        isHeader: true,
        groupLabel: group,
        builder: (context, _) => child,
      ),
    );

    void row({
      required IconData icon,
      Color tint = Colors.white70,
      required String label,
      String? value,
      String? reason,
      bool warning = false,
      required VoidCallback onTap,
    }) {
      final index = elements.length;
      elements.add(
        FocusElement(
          extent: WearMetrics.itemExtent,
          builder: (context, d) => Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: WearMetrics.cardGap,
            ),
            child: WearRow(
              icon: icon,
              tint: tint,
              label: label,
              value: value,
              reason: reason,
              warning: warning,
              distance: d,
              onTap: () => _tap(index, onTap),
            ),
          ),
        ),
      );
    }

    // Absent rather than zero when the log never arrived: "0 bought" would
    // name a trip that bought nothing, where what is true is that this watch
    // has not been told.
    if (review != null) {
      block(_tallyExtent, _Tally(review: review));
    }

    void storeGroup(int? storeId, List<ListItem> items) {
      final shop = controller.storeById(storeId);
      appendStoreGroup(
        elements: elements,
        shop: shop,
        items: items,
        billed: controller.billedFor(storeId),
        tap: _tap,
        onEditBilled: () =>
            unawaited(_editBilled(storeId, shop?.name ?? m.shopping.anyStore)),
      );
    }

    final groups = review?.stores ?? const <ShoppingReviewStore>[];
    for (final store in groups) {
      storeGroup(store.storeId, store.items);
    }
    // A trip with no legs that checked nothing off is described by no groups
    // at all, and the till still charged for whatever went in the basket. The
    // figure it takes is the trip's own.
    if (review != null && groups.isEmpty) storeGroup(null, const []);

    // The tills above stay open on a dead link — their figures go to the queue
    // — and only the close is held back, because a queued one would have to
    // vanish the session pager on a write that has not happened.
    row(
      icon: Icons.done_all,
      label: m.shopping.finishTrip,
      reason: controller.isOnline ? null : m.wear.needsConnection,
      warning: true,
      onTap: () => unawaited(_finish()),
    );

    return elements;
  }

  /// Two lines and the air above them, the same weight the account page gives
  /// its identity: read once, never aimed at.
  static const double _tallyExtent = 54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: SnapFocusList(
          key: _listKey,
          controller: _scroll,
          itemExtent: WearMetrics.itemExtent,
          falloffRows: WearMetrics.falloffRows,
          rotaryActive: !_covered,
          geometry: _geometry,
          elements: _elements(),
        ),
      ),
    );
  }
}

/// What the trip came to, in the two numbers a wearer wants before they end
/// it, over what the prices add up to.
class _Tally extends StatelessWidget {
  final ShoppingReview review;

  const _Tally({required this.review});

  @override
  Widget build(BuildContext context) {
    final bought = review.stores.fold<int>(0, (n, s) => n + s.items.length);
    final shops = review.stores.where((s) => s.items.isNotEmpty).length;
    final estimate = formatShoppingEstimate(review.grandTotal);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${m.wear.boughtTally(bought)} · ${m.wear.storeTally(shops)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (estimate != null)
          Text(
            estimate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              color: Colors.white38,
            ),
          ),
      ],
    );
  }
}
