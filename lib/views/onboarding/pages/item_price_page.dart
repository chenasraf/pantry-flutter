import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces item prices: a mock item row with a price chip above a simplified
/// price input (Set/Range toggle, amount, currency), so users recognise both
/// what a price looks like and how to set one. Always shown; a footnote names
/// the required Pantry version when the server lacks the `item-price` capability.
class ItemPriceOnboardingPage extends StatelessWidget {
  const ItemPriceOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.priceTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.priceBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _MockItemRow(),
          const SizedBox(height: 16),
          const _MockPriceInput(),
          const ServerRequirementNote(
            feature: 'item-price',
            requiredVersion: '0.24.0',
          ),
        ],
      ),
    );
  }
}

/// A mock item card with a price chip called out beside a category chip.
class _MockItemRow extends StatelessWidget {
  const _MockItemRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.onboarding.priceMockName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  children: [
                    _Chip(
                      leading: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: m.onboarding.barcodeScanMockCategory,
                      textColor: cs.primary,
                      background: cs.primary.withValues(alpha: 0.13),
                    ),
                    _Chip(
                      leading: Icon(
                        Icons.sell_outlined,
                        size: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      label: r'$8-12',
                      textColor: cs.onSurfaceVariant,
                      background: cs.onSurface.withValues(alpha: 0.06),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simplified, non-interactive version of the real price input: the
/// Set/Range toggle (Range selected), an amount, and a currency.
class _MockPriceInput extends StatelessWidget {
  const _MockPriceInput();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = m.checklists.price;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Segment(label: p.set, selected: false)),
              const SizedBox(width: 8),
              Expanded(child: _Segment(label: p.range, selected: true)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _FakeField(text: '8', label: p.min),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _FakeField(text: '12', label: p.max),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _FakeField(text: r'USD ($)', label: p.currency),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;

  const _Segment({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}

class _FakeField extends StatelessWidget {
  final String text;
  final String label;

  const _FakeField({required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill chip mirroring the item-row meta chips.
class _Chip extends StatelessWidget {
  final Widget leading;
  final String label;
  final Color textColor;
  final Color background;

  const _Chip({
    required this.leading,
    required this.label,
    required this.textColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
