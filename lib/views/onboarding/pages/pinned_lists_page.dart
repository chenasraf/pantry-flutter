import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Tells users that pinning a list shows it in the Pantry home-screen widget,
/// and explains how to pin (overflow menu → Pin list). Stays static — the
/// "demo" is a stylised mock of the widget; the real widget UX varies per OS
/// and would be wasteful to animate here.
class PinnedListsOnboardingPage extends StatelessWidget {
  const PinnedListsOnboardingPage({super.key});

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
            ob.pinnedListsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.pinnedListsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _WidgetMock(),
          const SizedBox(height: 24),
          _HowToPin(
            menu: ob.pinnedListsMenuLabel,
            action: ob.pinnedListsActionLabel,
          ),
        ],
      ),
    );
  }
}

/// Stylised home-screen widget tile — header bar + two pinned-list rows so
/// the user recognises what they're looking at on their actual launcher.
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
                child: Icon(Icons.push_pin, size: 14, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Text(
                ob.pinnedListsWidgetTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
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
        ? ob.pinnedListsWidgetEmpty
        : ob.pinnedListsWidgetItemsLeft(leftCount);
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

/// Inline instruction with the actual icons the user will tap. Reading the
/// words alongside the glyphs makes the step land without a screenshot.
class _HowToPin extends StatelessWidget {
  final String menu;
  final String action;

  const _HowToPin({required this.menu, required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final menuChip = _InlineGlyph(icon: Icons.more_vert, label: menu);
    final actionChip = _InlineGlyph(
      icon: Icons.push_pin,
      label: action,
      accent: true,
    );
    // The body string already includes "${menu}" and "${action}" placeholders
    // — but i18n keeps those as inline text, not widgets. To get widget chips
    // inline with the body sentence we render the chips above the paragraph
    // and let the paragraph reference them by name. Compact, accessible, and
    // avoids hand-parsing the localized string into RichText spans.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [menuChip, actionChip],
        ),
        const SizedBox(height: 12),
        Text(
          ob.pinnedListsHow(menu, action),
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
    final tint = accent ? cs.primary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? cs.primary.withValues(alpha: 0.14)
            : cs.surfaceContainerHighest,
        border: Border.all(color: tint.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}
