import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Introduces the Multiple toggle on the compose bar — flipping it turns
/// the single-line input into a multi-line box where every line becomes
/// its own item.
class BulkAddOnboardingPage extends StatelessWidget {
  const BulkAddOnboardingPage({super.key});

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
            ob.bulkAddTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.bulkAddBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _MockBulkComposeBar(),
        ],
      ),
    );
  }
}

/// Stylised compose bar in bulk-mode. The Multiple toggle sits on the
/// trailing edge of the input bar (top-aligned, mirroring the real layout
/// where the toggle hugs the first line), and the "separate items by new
/// lines" hint renders as small caption text below the bar with start
/// padding 4 — same as the real compose bar.
class _MockBulkComposeBar extends StatelessWidget {
  const _MockBulkComposeBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ob = m.onboarding;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MockMultiLineInput(
          lines: [
            ob.mockItemName,
            ob.mockHardwareItemName,
            ob.mockBulkItemThird,
            ob.mockBulkItemFourth,
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            m.checklists.compose.multipleHint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveMultipleToggle extends StatelessWidget {
  const _ActiveMultipleToggle();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    return Container(
      height: 30,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent, width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_list_bulleted, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            m.checklists.compose.multiple,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMultiLineInput extends StatelessWidget {
  final List<String> lines;

  const _MockMultiLineInput({required this.lines});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.add, color: cs.primary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    Text(
                      lines[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (i < lines.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: const _ActiveMultipleToggle(),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
