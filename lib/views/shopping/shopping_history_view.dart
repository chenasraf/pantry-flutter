import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/shopping_estimate.dart';
import 'package:pantry/models/shopping_history_row.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/services/store_service.dart';
import 'package:pantry/utils/date_format.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/shopping/shopping_review_view.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/member_avatar.dart';

/// Read-only list of closed trips (Phase 3). A Mine/House scope toggle selects
/// which trips are shown; tapping a row opens its read-only per-store summary.
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
  final List<ShoppingHistoryRow> _rows = [];
  Map<int, Store> _stores = {};
  Map<String, String> _memberNames = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShoppingReviewView(
          houseId: widget.houseId,
          sessionId: row.id,
          mode: ShoppingReviewMode.history,
          stores: _stores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.shopping.historyTitle),
      ),
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
          return _HistoryCard(
            row: _rows[index],
            memberName: _memberNames[_rows[index].userId],
            onTap: () => _openSummary(_rows[index]),
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

  const _HistoryCard({
    required this.row,
    required this.memberName,
    required this.onTap,
  });

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  total ?? '—',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
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
