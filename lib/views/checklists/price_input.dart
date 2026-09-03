import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry/views/checklists/price_draft.dart';
import 'package:pantry/views/checklists/price_input_fields.dart';

export 'package:pantry/views/checklists/price_draft.dart' show PricesDraft;

/// A Set/Range segmented control, one or two amount fields, and a currency
/// dropdown. Renders bare (no outer card) so callers can host it inside their
/// own section — the full item form and the compose bar's price tray.
class PriceInput extends StatefulWidget {
  final PriceDraft draft;

  /// Called on any change (amount text, toggle, currency) so the host can
  /// rebuild its live preview.
  final VoidCallback onChanged;

  const PriceInput({super.key, required this.draft, required this.onChanged});

  @override
  State<PriceInput> createState() => _PriceInputState();
}

class _PriceInputState extends State<PriceInput> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.draft.minText);
    _maxCtrl = TextEditingController(text: widget.draft.maxText);
    _minCtrl.addListener(() {
      widget.draft.minText = _minCtrl.text;
      widget.onChanged();
    });
    _maxCtrl.addListener(() {
      widget.draft.maxText = _maxCtrl.text;
      widget.onChanged();
    });
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _setRange(bool range) {
    if (widget.draft.isRange == range) return;
    setState(() => widget.draft.isRange = range);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = m.checklists.price;
    final draft = widget.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetRangeToggle(
          isRange: draft.isRange,
          setLabel: p.set,
          rangeLabel: p.range,
          onChanged: _setRange,
        ),
        const SizedBox(height: 10),
        // Amount(s) and currency share one row: [amount][currency] for a set,
        // [min][max][currency] for a range.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (draft.isRange) ...[
              Expanded(
                flex: 3,
                child: AmountField(controller: _minCtrl, label: p.min),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: AmountField(controller: _maxCtrl, label: p.max),
              ),
            ] else
              Expanded(
                flex: 6,
                child: AmountField(controller: _minCtrl, label: p.amount),
              ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: CurrencyDropdown(
                value: draft.currency,
                onChanged: (code) {
                  setState(() => draft.currency = code);
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        if (draft.hasPrice)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                _minCtrl.clear();
                _maxCtrl.clear();
              },
              icon: const Icon(Icons.close, size: 16),
              label: Text(p.clear),
            ),
          ),
      ],
    );
  }
}

/// Editor for an item's prices: a pinned "Any store" row plus an add-row per
/// store. Mirrors the web app's `ItemPricesEditor`. Renders bare so callers can
/// host it inside their own section (the item form and the compose bar tray).
class ItemPricesEditor extends StatefulWidget {
  final PricesDraft draft;

  /// Stores offered for per-store rows. Empty (and the add button hidden) when
  /// the server lacks the `stores` capability.
  final List<models.Store> stores;

  /// Whether the server advertises `item-price-per-store`. When false the editor
  /// collapses to just the store-less price input (the legacy single-price UI):
  /// no "Any store" label, per-store rows, or add button.
  final bool perStoreEnabled;

  /// Called on any change so the host can rebuild its live preview.
  final VoidCallback onChanged;

  const ItemPricesEditor({
    super.key,
    required this.draft,
    required this.stores,
    required this.perStoreEnabled,
    required this.onChanged,
  });

  @override
  State<ItemPricesEditor> createState() => _ItemPricesEditorState();
}

class _ItemPricesEditorState extends State<ItemPricesEditor> {
  List<models.Store> get _stores => widget.stores;

  /// Stores not already claimed by a per-store row.
  List<models.Store> get _availableStores {
    final used = widget.draft.rows.map((r) => r.storeId).toSet();
    return [
      for (final s in _stores)
        if (!used.contains(s.id)) s,
    ];
  }

  void _addRow() {
    final next = _availableStores.isNotEmpty ? _availableStores.first : null;
    if (next == null) return;
    setState(() {
      widget.draft.rows.add(
        StorePriceRow(
          storeId: next.id,
          draft: PriceDraft(currency: widget.draft.defaultCurrency),
        ),
      );
    });
    widget.onChanged();
  }

  void _removeRow(int index) {
    setState(() => widget.draft.rows.removeAt(index));
    widget.onChanged();
  }

  void _selectStore(int index, int storeId) {
    setState(() => widget.draft.rows[index].storeId = storeId);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    // Legacy single-price servers: just the store-less input, nothing else.
    if (!widget.perStoreEnabled) {
      return PriceInput(
        draft: widget.draft.storeless,
        onChanged: widget.onChanged,
      );
    }
    final p = m.checklists.price;
    final rows = widget.draft.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoreLabel(text: p.anyStore),
        const SizedBox(height: 8),
        PriceInput(draft: widget.draft.storeless, onChanged: widget.onChanged),
        for (var i = 0; i < rows.length; i++) ...[
          const SizedBox(height: 14),
          StoreRow(
            row: rows[i],
            stores: _stores,
            // A row may keep its own store plus any not used elsewhere.
            options: [
              for (final s in _stores)
                if (s.id == rows[i].storeId ||
                    _availableStores.any((a) => a.id == s.id))
                  s,
            ],
            onStoreSelected: (id) => _selectStore(i, id),
            onRemove: () => _removeRow(i),
            onChanged: widget.onChanged,
          ),
        ],
        if (_stores.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _availableStores.isEmpty ? null : _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: Text(p.addPrice),
            ),
          ),
        ],
      ],
    );
  }
}
