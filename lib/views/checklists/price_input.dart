import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/currencies.dart';

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

  /// Seed from an existing item, falling back to [fallbackCurrency] (the
  /// house's last-used currency) when the item carries none.
  factory PriceDraft.fromItem(
    ListItem item, {
    required String fallbackCurrency,
  }) {
    final type = item.priceType;
    final hasPrice =
        (type == 'set' || type == 'range') && item.priceMin != null;
    return PriceDraft(
      isRange: type == 'range',
      minText: hasPrice ? _seedAmount(item.priceMin!) : '',
      maxText: type == 'range' && item.priceMax != null
          ? _seedAmount(item.priceMax!)
          : '',
      currency: item.priceCurrency ?? fallbackCurrency,
    );
  }

  double? get _min => _parseAmount(minText);
  double? get _max => _parseAmount(maxText);

  /// Whether the draft carries a usable price (a parseable min amount).
  bool get hasPrice => _min != null;

  /// priceType to send on **create** — null when there's no price.
  String? get createPriceType => hasPrice ? (isRange ? 'range' : 'set') : null;

  /// priceType to send on **update** — `''` clears when there's no price,
  /// otherwise `'set'`/`'range'`. Always send the full group on edit.
  String get updatePriceType => hasPrice ? (isRange ? 'range' : 'set') : '';

  double? get priceMin => hasPrice ? _min : null;
  double? get priceMax => hasPrice && isRange ? _max : null;
  String? get priceCurrency => hasPrice ? currency : null;
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
