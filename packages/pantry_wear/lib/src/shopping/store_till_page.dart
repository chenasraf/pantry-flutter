import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../checklists/checklists_controller.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'store_group.dart';

/// What the shop being left charged, asked on the way out of it.
///
/// A till is only in front of the wearer while they are standing at it, so the
/// figure is asked for here rather than saved up for the end of the trip. Only
/// the shop being left is shown: the others have their own moment, and one of
/// them has not happened yet.
///
/// The button moves the trip on whether or not a figure was given. A shop that
/// charged nothing has nothing to record, and making the wearer say so at every
/// leg would be a toll on the one gesture the trip is made of.
///
/// Pops `true` once the trip has moved, and nothing when the wearer backs out.
class StoreTillPage extends StatefulWidget {
  final ChecklistsController controller;

  /// The shop being left — null for a trip's storeless fallback, whose figure
  /// is the trip's own.
  final int? storeId;

  /// The leg the trip moves to when the button is pressed.
  final int nextStoreId;

  const StoreTillPage({
    super.key,
    required this.controller,
    required this.storeId,
    required this.nextStoreId,
  });

  @override
  State<StoreTillPage> createState() => _StoreTillPageState();
}

class _StoreTillPageState extends State<StoreTillPage> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// The field pushed over this page takes the crown with it.
  var _covered = false;

  /// The trip refusing to move, said above the button that asked it to. The
  /// wearer is still at the till, and the button is what to try again.
  String? _error;

  /// A second tap while the first is still in flight would advance twice.
  var _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Whether the last request reached the server decides whether the button
    // can act at all, and it changes without the page asking anything.
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

  Future<void> _editBilled(String storeName) async {
    setState(() => _covered = true);
    await askBilled(
      context,
      widget.controller,
      storeId: widget.storeId,
      storeName: storeName,
    );
    if (mounted) setState(() => _covered = false);
  }

  /// The page leaves on the move landing, and stays to say so when it does
  /// not — a refusal here is the trip declining to move, not the till figure
  /// failing, which was queued and is already safe.
  Future<void> _advance() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final moved = await widget.controller.advanceTo(widget.nextStoreId);
    if (!mounted) return;
    if (moved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = m.wear.advanceFailed;
    });
  }

  /// What went in the basket at this shop, as the trip last described it.
  List<ListItem> get _bought {
    for (final store
        in widget.controller.review?.stores ?? const <ShoppingReviewStore>[]) {
      if (store.storeId == widget.storeId) return store.items;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final shop = controller.storeById(widget.storeId);
    final name = shop?.name ?? m.shopping.anyStore;
    final nextStore = controller.storeById(widget.nextStoreId);
    final blocked = controller.isOnline ? null : m.wear.needsConnection;

    final elements = <FocusElement>[];
    appendStoreGroup(
      metrics: WearMetrics.of(context),
      elements: elements,
      shop: shop,
      items: _bought,
      billed: controller.billedFor(widget.storeId),
      tap: _tap,
      onEditBilled: () => unawaited(_editBilled(name)),
    );

    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: SnapFocusList(
                  key: _listKey,
                  controller: _scroll,
                  itemExtent: WearMetrics.of(context).itemExtent,
                  falloffRows: WearMetrics.falloffRows,
                  rotaryActive: !_covered,
                  geometry: _geometry,
                  elements: elements,
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearCta.insetFor(constraints.maxHeight),
                child: WearCta(
                  key: const ValueKey('advance-trip'),
                  icon: Icons.arrow_forward,
                  label: m.wear.nextIs(nextStore?.name ?? m.shopping.anyStore),
                  reason: blocked,
                  error: _error,
                  busy: _busy,
                  onTap: () => unawaited(_advance()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
