import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/item_detail_view.dart';
import 'package:pantry/views/shopping/shopping_reminders_view.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/auto_refresh.dart';

import 'shopping_session_widgets.dart';

/// The live, dense shopping screen. Polls (items + heartbeat + done-today) on
/// the user-configured shopping interval — which defaults to following the
/// checklist interval — paused while the app is backgrounded and fired on
/// resume. Also supports pull-to-refresh.
class ShoppingSessionView extends StatefulWidget {
  final ShoppingSession session;

  const ShoppingSessionView({super.key, required this.session});

  @override
  State<ShoppingSessionView> createState() => _ShoppingSessionViewState();
}

class _ShoppingSessionViewState extends State<ShoppingSessionView> {
  late final _controller = ShoppingSessionController(session: widget.session);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _SessionBody(),
    );
  }
}

class _SessionBody extends StatefulWidget {
  const _SessionBody();

  @override
  State<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends State<_SessionBody> {
  bool _doneExpanded = false;
  bool _removedExpanded = false;
  bool _busy = false;

  ShoppingSessionController get _c => context.read<ShoppingSessionController>();

  Future<void> _check(ListItem item) async {
    try {
      await _c.checkItem(item);
    } catch (_) {
      if (!mounted) return;
      showAppToast(message: m.shopping.checkFailed, kind: ToastKind.error);
    }
  }

  /// Tap a Done-drawer row to reverse the check — it leaves the drawer and
  /// returns to the to-buy list.
  Future<void> _uncheck(ListItem item) async {
    try {
      await _c.uncheckItem(item);
    } catch (_) {
      if (!mounted) return;
      showAppToast(message: m.shopping.checkFailed, kind: ToastKind.error);
    }
  }

  /// Swipe removed [item] from this trip. Optimistic + queued (survives
  /// offline); an Undo toast unskips it.
  void _skip(ListItem item) {
    _c.skipItem(item);
    showUndoToast(
      message: m.shopping.removedFromTrip,
      undoLabel: m.shopping.undo,
      onUndo: () => _c.unskipItem(item.id),
      undoFailedMessage: m.shopping.undoRemoveFailed,
    );
  }

  /// Restore a removed item back onto the trip from the "Removed" section.
  /// Shares the unskip path with the Undo toast.
  Future<void> _restore(ListItem item) async {
    try {
      await _c.unskipItem(item.id);
    } catch (_) {
      if (!mounted) return;
      showAppToast(message: m.shopping.restoreFailed, kind: ToastKind.error);
    }
  }

  /// The checklists controller [ItemDetailView] writes through, built the first
  /// time a row's view button is pressed and kept for the rest of the trip.
  ///
  /// A trip is its own route, so the checklists tab's controller is not in this
  /// tree — and a trip is walked far more often than an item is opened from
  /// one, which is why this is not built up front.
  ChecklistsController? _itemsController;

  @override
  void dispose() {
    _itemsController?.dispose();
    super.dispose();
  }

  /// Load the checklists reference data the detail screen needs, once.
  ///
  /// Loading selects a list, and the selection is shared with the checklists
  /// tab — so it is put back afterwards, or opening an item mid-trip would
  /// decide which list that tab opens on next.
  Future<ChecklistsController> _ensureItemsController() async {
    final existing = _itemsController;
    if (existing != null) return existing;
    final controller = ChecklistsController(houseId: _c.houseId);
    _itemsController = controller;
    final savedListId = ChecklistService.instance.selectedListId;
    try {
      await controller.load();
    } finally {
      ChecklistService.instance.selectedListId = savedListId;
    }
    return controller;
  }

  /// Open the item's full detail screen. Everything it offers — edit, move,
  /// delete — goes through the sync queue, so the next poll brings the change
  /// back onto the trip.
  Future<void> _view(ListItem item) async {
    final controller = await _ensureItemsController();
    if (!mounted) return;
    await Navigator.of(context).push(
      itemModalRoute(
        ItemDetailView(
          item: item,
          category: item.categoryId != null
              ? controller.categories[item.categoryId]
              : null,
          stores: controller.storesFor(item),
          labels: controller.labelsFor(item),
          houseId: controller.houseId,
          controller: controller,
        ),
      ),
    );
    if (!mounted) return;
    await _c.poll();
  }

  Future<void> _jumpToStore(int storeId) async {
    if (storeId == _c.session.activeStoreId) return;
    try {
      await _c.advance(storeId);
    } catch (_) {
      /* poll will reconcile */
    }
  }

  Future<void> _togglePrivacy() async {
    try {
      await _c.setPrivacy(!_c.session.isPrivate);
    } catch (_) {
      /* reverted in controller */
    }
  }

  /// Step out of a housemate's trip, leaving it running for them.
  Future<void> _leave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _c.leave();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(message: m.shopping.leaveTripFailed, kind: ToastKind.error);
    }
  }

  /// Whoever finishes a shared trip finishes it for everyone, so a poll can
  /// find the screen standing on a trip that is over. Say so and step out.
  bool _departed = false;

  void _handleTripEnded() {
    if (_departed || !mounted) return;
    _departed = true;
    showAppToast(
      message: m.shopping.tripFinishedByHousemate,
      kind: ToastKind.info,
    );
    Navigator.of(context).pop();
  }

  Future<void> _openReminders() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingRemindersView(houseId: _c.houseId),
      ),
    );
  }

  /// FAB action: review the current store, then advance to the next store or
  /// finish the trip.
  Future<void> _reviewAndProceed() async {
    if (_busy) return;
    final controller = _c;
    final session = controller.session;
    final nextStoreId = session.nextStoreId;
    final isAdvance = nextStoreId != null;
    final mode = isAdvance
        ? ShoppingReviewMode.advance
        : ShoppingReviewMode.close;
    final moment = isAdvance
        ? ShoppingReminderMoment.onStoreAdvance
        : ShoppingReminderMoment.onClose;

    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShoppingReviewView(
          houseId: controller.houseId,
          sessionId: controller.sessionId,
          mode: mode,
          activeStoreId: session.activeStoreId,
          stores: controller.stores,
          reminders: controller.remindersFor(moment),
          onManageReminders: _openReminders,
        ),
      ),
    );

    if (!mounted) return;
    if (confirmed != true) {
      // Billed edits may have landed — refresh the session DTO.
      await controller.refreshSession();
      return;
    }

    setState(() => _busy = true);
    try {
      if (isAdvance) {
        await controller.advance(nextStoreId);
      } else {
        await controller.close();
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (_) {
      if (mounted) {
        showAppToast(message: m.shopping.loadFailed, kind: ToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShoppingSessionController>();
    final prefs = context.watch<PrefsService>();
    final session = controller.session;
    if (controller.hasEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleTripEnded());
    }
    final activeStore = session.activeStoreId != null
        ? controller.stores[session.activeStoreId]
        : null;
    final hasNext = session.nextStoreId != null;

    return AutoRefresh(
      interval: AutoRefresh.durationFromSeconds(
        prefs.shoppingRefreshSecondsResolved,
      ),
      onRefresh: () => _c.poll(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(activeStore?.name ?? m.shopping.startTitle),
          actions: [
            // Privacy belongs to the shopper who started the trip; a housemate
            // who joined 404s on it.
            if (controller.isStarter)
              IconButton(
                icon: Icon(
                  session.isPrivate ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: session.isPrivate
                    ? m.shopping.makePublic
                    : m.shopping.makePrivate,
                onPressed: _togglePrivacy,
              )
            else
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: m.shopping.leaveTrip,
                onPressed: _busy ? null : _leave,
              ),
          ],
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (session.stores.isNotEmpty)
                    ShoppingStoreBar(
                      controller: controller,
                      onJumpToStore: _jumpToStore,
                    ),
                  ShoppingProgressRow(controller: controller),
                  Expanded(
                    child: ShoppingItemArea(
                      controller: controller,
                      onCheck: _check,
                      onSkip: _skip,
                      onView: _view,
                      onRefresh: () => _c.poll(),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: controller.isLoading
            ? null
            : ShoppingBottomBar(
                controller: controller,
                doneExpanded: _doneExpanded,
                onToggleDone: () =>
                    setState(() => _doneExpanded = !_doneExpanded),
                onUncheck: _uncheck,
                removedExpanded: _removedExpanded,
                onToggleRemoved: () =>
                    setState(() => _removedExpanded = !_removedExpanded),
                onRestore: _restore,
                busy: _busy,
                hasNext: hasNext,
                onProceed: _reviewAndProceed,
              ),
      ),
    );
  }
}
