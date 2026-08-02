import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces Shopping Mode. Shows a mock of the dense shopping screen — a
/// store bar with the active store, an "in cart" progress row, and a couple of
/// category-grouped rows (one already checked) — so users recognise the
/// walk-the-aisles flow. Always shown; when the server doesn't report the
/// `shopping` capability, a footnote spells out the Pantry version it needs.
class ShoppingModeOnboardingPage extends StatelessWidget {
  const ShoppingModeOnboardingPage({super.key});

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
            ob.shoppingIntroTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.shoppingIntroBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _MockShoppingCard(),
          const ServerRequirementNote(
            feature: 'shopping',
            requiredVersion: '0.25.0',
          ),
        ],
      ),
    );
  }
}

/// A compact, non-interactive facsimile of the dense shopping screen.
class _MockShoppingCard extends StatelessWidget {
  const _MockShoppingCard();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Store bar: active store filled, next store dimmed.
          Row(
            children: [
              _StorePill(
                label: m.onboarding.shoppingMockStoreActive,
                active: true,
              ),
              const SizedBox(width: 8),
              _StorePill(
                label: m.onboarding.shoppingMockStoreNext,
                active: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress row: "in cart" + bar.
          Row(
            children: [
              Text(
                m.shopping.inCart(3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Category header + item rows.
          _CategoryHeader(label: m.onboarding.mockItemCategory),
          _ItemRow(label: m.onboarding.mockBulkItemThird, checked: false),
          _ItemRow(label: m.onboarding.mockItemName, checked: true),
        ],
      ),
    );
  }
}

class _StorePill extends StatelessWidget {
  final String label;
  final bool active;

  const _StorePill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: active ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront,
              size: 15,
              color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;

  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String label;
  final bool checked;

  const _ItemRow({required this.label, required this.checked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: checked ? Colors.green : cs.outline,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: checked ? cs.onSurfaceVariant : cs.onSurface,
              decoration: checked ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
