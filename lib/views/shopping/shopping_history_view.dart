import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/models/shopping_history_row.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/shopping/delete_trip_dialog.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';
import 'package:pantry/widgets/context_menu_region.dart';
import 'package:pantry/widgets/member_avatar.dart';

/// List of closed trips. A Mine/House scope toggle selects which trips are
/// shown; tapping a row opens its per-store summary, which the shopper who
/// made the trip can open for amending.
class ShoppingHistoryView extends StatefulWidget {
  final int houseId;

  const ShoppingHistoryView({super.key, required this.houseId});

  @override
  State<ShoppingHistoryView> createState() => _ShoppingHistoryViewState();
}

class _ShoppingHistoryViewState extends State<ShoppingHistoryView> {
  static const _pageSize = 30;
  ShoppingService get _service => ShoppingService.instance;

  ShoppingHistoryScope _scope = ShoppingHistoryScope.mine;

  /// Only the shopper who made a trip may amend its totals, so the House scope
  /// reads a housemate's trip without an edit action.
  final String? _currentUserId = AuthService.instance.credentials?.loginName;

  final List<ShoppingHistoryRow> _rows = [];
  Map<int, Store> _stores = {};
  Map<String, String> _memberNames = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  StreamSubscription<SyncOpApplied>? _appliedSub;

  @override
  void dispose() {
    _appliedSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
    _stores = {
      for (final s
          in StoreService.instance.getCached(widget.houseId) ?? const [])
        s.id: s,
    };
    _memberNames = {
      for (final mm
          in HouseService.instance.getCachedMembers(widget.houseId) ?? const [])
        mm.userId: mm.displayName,
    };
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _hasMore = true;
    });
    // Refresh reference data best-effort (names/store labels on the cards).
    unawaited(_loadReferenceData());
    await _fetch(reset: true);
  }

  Future<void> _loadReferenceData() async {
    try {
      final stores = await StoreService.instance.getStores(widget.houseId);
      final members = await HouseService.instance.getMembers(widget.houseId);
      if (!mounted) return;
      setState(() {
        _stores = {for (final s in stores) s.id: s};
        _memberNames = {for (final mm in members) mm.userId: mm.displayName};
      });
    } catch (_) {
      /* keep cached */
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    try {
      final rows = await _service.getHistory(
        widget.houseId,
        scope: _scope,
        limit: _pageSize,
        offset: reset ? 0 : _rows.length,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(rows);
        _hasMore = rows.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (_rows.isEmpty) _error = m.shopping.loadFailed;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetch();
  }

  void _setScope(ShoppingHistoryScope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _reload();
  }

  Future<void> _openSummary(ShoppingHistoryRow row) async {
    final amended = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ShoppingReviewView(
          houseId: widget.houseId,
          sessionId: row.id,
          mode: ShoppingReviewMode.history,
          stores: _stores,
          canEditBilled: row.userId == _currentUserId,
          onDelete: _canDelete(row) ? () => _deleteAndRemove(row) : null,
        ),
      ),
    );
    if (amended == true) await _refreshRow(row.id);
  }

  /// Only the shopper who started a trip may delete it; joining one, or seeing
  /// it in the House scope, is not enough.
  bool _canDelete(ShoppingHistoryRow row) =>
      ServerFeature.shoppingHistoryDelete && row.userId == _currentUserId;

  /// Sends the delete and reports whether it landed, toasting when it didn't.
  /// Removing the row is left to the caller, because a swiped-away card must
  /// leave the list only once its dismiss animation has finished.
  Future<bool> _delete(ShoppingHistoryRow row) async {
    try {
      await _service.deleteSession(widget.houseId, row.id);
      return true;
    } on ApiException catch (e) {
      showAppToast(message: m.shopping.deleteTripFailed, kind: ToastKind.error);
      // The trip is still live, so the list no longer matches the server.
      if (e.statusCode == 409 && mounted) unawaited(_reload());
      return false;
    } catch (_) {
      showAppToast(message: m.shopping.deleteTripFailed, kind: ToastKind.error);
      return false;
    }
  }

  /// The server row is gone too, so dropping it locally keeps the next page's
  /// offset (`_rows.length`) in line without a refetch.
  void _removeRow(int sessionId) {
    if (!mounted) return;
    setState(() => _rows.removeWhere((r) => r.id == sessionId));
  }

  Future<bool> _deleteAndRemove(ShoppingHistoryRow row) async {
    final deleted = await _delete(row);
    if (deleted) _removeRow(row.id);
    return deleted;
  }

  Future<void> _confirmAndDelete(ShoppingHistoryRow row) async {
    if (!await confirmDeleteTrip(context)) return;
    await _deleteAndRemove(row);
  }

  /// A typed total is queued rather than sent, so it reaches the server — and
  /// with it the row's recomputed total — whenever the queue drains, which on a
  /// bad link is long after the summary was closed.
  void _onSyncApplied(SyncOpApplied e) {
    if (e.op.entity != SyncEntity.shoppingSession) return;
    if (e.op.houseId != widget.houseId) return;
    final sessionId = e.op.parentId;
    if (sessionId == null) return;
    if (!_rows.any((r) => r.id == sessionId)) return;
    unawaited(_refreshRow(sessionId));
  }

  /// Pull an amended trip's row back down so the total on the card matches what
  /// was typed. Rows come back in a fixed order, so a row's position is a
  /// stable offset; a shifted position — a trip closed while this one was open
  /// — falls back to a full reload rather than writing over the wrong row.
  Future<void> _refreshRow(int sessionId) async {
    final index = _rows.indexWhere((r) => r.id == sessionId);
    if (index < 0) return;
    try {
      final fetched = await _service.getHistory(
        widget.houseId,
        scope: _scope,
        limit: 1,
        offset: index,
      );
      if (!mounted) return;
      if (fetched.length == 1 && fetched.first.id == sessionId) {
        setState(() => _rows[index] = fetched.first);
      } else {
        await _reload();
      }
    } catch (_) {
      // Non-fatal: the card keeps the older figure until the next refresh.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(m.shopping.historyTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<ShoppingHistoryScope>(
              segments: [
                ButtonSegment(
                  value: ShoppingHistoryScope.mine,
                  label: Text(m.shopping.scopeMine),
                ),
                ButtonSegment(
                  value: ShoppingHistoryScope.house,
                  label: Text(m.shopping.scopeHouse),
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => _setScope(s.first),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorRetry(message: _error!, onRetry: _reload);
    }
    if (_rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _scope == ShoppingHistoryScope.mine
                ? m.shopping.noTripsYet
                : m.shopping.noHouseTripsYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _rows.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _rows.length) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: Text(m.shopping.loadMore),
                      ),
              ),
            );
          }
          final row = _rows[index];
          final canDelete = _canDelete(row);
          final card = _HistoryCard(
            row: row,
            memberName: _memberNames[row.userId],
            onTap: () => _openSummary(row),
            onDelete: canDelete ? () => _confirmAndDelete(row) : null,
          );
          // A swipe is awkward with a mouse or trackpad; desktop reaches the
          // same action through the card's menu instead.
          if (!canDelete || !PlatformInfo.isMobile) return card;
          return Dismissible(
            key: ValueKey('trip-${row.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async =>
                await confirmDeleteTrip(context) && await _delete(row),
            onDismissed: (_) => _removeRow(row.id),
            background: const _DeleteBackground(),
            child: card,
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ShoppingHistoryRow row;
  final String? memberName;
  final VoidCallback onTap;

  /// Asks to delete the trip; null when the viewer may not.
  final VoidCallback? onDelete;

  const _HistoryCard({
    required this.row,
    required this.memberName,
    required this.onTap,
    this.onDelete,
  });

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: cs.error),
            const SizedBox(width: 12),
            Text(m.shopping.deleteTrip, style: TextStyle(color: cs.error)),
          ],
        ),
      ),
    ];
  }

  void _onMenuSelected(String value) {
    if (value == 'delete') onDelete?.call();
  }

  /// Swiping is the quick path on a phone, but a hidden gesture alone is easy
  /// to miss, so a long press offers the same action.
  Future<void> _showActionSheet(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: cs.error),
          title: Text(m.shopping.deleteTrip, style: TextStyle(color: cs.error)),
          onTap: () => Navigator.pop(ctx, 'delete'),
        ),
      ),
    );
    if (selected != null) _onMenuSelected(selected);
  }

  /// Human trip duration (createdAt → closedAt), or null when still open.
  String? get _duration {
    final closed = row.closedAt;
    if (closed == null) return null;
    final secs = closed - row.createdAt;
    if (secs < 60) return '${secs < 0 ? 0 : secs}s';
    final mins = (secs / 60).round();
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = formatCurrencyAmounts(row.grandTotal);
    final when = row.closedAt ?? row.createdAt;
    final duration = _duration;
    final timeLabel = duration == null
        ? formatDate(when)
        : '${formatDate(when)} · $duration';
    final desktopMenu = onDelete != null && !PlatformInfo.isMobile;

    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete != null && PlatformInfo.isMobile
            ? () => _showActionSheet(context)
            : null,
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(
                userId: row.userId,
                displayName: memberName ?? row.userId,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StorePath(stores: row.stores),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Chip(icon: Icons.schedule, label: timeLabel),
                        _Chip(
                          icon: Icons.check_circle_outline,
                          label: m.shopping.itemsCount(row.itemCount),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: AppSurfaces.of(context).chip(selected: true),
                child: Text(
                  total ?? '—',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (desktopMenu) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: _onMenuSelected,
                  itemBuilder: _menuItems,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!desktopMenu) return card;
    return ContextMenuRegion<String>(
      itemBuilder: () => _menuItems(context),
      onSelected: _onMenuSelected,
      child: card,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
      ),
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.shopping.deleteTrip,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onErrorContainer,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: cs.onErrorContainer),
        ],
      ),
    );
  }
}

/// The store visit path ("A → B → C") rendered with Material arrow icons
/// between store names, or the "no store" label when the trip was storeless.
class _StorePath extends StatelessWidget {
  final List<String> stores;

  const _StorePath({required this.stores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (stores.isEmpty) {
      return Text(m.shopping.noStorePath, style: theme.textTheme.titleSmall);
    }
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < stores.length; i++) ...[
          if (i > 0)
            Icon(
              Icons.arrow_right_alt,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          Text(
            stores[i],
            textDirection: detectTextDirection(stores[i]),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: AppSurfaces.of(context).chip(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }
}
