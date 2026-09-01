import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/color.dart';

/// Format a stored amount for seeding an input field: trim trailing zeros so a
/// round number shows as "1" (not "1.00") and "9.99" stays "9.99".
String _seedAmount(double amount) {
  if (amount == amount.truncateToDouble()) return amount.toInt().toString();
  return amount.toString();
}

double? _parseAmount(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Mutable draft backing the [PriceInput] widget. The Set/Range selection is
/// kept as local UI state ([isRange]) rather than derived from the amounts, so
/// switching to Range with an empty field doesn't snap back to Set.
class PriceDraft {
  bool isRange;
  String minText;
  String maxText;
  String currency;

  PriceDraft({
    this.isRange = false,
    this.minText = '',
    this.maxText = '',
    this.currency = defaultCurrency,
  });

  /// Seed from a single [ItemPrice] entry (or null for an empty row), falling
  /// back to [fallbackCurrency] (the house's last-used currency) when the entry
  /// carries no currency.
  factory PriceDraft.fromItemPrice(
    ItemPrice? price, {
    required String fallbackCurrency,
  }) {
    final type = price?.priceType;
    final hasPrice =
        (type == 'set' || type == 'range') && price?.priceMin != null;
    return PriceDraft(
      isRange: type == 'range',
      minText: hasPrice ? _seedAmount(price!.priceMin!) : '',
      maxText: type == 'range' && price?.priceMax != null
          ? _seedAmount(price!.priceMax!)
          : '',
      currency: price?.priceCurrency ?? fallbackCurrency,
    );
  }

  double? get _min => _parseAmount(minText);
  double? get _max => _parseAmount(maxText);

  /// Whether the draft carries a usable price (a parseable min amount).
  bool get hasPrice => _min != null;

  /// priceType this draft represents, or null when there's no price.
  String? get priceType => hasPrice ? (isRange ? 'range' : 'set') : null;

  double? get priceMin => hasPrice ? _min : null;
  double? get priceMax => hasPrice && isRange ? _max : null;
  String? get priceCurrency => hasPrice ? currency : null;

  /// Compose this draft into an [ItemPrice] for [storeId], or null when the
  /// draft carries no usable amount.
  ItemPrice? toItemPrice(int? storeId) {
    if (!hasPrice) return null;
    return ItemPrice(
      storeId: storeId,
      priceType: priceType,
      priceMin: priceMin,
      priceMax: priceMax,
      priceCurrency: priceCurrency,
    );
  }
}

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
        _SetRangeToggle(
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
                child: _AmountField(controller: _minCtrl, label: p.min),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _AmountField(controller: _maxCtrl, label: p.max),
              ),
            ] else
              Expanded(
                flex: 6,
                child: _AmountField(controller: _minCtrl, label: p.amount),
              ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _CurrencyDropdown(
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

class _SetRangeToggle extends StatelessWidget {
  final bool isRange;
  final String setLabel;
  final String rangeLabel;
  final ValueChanged<bool> onChanged;

  const _SetRangeToggle({
    required this.isRange,
    required this.setLabel,
    required this.rangeLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget seg(String label, bool range) {
      final selected = isRange == range;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(range),
          borderRadius: BorderRadius.circular(9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg(setLabel, false),
        const SizedBox(width: 8),
        seg(rangeLabel, true),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _AmountField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // The stored value may be an unknown code; keep it selectable so the
    // dropdown has a valid current item instead of asserting.
    final known = currencyByCode(value);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: m.checklists.price.currency,
        isDense: true,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: known != null ? value.toUpperCase() : null,
          isExpanded: true,
          isDense: true,
          hint: Text(value),
          items: [
            for (final c in currencies)
              DropdownMenuItem<String>(
                value: c.code,
                child: Text(
                  '${c.code} (${c.symbol})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (code) {
            if (code != null) onChanged(code);
          },
        ),
      ),
    );
  }
}

/// One per-store price row within a [PricesDraft]. [key] is a stable identity so
/// the row's [PriceInput] keeps its text controllers as rows are added/removed.
class StorePriceRow {
  static int _nextKey = 0;

  final int key;
  int storeId;
  final PriceDraft draft;

  StorePriceRow({required this.storeId, required this.draft})
    : key = _nextKey++;
}

/// Mutable draft for an item's full set of prices: a store-less (default) price
/// plus zero or more per-store rows. Mirrors the web app's `ItemPricesEditor`
/// model. Compose into the wire shape with [toItemPrices].
class PricesDraft {
  final PriceDraft storeless;
  final List<StorePriceRow> rows;
  final String defaultCurrency;

  PricesDraft({
    required this.storeless,
    required this.rows,
    required this.defaultCurrency,
  });

  factory PricesDraft.empty(String currency) => PricesDraft(
    storeless: PriceDraft(currency: currency),
    rows: [],
    defaultCurrency: currency,
  );

  /// Seed from an existing item, falling back to [fallbackCurrency] where an
  /// entry carries no currency.
  factory PricesDraft.fromItem(
    ListItem item, {
    required String fallbackCurrency,
  }) {
    final rows = [
      for (final p in item.prices)
        if (p.storeId != null)
          StorePriceRow(
            storeId: p.storeId!,
            draft: PriceDraft.fromItemPrice(
              p,
              fallbackCurrency: fallbackCurrency,
            ),
          ),
    ];
    return PricesDraft(
      storeless: PriceDraft.fromItemPrice(
        storelessPrice(item.prices),
        fallbackCurrency: fallbackCurrency,
      ),
      rows: rows,
      defaultCurrency: fallbackCurrency,
    );
  }

  /// Whether any price (store-less or per-store) carries a usable amount.
  bool get hasAnyPrice =>
      storeless.hasPrice || rows.any((r) => r.draft.hasPrice);

  /// Currency worth remembering for the next new item: the store-less price's
  /// currency when set, else the first priced row's, else null.
  String? get rememberCurrency {
    if (storeless.hasPrice) return storeless.currency;
    for (final r in rows) {
      if (r.draft.hasPrice) return r.draft.currency;
    }
    return null;
  }

  /// Compose into the wire list, dropping rows without a usable amount. Safe to
  /// send as the `prices` param on create/update (empty clears all prices).
  List<ItemPrice> toItemPrices() {
    final out = <ItemPrice>[];
    final s = storeless.toItemPrice(null);
    if (s != null) out.add(s);
    for (final r in rows) {
      final p = r.draft.toItemPrice(r.storeId);
      if (p != null) out.add(p);
    }
    return out;
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
        _StoreLabel(text: p.anyStore),
        const SizedBox(height: 8),
        PriceInput(draft: widget.draft.storeless, onChanged: widget.onChanged),
        for (var i = 0; i < rows.length; i++) ...[
          const SizedBox(height: 14),
          _StoreRow(
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

class _StoreLabel extends StatelessWidget {
  final String text;

  const _StoreLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  final StorePriceRow row;
  final List<models.Store> stores;
  final List<models.Store> options;
  final ValueChanged<int> onStoreSelected;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _StoreRow({
    required this.row,
    required this.stores,
    required this.options,
    required this.onStoreSelected,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StoreSelect(
                value: row.storeId,
                options: options,
                onChanged: onStoreSelected,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              tooltip: m.checklists.price.removePrice,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        PriceInput(
          key: ValueKey('price-row-${row.key}'),
          draft: row.draft,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StoreSelect extends StatelessWidget {
  final int value;
  final List<models.Store> options;
  final ValueChanged<int> onChanged;

  const _StoreSelect({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectable = options.any((s) => s.id == value);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: m.checklists.price.store,
        isDense: true,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(12, 12, 8, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectable ? value : null,
          isExpanded: true,
          isDense: true,
          items: [
            for (final s in options)
              DropdownMenuItem<int>(
                value: s.id,
                child: Row(
                  children: [
                    Icon(
                      storeIcon(s.icon),
                      size: 16,
                      color: parseHexColor(s.color) ?? cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
      ),
    );
  }
}
