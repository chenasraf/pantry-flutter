import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/shopping_estimate.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/models/shopping_review.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/shopping/shopping_reminder_block.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// Which review the screen renders. [advance] shows only the store being left
/// (a till summary before moving on); [close] shows the whole trip with
/// editable totals and a confirm to finish; [history] is a read-only past trip.
enum ShoppingReviewMode { advance, close, history }

/// Full-screen review of a trip. Loads `…/review` (live) or `…/summary`
/// (history). Pops `true` when the user confirms the transition (advance /
/// finish); billed-total edits are persisted independently as they happen.
class ShoppingReviewView extends StatefulWidget {
  final int houseId;
  final int sessionId;
  final ShoppingReviewMode mode;

  /// The active store being left, for [ShoppingReviewMode.advance] narrowing.
  final int? activeStoreId;
  final Map<int, Store> stores;

  /// Reminders for the moment surfaced at the top (advance → on_store_advance,
  /// close → on_close). Already filtered to enabled and ordered.
  final List<ShoppingReminder> reminders;
  final VoidCallback? onManageReminders;

  const ShoppingReviewView({
    super.key,
    required this.houseId,
    required this.sessionId,
    required this.mode,
    required this.stores,
    this.activeStoreId,
    this.reminders = const [],
    this.onManageReminders,
  });

  @override
  State<ShoppingReviewView> createState() => _ShoppingReviewViewState();
}

class _ShoppingReviewViewState extends State<ShoppingReviewView> {
  ShoppingService get _service => ShoppingService.instance;
  bool get _readOnly => widget.mode == ShoppingReviewMode.history;

  ShoppingReview? _review;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final review = widget.mode == ShoppingReviewMode.history
          ? await _service.getSummary(widget.houseId, widget.sessionId)
          : await _service.getReview(widget.houseId, widget.sessionId);
      if (!mounted) return;
      setState(() {
        _review = review;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = m.shopping.loadFailed;
      });
    }
  }

  /// The store groups to render. In advance mode, only the store being left.
  List<ShoppingReviewStore> get _visibleStores {
    final all = _review?.stores ?? const [];
    if (widget.mode != ShoppingReviewMode.advance) return all;
    return all.where((s) => s.storeId == widget.activeStoreId).toList();
  }

  Future<void> _saveBilled(
    ShoppingReviewStore store,
    double? total,
    String currency,
  ) async {
    try {
      if (store.storeId == null) {
        await _service.setSessionBilled(
          widget.houseId,
          widget.sessionId,
          billedTotal: total,
          billedCurrency: total == null ? null : currency,
        );
      } else {
        await _service.setStoreBilled(
          widget.houseId,
          widget.sessionId,
          store.storeId!,
          billedTotal: total,
          billedCurrency: total == null ? null : currency,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.shopping.saveTotalFailed)));
    }
  }

  String get _title => switch (widget.mode) {
    ShoppingReviewMode.advance => m.shopping.advanceTitle,
    ShoppingReviewMode.close => m.shopping.reviewTitle,
    ShoppingReviewMode.history => m.shopping.reviewTitle,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: appBarBackLeading(context), title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRetry(message: _error!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ShoppingReminderBlock(
                  reminders: widget.reminders,
                  onManage: widget.onManageReminders,
                ),
                const SizedBox(height: 16),
                for (final store in _visibleStores) ...[
                  _StoreSection(
                    store: store,
                    storeName: _storeName(store.storeId),
                    storeColor: _storeColor(store.storeId),
                    storeIconData: _storeIcon(store.storeId),
                    readOnly: _readOnly,
                    onSaveBilled: (total, currency) =>
                        _saveBilled(store, total, currency),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.mode != ShoppingReviewMode.advance)
                  _GrandTotal(review: _review!),
              ],
            ),
      bottomNavigationBar: _readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(m.common.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(true),
                        icon: Icon(
                          widget.mode == ShoppingReviewMode.advance
                              ? Icons.arrow_forward
                              : Icons.flag,
                        ),
                        label: Text(
                          widget.mode == ShoppingReviewMode.advance
                              ? m.shopping.nextStore
                              : m.shopping.finishTrip,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  String _storeName(int? storeId) {
    if (storeId == null) return m.shopping.anyStore;
    return widget.stores[storeId]?.name ?? m.shopping.anyStore;
  }

  Color? _storeColor(int? storeId) =>
      storeId == null ? null : parseHexColor(widget.stores[storeId]?.color);

  IconData _storeIcon(int? storeId) =>
      storeIcon(storeId == null ? null : widget.stores[storeId]?.icon);
}

class _StoreSection extends StatefulWidget {
  final ShoppingReviewStore store;
  final String storeName;
  final Color? storeColor;
  final IconData storeIconData;
  final bool readOnly;
  final void Function(double? total, String currency) onSaveBilled;

  const _StoreSection({
    required this.store,
    required this.storeName,
    required this.storeColor,
    required this.storeIconData,
    required this.readOnly,
    required this.onSaveBilled,
  });

  @override
  State<_StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends State<_StoreSection> {
  late final TextEditingController _billedCtrl;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final billed = widget.store.billedTotal;
    _billedCtrl = TextEditingController(
      text: billed == null ? '' : _trim(billed),
    );
    _currency =
        widget.store.billedCurrency ??
        (widget.store.estimate.isNotEmpty
            ? widget.store.estimate.first.currency
            : defaultCurrency);
  }

  static String _trim(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _billedCtrl.dispose();
    super.dispose();
  }

  void _persist() {
    final raw = _billedCtrl.text.trim().replaceAll(',', '.');
    final parsed = raw.isEmpty ? null : double.tryParse(raw);
    widget.onSaveBilled(parsed, _currency);
  }

  /// The bare estimate figure(s) used as the billed field's placeholder.
  String get _estimateHint {
    final est = widget.store.estimate;
    if (est.isEmpty) return '';
    final r = est.first;
    return r.min == r.max ? _trim(r.min) : '${_trim(r.min)}–${_trim(r.max)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final store = widget.store;
    final estimateLabel = formatShoppingEstimate(store.estimate);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.storeIconData,
                  color: widget.storeColor ?? cs.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.storeName,
                    textDirection: detectTextDirection(widget.storeName),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (estimateLabel != null)
                  Text(
                    estimateLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in store.items) _ReviewItemRow(item: item),
            if (store.noPriceCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  m.shopping.itemsWithoutPrice(store.noPriceCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _billedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: m.shopping.actualPaid,
                        hintText: _estimateHint,
                        border: const OutlineInputBorder(),
                      ),
                      onTapOutside: (_) => _persist(),
                      onEditingComplete: _persist,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        // Keep an unknown server-supplied code selectable so
                        // the dropdown's value always matches exactly one item.
                        if (currencyByCode(_currency) == null)
                          DropdownMenuItem(
                            value: _currency,
                            child: Text(
                              _currency,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        for (final c in currencies)
                          DropdownMenuItem(
                            value: c.code,
                            child: Text(
                              '${c.code} ${c.symbol}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _currency = v);
                        _persist();
                      },
                    ),
                  ),
                ],
              ),
            ] else if (store.billedTotal != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.shopping.actualPaid,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyAmount(
                        currency: store.billedCurrency ?? defaultCurrency,
                        amount: store.billedTotal!,
                      ).label,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewItemRow extends StatelessWidget {
  final ListItem item;

  const _ReviewItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = item.formattedPrice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              textDirection: detectTextDirection(item.name),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (price != null)
            Text(
              price,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [],
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _GrandTotal extends StatelessWidget {
  final ShoppingReview review;

  const _GrandTotal({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = formatShoppingEstimate(review.grandTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(m.shopping.grandTotal, style: theme.textTheme.titleMedium),
            Text(
              total ?? '—',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (review.uncheckedCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              m.shopping.itemsStillUnchecked(review.uncheckedCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
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
