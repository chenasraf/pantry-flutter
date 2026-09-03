import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces list-scoped categories: a mock of the category "List" selector
/// (as it appears in the create/edit dialog) plus two captioned rows showing
/// the two scopes — global (every list) and a single list. Always shown; a
/// footnote names the required Pantry version when the server lacks the
/// `category-lists` capability.
class CategoryScopeOnboardingPage extends StatelessWidget {
  const CategoryScopeOnboardingPage({super.key});

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
            ob.categoryScopeTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.categoryScopeBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _MockScopeField(),
          const SizedBox(height: 16),
          _ScopeRow(
            icon: Icons.public,
            label: m.categories.globalList,
            caption: ob.categoryScopeGlobalCaption,
          ),
          const SizedBox(height: 10),
          _ScopeRow(
            icon: Icons.check_circle_outline,
            label: ob.mockListGroceries,
            caption: ob.categoryScopeScopedCaption,
          ),
          const ServerRequirementNote(
            feature: 'category-lists',
            requiredVersion: '0.28.0',
          ),
        ],
      ),
    );
  }
}

/// A non-interactive version of the create-category dialog's "List" dropdown,
/// scoped to a single list.
class _MockScopeField extends StatelessWidget {
  const _MockScopeField();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border.all(color: cs.primary, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.categories.list.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  m.onboarding.mockListGroceries,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

/// A scope option row: an icon, the scope label, and a one-line caption.
class _ScopeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;

  const _ScopeRow({
    required this.icon,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: cs.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
