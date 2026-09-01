import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/views/checklists/price_draft.dart';
import 'package:pantry/views/checklists/price_input.dart';

class SetRangeToggle extends StatelessWidget {
  final bool isRange;
  final String setLabel;
  final String rangeLabel;
  final ValueChanged<bool> onChanged;

  const SetRangeToggle({
    super.key,
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

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const AmountField({super.key, required this.controller, required this.label});

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

class CurrencyDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

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

class StoreLabel extends StatelessWidget {
  final String text;

  const StoreLabel({super.key, required this.text});

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

class StoreRow extends StatelessWidget {
  final StorePriceRow row;
  final List<models.Store> stores;
  final List<models.Store> options;
  final ValueChanged<int> onStoreSelected;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const StoreRow({
    super.key,
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
