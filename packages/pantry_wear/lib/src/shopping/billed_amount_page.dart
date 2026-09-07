import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/currencies.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../widgets/wear_choice_page.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';

/// What a till charged, typed on the wrist.
///
/// The one field in the app that accepts input, and the argument for it is that
/// a total is a number: the exclusion this narrows was about prose and
/// credentials, neither of which a till produces. Wear's own IME opens in its
/// numeric mode, so nothing here is a keyboard of our own.
///
/// Pops the figure and the currency it is in, or nothing when the wearer backs
/// out. An emptied field is a figure too — it clears the total.
class BilledAmountPage extends StatefulWidget {
  /// Whose till, drawn above the field so the number has a name.
  final String storeName;

  final double? total;
  final String currency;

  const BilledAmountPage({
    super.key,
    required this.storeName,
    required this.total,
    required this.currency,
  });

  @override
  State<BilledAmountPage> createState() => _BilledAmountPageState();
}

/// What [BilledAmountPage] pops: the amount, or null to clear it, in the
/// currency the wearer left selected.
typedef BilledAmount = ({double? total, String currency});

class _BilledAmountPageState extends State<BilledAmountPage> {
  late final TextEditingController _field = TextEditingController(
    text: _initialText,
  );
  late String _currency = widget.currency;

  String get _initialText {
    final total = widget.total;
    if (total == null) return '';
    final decimals = resolveCurrency(widget.currency).decimals;
    final rounded = double.parse(total.toStringAsFixed(decimals));
    return rounded == rounded.truncateToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// A comma is the decimal separator on most of the keyboards this field
  /// opens under, and a total typed with one is not a total the page may
  /// silently discard.
  double? get _parsed {
    final text = _field.text.trim().replaceAll(',', '.');
    return text.isEmpty ? null : double.tryParse(text);
  }

  bool get _valid => _field.text.trim().isEmpty || _parsed != null;

  Future<void> _pickCurrency() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WearChoicePage<String>(
          choices: [
            for (final currency in currencies)
              WearChoice(
                value: currency.code,
                label: '${currency.code} ${currency.symbol}',
              ),
          ],
          selected: _currency,
          empty: '',
          onSelected: (code) async {
            if (mounted) setState(() => _currency = code);
          },
        ),
      ),
    );
  }

  void _save() => Navigator.of(
    context,
  ).pop<BilledAmount>((total: _parsed, currency: _currency));

  @override
  Widget build(BuildContext context) {
    final currency = resolveCurrency(_currency);
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.only(
                    start: 16,
                    end: 16,
                    top: constraints.maxHeight * 0.18,
                    bottom: constraints.maxHeight * 0.34,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textDirection: detectTextDirection(widget.storeName),
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.1,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _field,
                        autofocus: true,
                        // Numbers read left to right in every locale the app
                        // ships, so the field does not follow the layout.
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _save(),
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: currency.symbol,
                          hintStyle: const TextStyle(
                            fontSize: 26,
                            height: 1.1,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: WearMetrics.cardHeight,
                        child: WearRow(
                          icon: Icons.payments_outlined,
                          label: m.wear.currency,
                          value: '${currency.code} ${currency.symbol}',
                          onTap: () => unawaited(_pickCurrency()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearCta.insetFor(constraints.maxHeight),
                child: WearCta(
                  key: const ValueKey('save-billed'),
                  icon: Icons.check,
                  label: m.common.save,
                  reason: _valid ? null : m.wear.notANumber,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
