import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/shopping/shopping_reminders_view.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.shopping.checkFailed)));
    }
  }

  /// Tap a Done-drawer row to reverse the check — it leaves the drawer and
  /// returns to the to-buy list.
  Future<void> _uncheck(ListItem item) async {
    try {
      await _c.uncheckItem(item);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.shopping.checkFailed)));
    }
  }

  /// Swipe removed [item] from this trip. Optimistic + queued (survives
  /// offline); an Undo toast unskips it.
  void _skip(ListItem item) {
    _c.skipItem(item);
    showUndoSnackBar(
      message: m.shopping.removedFromTrip,
      undoLabel: m.shopping.undo,
      onUndo: () => _c.unskipItem(item.id),
      undoFailedMessage: m.shopping.undoRemoveFailed,
    );
  }

  /// Restore a removed item back onto the trip from the "Removed" section.
  /// Shares the unskip path with the Undo snackbar.
  Future<void> _restore(ListItem item) async {
    try {
      await _c.unskipItem(item.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.shopping.restoreFailed)));
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.shopping.loadFailed)));
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
          leading: appBarBackLeading(context),
          title: Text(activeStore?.name ?? m.shopping.startTitle),
          actions: [
            IconButton(
              icon: Icon(
                session.isPrivate ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: session.isPrivate
                  ? m.shopping.makePublic
                  : m.shopping.makePrivate,
              onPressed: _togglePrivacy,
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
