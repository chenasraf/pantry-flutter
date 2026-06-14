import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Desktop counterpart to `SwipeActionsOnboardingPage`. Where the mobile flow
/// teaches a gesture, this one explains that action buttons live permanently
/// at the trailing edge of every row. No animation needed — the mock just
/// shows the steady-state layout the user will encounter.
class QuickActionsOnboardingPage extends StatelessWidget {
  const QuickActionsOnboardingPage({super.key});

  static const double _actionWidth = 62;

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
            ob.quickActionsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.quickActionsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: _MockListItem()),
                  _PinnedActionButton(
                    width: _actionWidth,
                    icon: Icons.edit_outlined,
                    label: m.checklists.swipeEdit,
                    tint: cs.onSurfaceVariant,
                    background: Color.alphaBlend(
                      cs.onSurface.withValues(alpha: 0.07),
                      cs.surface,
                    ),
                  ),
                  _PinnedActionButton(
                    width: _actionWidth,
                    icon: Icons.drive_file_move_outlined,
                    label: m.checklists.swipeMove,
                    tint: const Color(0xFFD9B441),
                    background: Color.alphaBlend(
                      const Color(0xFFD9B441).withValues(alpha: 0.18),
                      cs.surface,
                    ),
                  ),
                  _PinnedActionButton(
                    width: _actionWidth,
                    icon: Icons.delete_outline,
                    label: m.checklists.swipeDelete,
                    tint: const Color(0xFFEF7878),
                    background: Color.alphaBlend(
                      const Color(0xFFEF7878).withValues(alpha: 0.2),
                      cs.surface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedActionButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color tint;
  final Color background;

  const _PinnedActionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.tint,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: background,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: tint, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same shape as the swipe-page mock so the two onboarding pages feel like
/// variants of one explanation. Kept private rather than shared because the
/// two pages diverge as soon as one needs animation hooks.
class _MockListItem extends StatelessWidget {
  const _MockListItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      color: cs.surface,
      child: Row(
        children: [
          _MockCheckbox(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ob.mockItemName,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MockChip(
                      label: ob.mockItemQuantity,
                      color: cs.onSurfaceVariant,
                      background: cs.surfaceContainerHighest,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _MockChip(
                        label: ob.mockItemCategory,
                        color: cs.primary,
                        background: cs.primary.withValues(alpha: 0.14),
                        icon: Icons.local_florist,
                      ),
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

class _MockCheckbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline, width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

class _MockChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const _MockChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
