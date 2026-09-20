import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_presence_entry.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../checklists/checklists_controller.dart';
import '../services/server_reach.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_avatar.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';

/// What the wearer settled on: a housemate's trip joined, or one of their own
/// to configure.
enum JoinChoice { joined, startOwn }

/// The trips already under way in the house, offered before the wearer sets up
/// one of their own.
///
/// Two people shopping the same list in two trips is the thing this page
/// exists to prevent, so a housemate's trip is put where it is read first —
/// but it is an offer and never a gate: *start my own* holds the fixed action
/// slot at the bottom of the screen, where every other page on the watch keeps
/// the thing it is for, and a wearer who wants their own trip reaches it
/// without reading a row.
///
/// One row per trip rather than per shopper: housemates sharing a trip appear
/// together under whoever started it, which is also how the server describes
/// them.
class JoinTripPage extends StatefulWidget {
  final ChecklistsController controller;

  const JoinTripPage({super.key, required this.controller});

  @override
  State<JoinTripPage> createState() => _JoinTripPageState();
}

class _JoinTripPageState extends State<JoinTripPage> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// Held from the moment a row is tapped: joining is a round trip, and a
  /// second tap would ask to be put in two trips at once.
  var _busy = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    // Whether the link is up decides whether these rows can act at all, and it
    // changes without this page asking anything.
    SyncManager.instance.status.addListener(_onChanged);
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

  /// The checklists page's rule, unchanged: a card that is not on the centre
  /// line scrolls there and nothing happens, so a mis-aim costs a scroll rather
  /// than a trip.
  void _tap(int index, VoidCallback action) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    action();
  }

  /// A refused join leaves the page standing with the reason where the reason
  /// for a blocked start goes: the other trips are still on screen, and one of
  /// them may be the one to take.
  Future<void> _join(ShoppingPresenceEntry entry) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final joined = await widget.controller.joinTrip(entry);
    if (!mounted) return;
    if (joined) {
      Navigator.of(context).pop(JoinChoice.joined);
      return;
    }
    setState(() {
      _busy = false;
      _error = m.wear.joinFailed;
    });
  }

  // -- The list --------------------------------------------------------------

  List<FocusElement> _elements() {
    final metrics = WearMetrics.of(context);
    final controller = widget.controller;
    final offline = !SyncManager.instance.isOnline;
    final elements = <FocusElement>[];

    for (final entry in controller.joinableTrips) {
      // Captured as the row is added, so the order lives in one place.
      final index = elements.length;
      final starter = controller.displayNameOf(entry.userId);
      final others = entry.memberIds.length - 1;
      final store = controller.storeById(entry.activeStoreId);
      elements.add(
        FocusElement(
          extent: metrics.itemExtent,
          builder: (context, d) => Padding(
            padding: EdgeInsetsDirectional.only(bottom: metrics.cardGap),
            child: WearRow(
              leading: WearAvatarStack(
                members: [
                  for (final id in entry.memberIds)
                    (userId: id, displayName: controller.displayNameOf(id)),
                ],
              ),
              label: others > 0 ? m.wear.plusOthers(starter, others) : starter,
              value: store?.name ?? m.shopping.bannerShoppingNow,
              reason: unreachableReason(!offline),
              distance: d,
              onTap: () => _tap(index, () => unawaited(_join(entry))),
            ),
          ),
        ),
      );
    }

    return elements;
  }

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
                  rotaryActive: true,
                  geometry: _geometry,
                  elements: _elements(),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearCta.insetFor(constraints.maxHeight),
                child: WearCta(
                  key: const ValueKey('start-my-own'),
                  icon: Icons.shopping_cart_checkout,
                  label: m.wear.startMyOwn,
                  error: _error,
                  busy: _busy,
                  onTap: () => Navigator.of(context).pop(JoinChoice.startOwn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
