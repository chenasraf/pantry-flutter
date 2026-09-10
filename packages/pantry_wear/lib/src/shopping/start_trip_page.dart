import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../widgets/focus_list.dart';
import '../widgets/wear_choice_page.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'start_trip_controller.dart';
import 'trip_reminders_page.dart';

/// What a trip is started with: the reminders to read, the lists to shop, the
/// stores to walk and whether housemates see any of it.
///
/// Four rows over one call to action. The rows follow the account page's rule —
/// a row that asks a question opens a page rather than answering in place —
/// with privacy the exception: a switch shows its value and the outcome of a
/// tap at once, which is the whole of what that rule was guarding against.
///
/// Pops `true` when a trip is live, so the shell reads the mode back off the
/// controller rather than being handed a session. There is one path into a
/// session however it began.
class StartTripPage extends StatefulWidget {
  final int houseId;

  /// Supplied only by tests, which pump the real tree against a controller
  /// holding a fixed answer. The page starts the one it makes itself.
  final StartTripController? controller;

  const StartTripPage({super.key, required this.houseId, this.controller});

  @override
  State<StartTripPage> createState() => _StartTripPageState();
}

class _StartTripPageState extends State<StartTripPage> {
  late final StartTripController _controller;
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this page must take the crown with it: the detent
  /// stream is broadcast and a covered list stays mounted, so without this one
  /// turn of the bezel scrolls both.
  var _covered = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? StartTripController(houseId: widget.houseId);
    _controller.addListener(_onChanged);
    // Whether the last request reached the server is what decides the call to
    // action, and it changes without this page asking anything.
    SyncManager.instance.status.addListener(_onChanged);
    if (widget.controller == null) unawaited(_controller.load());
  }

  @override
  void dispose() {
    SyncManager.instance.status.removeListener(_onChanged);
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _push(Widget page) async {
    setState(() => _covered = true);
    await Navigator.of(context).push<void>(wearRoute<void>(page));
    if (mounted) setState(() => _covered = false);
  }

  /// The checklists page's rule, unchanged: a card that is not on the centre
  /// line scrolls there and nothing happens, so a mis-aim costs a scroll rather
  /// than a choice. The distance is checked as well as the index — "nearest
  /// snappable" is not "on the line".
  void _tap(int index, VoidCallback action) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    action();
  }

  /// A refused start leaves the page standing, with the reason where the reason
  /// for a blocked one goes — the wearer's choices are still on screen and the
  /// button is the thing to try again.
  Future<void> _start() async {
    final session = await _controller.start();
    if (mounted && session != null) Navigator.of(context).pop(true);
  }

  // -- The list --------------------------------------------------------------

  List<FocusElement> _elements() {
    final metrics = WearMetrics.of(context);
    final elements = <FocusElement>[];

    void row({
      required IconData icon,
      required String label,
      String? value,
      bool? toggled,
      required VoidCallback onTap,
    }) {
      // Captured as the row is added, so the order lives in one place.
      final index = elements.length;
      elements.add(
        FocusElement(
          extent: metrics.itemExtent,
          builder: (context, d) => Padding(
            padding: EdgeInsetsDirectional.only(bottom: metrics.cardGap),
            child: WearRow(
              icon: icon,
              label: label,
              value: value,
              toggled: toggled,
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
      value: '${_controller.reminders.length}',
      onTap: () =>
          unawaited(_push(TripRemindersPage(reminders: _controller.reminders))),
    );

    row(
      icon: EntityIcons.checklists,
      label: m.shopping.listsToShop,
      value: m.wear.nSelected(_controller.selectedListIds.length),
      onTap: () => unawaited(_push(_listPicker())),
    );

    row(
      icon: EntityIcons.store,
      label: m.shopping.storesTitle,
      value: m.wear.nSelected(_controller.enabledStoreIds.length),
      onTap: () => unawaited(_push(_storePicker())),
    );

    row(
      icon: _controller.isPrivate ? Icons.visibility_off : Icons.visibility,
      label: m.wear.privateTrip,
      toggled: _controller.isPrivate,
      onTap: () => _controller.setPrivate(!_controller.isPrivate),
    );

    return elements;
  }

  Widget _listPicker() => WearMultiChoicePage<int>(
    choices: [
      for (final list in _controller.lists)
        WearChoice(
          value: list.id,
          label: list.name,
          icon: checklistIcon(list.icon),
          tint: parseHexColor(list.color) ?? Colors.white70,
        ),
    ],
    selected: _controller.selectedListIds,
    empty: m.wear.noLists,
    onChanged: _controller.selectLists,
  );

  Widget _storePicker() => WearMultiChoicePage<int>(
    choices: [
      for (final store in _controller.availableStores)
        WearChoice(
          value: store.id,
          label: store.name,
          icon: storeIcon(store.icon),
          tint: parseHexColor(store.color) ?? Colors.white70,
        ),
    ],
    selected: _controller.enabledStoreIds,
    empty: m.wear.noStoresHere,
    onChanged: _controller.enableStores,
  );

  // -- Frame -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
                  elements: _elements(),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearCta.insetFor(constraints.maxHeight),
                child: WearCta(
                  key: const ValueKey('start-trip'),
                  icon: Icons.shopping_cart_checkout,
                  label: m.shopping.startShopping,
                  reason: _controller.blockedReason,
                  error: _controller.error,
                  busy: _controller.isStarting,
                  onTap: () => unawaited(_start()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
