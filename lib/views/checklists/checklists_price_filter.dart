import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/currencies.dart';
import 'package:pantry/utils/entity_icons.dart';
import 'package:pantry/utils/price.dart';
import 'checklists_filter_bar.dart';

/// The price filter: a dropdown whose panel holds a min/max amount range and a
/// currency selector ("Any currency" compares amounts verbatim across
/// currencies). The trigger summarises the active range, e.g. "$1-10", "≥1".
class ChecklistsPriceFilterDropdown extends StatefulWidget {
  final PriceFilter value;
  final ValueChanged<PriceFilter> onChanged;

  const ChecklistsPriceFilterDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ChecklistsPriceFilterDropdown> createState() =>
      _ChecklistsPriceFilterDropdownState();
}

class _ChecklistsPriceFilterDropdownState
    extends State<ChecklistsPriceFilterDropdown> {
  static const _anyCurrency = '__any__';
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  // Guards against re-seeding the fields when the parent echoes our own emit
  // back (which would drop a trailing "." mid-decimal).
  PriceFilter? _lastEmitted;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: _fmt(widget.value.min));
    _maxCtrl = TextEditingController(text: _fmt(widget.value.max));
  }

  @override
  void didUpdateWidget(ChecklistsPriceFilterDropdown old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (_lastEmitted != null &&
        v.min == _lastEmitted!.min &&
        v.max == _lastEmitted!.max &&
        v.currency == _lastEmitted!.currency) {
      return;
    }
    _minCtrl.text = _fmt(v.min);
    _maxCtrl.text = _fmt(v.max);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  static String _fmt(double? v) {
    if (v == null) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  static double? _parse(String text) {
    final cleaned = text.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final n = double.tryParse(cleaned);
    if (n == null || n < 0) return null;
    return n;
  }

  void _emit({String? currency, bool clearCurrency = false}) {
    final next = PriceFilter(
      min: _parse(_minCtrl.text),
      max: _parse(_maxCtrl.text),
      currency: clearCurrency ? null : (currency ?? widget.value.currency),
    );
    _lastEmitted = next;
    widget.onChanged(next);
  }

  void _clear() {
    _minCtrl.clear();
    _maxCtrl.clear();
    _emit(clearCurrency: true);
  }

  String _triggerLabel() {
    final f = widget.value;
    if (!f.isActive) return m.checklists.filters.price;
    final sym = f.currency != null ? resolveCurrency(f.currency).symbol : '';
    final lo = _fmt(f.min);
    final hi = _fmt(f.max);
    final String range;
    if (lo.isNotEmpty && hi.isNotEmpty) {
      range = '$lo-$hi';
    } else if (lo.isNotEmpty) {
      range = '≥$lo';
    } else if (hi.isNotEmpty) {
      range = '≤$hi';
    } else {
      // Currency-only: the symbol alone carries the filter.
      return sym.isNotEmpty ? sym : (f.currency ?? m.checklists.filters.price);
    }
    return sym.isNotEmpty ? '$sym$range' : range;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = m.checklists.price;
    final active = widget.value.isActive;
    final currency = widget.value.currency;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 268,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PriceFilterField(
                        controller: _minCtrl,
                        label: p.min,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PriceFilterField(
                        controller: _maxCtrl,
                        label: p.max,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: p.currency,
                    isDense: true,
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      12,
                      12,
                      8,
                      12,
                    ),
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
                      value: currency == null
                          ? _anyCurrency
                          : (currencyByCode(currency) != null
                                ? currency.toUpperCase()
                                : _anyCurrency),
                      isExpanded: true,
                      isDense: true,
                      items: [
                        DropdownMenuItem<String>(
                          value: _anyCurrency,
                          child: Text(
                            m.checklists.filters.anyCurrency,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                        if (code == null || code == _anyCurrency) {
                          _emit(clearCurrency: true);
                        } else {
                          _emit(currency: code);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: active ? _clear : null,
                    child: Text(m.common.clear),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => ChecklistsFilterButton(
        label: _triggerLabel(),
        icon: EntityIcons.price,
        active: active,
        open: controller.isOpen,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _PriceFilterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _PriceFilterField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
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
