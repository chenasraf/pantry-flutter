import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';

import '../checklists/checklists_controller.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'trip_reminders_page.dart';
import 'trip_summary_page.dart';

/// Where the trip has got to: the reminders for the moment it is at, the legs
/// behind and ahead of it, and the one move it can make from here.
///
/// The rail already names the shop the wearer is standing in, so the page never
/// repeats it. Tapping the centred leg advances to it — Q19's commit-on-centre
/// unchanged, which is what makes advance reversible: any leg is a legal
/// target, so tapping an earlier one goes back.
///
/// It does not auto-advance. Ticking the last thing off a shop's list is not
/// the same as having left it.
class ProgressionPage extends StatefulWidget {
  final ChecklistsController controller;

  /// Whether this is the page in front.
  final bool active;

  /// Whether the crown is this list's to steer: [active], and only while
  /// turning it scrolls rather than turns pages.
  final bool rotary;

  const ProgressionPage({
    super.key,
    required this.controller,
    required this.active,
    required this.rotary,
  });

  @override
  State<ProgressionPage> createState() => _ProgressionPageState();
}

class _ProgressionPageState extends State<ProgressionPage> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this page takes the crown with it: the detent stream
  /// is broadcast and a covered list stays mounted, so without this one turn of
  /// the bezel scrolls both.
  var _covered = false;

  /// The trip refusing to move, said above the button that asked it to and
  /// standing until the next attempt — the wearer is still looking at the leg
  /// they aimed at, and the button is what to try again.
  String? _error;

  /// A second tap while the first is still in flight would advance twice.
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Whether the last request reached the server decides both moves this page
    // offers, and it changes without the page asking anything.
    SyncManager.instance.status.addListener(_onChanged);
    unawaited(widget.controller.loadReminders());
  }

  @override
  void didUpdateWidget(ProgressionPage old) {
    super.didUpdateWidget(old);
    // Arriving on the page is the moment its reminders are worth re-reading:
    // they change on the scale of weeks, so a poll would only spend the link.
    if (widget.active && !old.active) {
      unawaited(widget.controller.loadReminders());
    }
  }

  @override
  void dispose() {
    SyncManager.instance.status.removeListener(_onChanged);
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  ShoppingSession? get _session => widget.controller.session;

  /// The leg after the one being shopped, or null at the last of them — the
  /// same flag the phone's own call to action reads.
  int? get _nextStoreId => _session?.nextStoreId;

  Future<void> _push(Widget page) async {
    setState(() => _covered = true);
    await Navigator.of(context).push<void>(wearRoute<void>(page));
    if (mounted) setState(() => _covered = false);
  }

  /// The checklists page's rule, unchanged: a card that is not on the centre
  /// line scrolls there and nothing happens, so a mis-aim costs a scroll rather
  /// than a write.
  void _tap(int index, VoidCallback action) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    action();
  }

  Future<void> _advanceTo(int storeId) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final moved = await widget.controller.advanceTo(storeId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = moved ? null : m.wear.advanceFailed;
    });
  }

  /// Finishing goes through the summary, which doubles as the confirmation:
  /// closing is irreversible server-side, so it earns a page rather than the
  /// check's undo stroke.
  Future<void> _finish() async {
    setState(() {
      _covered = true;
      _error = null;
    });
    final closed = await Navigator.of(context).push<bool>(
      wearRoute<bool>(TripSummaryPage(controller: widget.controller)),
    );
    if (!mounted) return;
    setState(() {
      _covered = false;
      // A trip that would not close leaves the wearer back here, where the
      // button that asked is.
      if (closed == false) _error = m.wear.finishFailed;
    });
  }

  /// The reminders for the moment the trip is actually at, in the order the
  /// house put them.
  List<ShoppingReminder> get _reminders {
    final moment = _nextStoreId != null
        ? ShoppingReminderMoment.onStoreAdvance
        : ShoppingReminderMoment.onClose;
    return [
      for (final reminder in widget.controller.reminders)
        if (reminder.enabled && reminder.showOn == moment) reminder,
    ]..sort((a, b) => a.position.compareTo(b.position));
  }

  // -- The list --------------------------------------------------------------

  List<FocusElement> _elements() {
    final controller = widget.controller;
    final session = _session;
    final elements = <FocusElement>[];
    final reminders = _reminders;

    void row({
      required IconData icon,
      Color tint = Colors.white70,
      required String label,
      String? value,
      bool spent = false,
      required VoidCallback onTap,
    }) {
      // Captured as the row is added, so the order lives in one place.
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
              spent: spent,
              distance: d,
              onTap: () => _tap(index, onTap),
            ),
          ),
        ),
      );
    }

    row(
      icon: Icons.notifications_none,
      label: m.shopping.remindersTitle,
      value: '${reminders.length}',
      onTap: () => unawaited(_push(TripRemindersPage(reminders: reminders))),
    );

    final legs = session?.orderedStoreIds ?? const <int>[];
    final activeIndex = legs.indexOf(session?.activeStoreId ?? -1);
    for (var i = 0; i < legs.length; i++) {
      final id = legs[i];
      final store = controller.storeById(id);
      final here = id == session?.activeStoreId;
      row(
        icon: store == null ? EntityIcons.store : storeIcon(store.icon),
        tint: _tintOf(store),
        label: store?.name ?? m.shopping.anyStore,
        value: here ? m.wear.hereNow : null,
        spent: activeIndex >= 0 && i < activeIndex,
        onTap: here ? () {} : () => unawaited(_advanceTo(id)),
      );
    }

    return elements;
  }

  static Color _tintOf(Store? store) => store == null
      ? Colors.white54
      : parseHexColor(store.color) ?? Colors.white54;

  // -- Frame -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final next = _nextStoreId;
    final nextStore = controller.storeById(next);
    final blocked = controller.isOnline ? null : m.wear.needsConnection;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: SnapFocusList(
              key: _listKey,
              controller: _scroll,
              itemExtent: WearMetrics.itemExtent,
              falloffRows: WearMetrics.falloffRows,
              rotaryActive: widget.rotary && !_covered,
              geometry: _geometry,
              underRail: true,
              elements: _elements(),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: WearCta.insetFor(constraints.maxHeight),
            child: next != null
                ? WearCta(
                    key: const ValueKey('advance-trip'),
                    icon: Icons.arrow_forward,
                    label: m.wear.nextIs(
                      nextStore?.name ?? m.shopping.anyStore,
                    ),
                    reason: blocked,
                    error: _error,
                    busy: _busy,
                    onTap: () => unawaited(_advanceTo(next)),
                  )
                : WearCta(
                    key: const ValueKey('finish-trip'),
                    icon: Icons.done_all,
                    label: m.shopping.finishTrip,
                    reason: blocked,
                    error: _error,
                    onTap: () => unawaited(_finish()),
                  ),
          ),
        ],
      ),
    );
  }
}
