import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/checklist_icons.dart';

/// Teaches users that tapping the list title at the top of the checklists tab
/// opens the list switcher. Shows a mocked-up AppBar title row + the switcher
/// panel underneath, with a curved arrow connecting them.
class ChecklistSelectorOnboardingPage extends StatelessWidget {
  const ChecklistSelectorOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    final lists = <_MockList>[
      _MockList(name: ob.mockListGroceries, icon: 'cart', selected: true),
      _MockList(name: ob.mockListHardware, icon: 'wrench', selected: false),
      _MockList(name: ob.mockListWeekend, icon: 'beach', selected: false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.checklistSelectorTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.checklistSelectorBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _MockTitleBar(list: lists.first),
          _ArrowHint(text: ob.checklistSelectorHint),
          _MockSwitcherPanel(lists: lists),
        ],
      ),
    );
  }
}

class _MockList {
  final String name;
  final String icon;
  final bool selected;

  const _MockList({
    required this.name,
    required this.icon,
    required this.selected,
  });
}

/// Reproduces ChecklistsView's AppBar title: icon tile + name + chevron, with
/// the surface-container background of a real AppBar.
class _MockTitleBar extends StatelessWidget {
  final _MockList list;

  const _MockTitleBar({required this.list});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(checklistIcon(list.icon), color: cs.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              list.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}

/// Inline preview of the bottom-sheet switcher: the three mock lists + a
/// "New list" tile at the end.
class _MockSwitcherPanel extends StatelessWidget {
  final List<_MockList> lists;

  const _MockSwitcherPanel({required this.lists});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final l in lists) ...[
            _SwitcherTile(list: l),
            const SizedBox(height: 8),
          ],
          _NewListTile(),
        ],
      ),
    );
  }
}

class _SwitcherTile extends StatelessWidget {
  final _MockList list;

  const _SwitcherTile({required this.list});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = list.selected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.10)
            : cs.surfaceContainer,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(checklistIcon(list.icon), color: cs.primary, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  m.onboarding.mockItemCountSummary(_mockCountFor(list.name)),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  static int _mockCountFor(String name) {
    // Stable per-page counts so the preview doesn't shuffle on rebuild.
    return name.length % 7 + 3;
  }
}

class _NewListTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(
          color: cs.outlineVariant,
          width: 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              m.onboarding.newListLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Curved down-pointing arrow + hint label connecting the mock title bar to
/// the switcher panel.
class _ArrowHint extends StatelessWidget {
  final String text;

  const _ArrowHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: CustomPaint(
        painter: _ArrowPainter(color: cs.primary),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Curve from the upper-left (under the title bar) down to the
    // upper-right of the switcher panel.
    final start = Offset(size.width * 0.20, 4);
    final end = Offset(size.width * 0.46, size.height - 4);
    final control = Offset(size.width * 0.16, size.height - 4);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    canvas.drawPath(path, stroke);

    // Arrowhead at the end, oriented along the curve's tangent.
    final tangent = (end - control);
    final angle = math.atan2(tangent.dy, tangent.dx);
    const headLen = 10.0;
    const headAngle = 0.5;
    final p1 = Offset(
      end.dx - headLen * math.cos(angle - headAngle),
      end.dy - headLen * math.sin(angle - headAngle),
    );
    final p2 = Offset(
      end.dx - headLen * math.cos(angle + headAngle),
      end.dy - headLen * math.sin(angle + headAngle),
    );
    canvas.drawLine(end, p1, stroke);
    canvas.drawLine(end, p2, stroke);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.color != color;
}
