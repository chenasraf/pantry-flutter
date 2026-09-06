import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/currencies.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../checklists/checklists_controller.dart';
import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'billed_amount_page.dart';

/// What the trip came to, and the last chance to say so.
///
/// It earns its page rather than asking "are you sure?" about a trip it
/// declines to describe: the tally, the bought items grouped by the shop they
/// came from, what each till charged, and *Finish trip* as the last row. The
/// back gesture is the cancel.
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
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _tap(int index, VoidCallback action) {
    final geometry = _geometry.value;
    if (index != geometry.centredIndex ||
        geometry.centredDistance > WearMetrics.itemExtent / 2) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    action();
  }

  /// The figure is queued, so it is on screen before it is sent and survives
  /// the relaunch a watch is always one moment from.
  Future<void> _editBilled(int? storeId, String storeName) async {
    final billed = widget.controller.billedFor(storeId);
    setState(() => _covered = true);
    final entered = await Navigator.of(context).push<BilledAmount>(
      wearRoute<BilledAmount>(
        BilledAmountPage(
          storeName: storeName,
          total: billed.total,
          currency: billed.currency ?? widget.controller.lastCurrency,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _covered = false);
    if (entered == null) return;
    widget.controller.setBilled(
      storeId: storeId,
      total: entered.total,
      currency: entered.currency,
    );
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

    for (final store in review?.stores ?? const <ShoppingReviewStore>[]) {
      if (store.items.isEmpty) continue;
      final shop = controller.storeById(store.storeId);
      final name = shop?.name ?? m.shopping.anyStore;
      final tint = shop == null
          ? Colors.white54
          : parseHexColor(shop.color) ?? Colors.white54;
      block(
        WearMetrics.headerExtent,
        _StoreHeader(
          label: name,
          icon: shop == null ? EntityIcons.store : storeIcon(shop.icon),
          tint: tint,
        ),
        group: name,
      );
      for (final item in store.items) {
        block(WearMetrics.summaryLineExtent, _BoughtLine(item: item));
      }
      final billed = controller.billedFor(store.storeId);
      row(
        icon: EntityIcons.price,
        tint: tint,
        label: m.shopping.actualPaid,
        value: _amountLabel(billed) ?? m.wear.notBilled,
        onTap: () => unawaited(_editBilled(store.storeId, name)),
      );
    }

    row(
      icon: Icons.done_all,
      label: m.shopping.finishTrip,
      warning: true,
      onTap: () => unawaited(_finish()),
    );

    return elements;
  }

  static String? _amountLabel(({double? total, String? currency}) billed) {
    final total = billed.total;
    if (total == null) return null;
    return CurrencyAmount(
      currency: billed.currency ?? defaultCurrency,
      amount: total,
    ).label;
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

/// The shop a run of bought lines came from, in the phone's own language: its
/// icon and name in its own colour over a hairline rule.
class _StoreHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;

  const _StoreHeader({
    required this.label,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: WearShape.isRound ? 22 : 16,
    ),
    child: Container(
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tint.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 5),
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
        ],
      ),
    ),
  );
}

/// One thing that went in the basket. Content passing through rather than a
/// target, so it is drawn as a line and not as a card.
class _BoughtLine extends StatelessWidget {
  final ListItem item;

  const _BoughtLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: WearShape.isRound ? 24 : 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(item.name),
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                color: Colors.white70,
              ),
            ),
          ),
          if (quantity != null) ...[
            const SizedBox(width: 6),
            Text(
              quantity,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(quantity),
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
