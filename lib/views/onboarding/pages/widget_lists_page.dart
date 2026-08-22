import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Tells users that the Pantry home-screen widget shows the lists they choose,
/// picked via the widget's gear, and that they can add several widgets each
/// with its own lists. The "demo" is a stylised mock of the widget; the real
/// widget UX varies per OS and would be wasteful to animate here.
class WidgetListsOnboardingPage extends StatelessWidget {
  const WidgetListsOnboardingPage({super.key});

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
            ob.widgetListsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.widgetListsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _WidgetMock(),
          const SizedBox(height: 24),
          _HowTo(action: ob.widgetListsActionLabel),
        ],
      ),
    );
  }
}

/// Stylised home-screen widget tile — header bar (with the gear) + two list
/// rows so the user recognises what they're looking at on their launcher.
class _WidgetMock extends StatelessWidget {
  const _WidgetMock();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ob = m.onboarding;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.list_alt, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ob.widgetListsWidgetTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.settings, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          _WidgetRow(name: ob.mockListGroceries, leftCount: 4),
          const SizedBox(height: 6),
          _WidgetRow(name: ob.mockListWeekend, leftCount: 0),
        ],
      ),
    );
  }
}

class _WidgetRow extends StatelessWidget {
  final String name;
  final int leftCount;

  const _WidgetRow({required this.name, required this.leftCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ob = m.onboarding;
    final done = leftCount == 0;
    final summary = done
        ? ob.widgetListsWidgetEmpty
        : ob.widgetListsWidgetItemsLeft(leftCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            summary,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: done ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline instruction with the actual gear glyph the user will tap, so reading
/// the words alongside the icon makes the step land without a screenshot.
class _HowTo extends StatelessWidget {
  final String action;

  const _HowTo({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _InlineGlyph(icon: Icons.settings, label: action, accent: true),
        const SizedBox(height: 12),
        Text(
          ob.widgetListsHow(action),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _InlineGlyph extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const _InlineGlyph({
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = accent ? cs.primary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: (accent ? cs.primary : cs.onSurface).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
