import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Demonstrates the new bottom compose bar at a glance. Renders a mocked-up
/// bar — chip row + input row with the gradient send button — so users
/// recognize it the next time they see it without explaining each chip.
class AddItemsOnboardingPage extends StatelessWidget {
  const AddItemsOnboardingPage({super.key});

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
            ob.addItemsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.addItemsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _MockComposeBar(listName: ob.mockComposeListName),
        ],
      ),
    );
  }
}

class _MockComposeBar extends StatelessWidget {
  final String listName;

  const _MockComposeBar({required this.listName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MockChip(
                  label: m.checklists.compose.chipCategory,
                  icon: Icons.label_outline,
                ),
                const SizedBox(width: 8),
                _MockChip(
                  label: m.checklists.compose.chipQuantity,
                  icon: Icons.format_list_numbered,
                ),
                const SizedBox(width: 8),
                _MockChip(
                  label: m.checklists.compose.chipType,
                  icon: Icons.cached,
                ),
                const SizedBox(width: 8),
                _MockChip(
                  label: m.checklists.compose.chipImage,
                  icon: Icons.image_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MockBar(placeholder: m.checklists.addToList(listName)),
        ],
      ),
    );
  }
}

class _MockChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MockChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBar extends StatelessWidget {
  final String placeholder;

  const _MockBar({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.primary, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.add, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              placeholder,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
