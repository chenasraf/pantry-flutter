import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Teaches the swipe-to-reveal gesture on list items. Renders a mocked-up
/// checklist row and runs a continuous demo animation that swipes the row
/// open, holds, then snaps back — so the reader can see the affordance
/// without having to actually swipe anything.
class SwipeActionsOnboardingPage extends StatefulWidget {
  const SwipeActionsOnboardingPage({super.key});

  @override
  State<SwipeActionsOnboardingPage> createState() =>
      _SwipeActionsOnboardingPageState();
}

class _SwipeActionsOnboardingPageState extends State<SwipeActionsOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Action button width — matches SwipeRevealRow._actionWidth so the demo
  // looks identical to the real list.
  static const double _actionWidth = 62;
  static const int _actionCount = 3;
  double get _maxSwipe => _actionWidth * _actionCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Phase boundaries (fractions of one loop). Opening and closing are short
  /// active motions; the two holds give the eye time to read the action
  /// labels (held-open) and reset (held-closed) before the next pass.
  static const double _openEnd = 0.18;
  static const double _holdOpenEnd = 0.46;
  static const double _closeEnd = 0.64;

  /// Maps the controller's 0..1 progress to a swipe offset (0 closed,
  /// `_maxSwipe` fully open).
  double _offsetFor(double t) {
    if (t < _openEnd) {
      final p = Curves.easeOutCubic.transform(t / _openEnd);
      return _maxSwipe * p;
    } else if (t < _holdOpenEnd) {
      return _maxSwipe;
    } else if (t < _closeEnd) {
      // Symmetric easing — same curve as the open phase so both motions
      // feel equally snappy. Using easeInCubic here made the close drag,
      // because most of the visible motion ended up bunched at the end.
      final p = Curves.easeOutCubic.transform(
        (t - _holdOpenEnd) / (_closeEnd - _holdOpenEnd),
      );
      return _maxSwipe * (1 - p);
    } else {
      return 0;
    }
  }

  /// Hint opacity during the opening phase (covers fade-in/visible/fade-out).
  double _openingHintOpacity(double t) {
    if (t < 0.02) return t / 0.02;
    if (t < _openEnd - 0.04) return 1;
    if (t < _openEnd) return 1 - (t - (_openEnd - 0.04)) / 0.04;
    return 0;
  }

  /// Hint opacity during the closing phase. Fades in just before the close
  /// motion starts so it reads as "we're about to do this", visible through
  /// the close, then fades out as the row settles back to idle.
  double _closingHintOpacity(double t) {
    const fadeIn = 0.02;
    const fadeOut = 0.04;
    if (t < _holdOpenEnd - fadeIn) return 0;
    if (t < _holdOpenEnd) return (t - (_holdOpenEnd - fadeIn)) / fadeIn;
    if (t < _closeEnd - fadeOut) return 1;
    if (t < _closeEnd) return 1 - (t - (_closeEnd - fadeOut)) / fadeOut;
    return 0;
  }

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
            ob.swipeActionsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.swipeActionsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Card-shaped container so the swipe motion clips cleanly inside,
          // mirroring how the real list item lives inside the list's surface.
          // Border lives in `foregroundDecoration` so it paints on top of the
          // (already-clipped) child — same fix as ChecklistItemTile's cards
          // view; otherwise the swipe row's Material surface erodes the
          // rounded corners and the border looks faded at the edges.
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final offset = _offsetFor(t);
                // Show whichever hint is currently fading in or out. Opening
                // and closing phases never overlap, so picking the bigger
                // opacity is safe and avoids stacking two pills.
                final openingOp = _openingHintOpacity(t);
                final closingOp = _closingHintOpacity(t);
                final showClosing = closingOp > openingOp;
                return _DemoRow(
                  offset: offset,
                  maxSwipe: _maxSwipe,
                  actionWidth: _actionWidth,
                  hintOpacity: showClosing ? closingOp : openingOp,
                  hintText: showClosing
                      ? ob.swipeActionsHintBack
                      : ob.swipeActionsHint,
                  hintDirection: showClosing
                      ? _SwipeDirection.right
                      : _SwipeDirection.left,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the mock row + the action buttons sliding in from the trailing
/// edge. Identical layering to the real `SwipeRevealRow`: foreground stays
/// put, actions translate in on top of it.
enum _SwipeDirection { left, right }

class _DemoRow extends StatelessWidget {
  final double offset;
  final double maxSwipe;
  final double actionWidth;
  final double hintOpacity;
  final String hintText;
  final _SwipeDirection hintDirection;

  const _DemoRow({
    required this.offset,
    required this.maxSwipe,
    required this.actionWidth,
    required this.hintOpacity,
    required this.hintText,
    required this.hintDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // SwipeRevealRow uses negative offsets internally; we work in positive
    // here for clarity, then flip for direction.
    final slide = (maxSwipe - offset) * (isRtl ? -1 : 1);
    return ClipRect(
      child: Stack(
        children: [
          const _MockListItem(),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            child: Transform.translate(
              offset: Offset(slide, 0),
              child: SizedBox(
                height: double.infinity,
                child: Row(
                  children: [
                    _DemoActionButton(
                      width: actionWidth,
                      icon: Icons.edit_outlined,
                      label: m.checklists.swipeEdit,
                      tint: Theme.of(context).colorScheme.onSurfaceVariant,
                      background: Color.alphaBlend(
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.07),
                        Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    _DemoActionButton(
                      width: actionWidth,
                      icon: Icons.drive_file_move_outlined,
                      label: m.checklists.swipeMove,
                      tint: const Color(0xFFD9B441),
                      background: Color.alphaBlend(
                        const Color(0xFFD9B441).withValues(alpha: 0.18),
                        Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    _DemoActionButton(
                      width: actionWidth,
                      icon: Icons.delete_outline,
                      label: m.checklists.swipeDelete,
                      tint: const Color(0xFFEF7878),
                      background: Color.alphaBlend(
                        const Color(0xFFEF7878).withValues(alpha: 0.2),
                        Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating "Swipe left" hint with a hand icon. Sits over the row
          // during the actual sliding so it reads as a gesture instruction.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Opacity(
                  opacity: hintOpacity,
                  child: _SwipeHintPill(
                    text: hintText,
                    direction: hintDirection,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeHintPill extends StatelessWidget {
  final String text;
  final _SwipeDirection direction;

  const _SwipeHintPill({required this.text, required this.direction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Visual arrow points in the literal gesture direction. In RTL the user
    // still drags physically in that screen direction (the SwipeRevealRow
    // implementation flips its internal sign), so the icon flips with the
    // locale to keep the visual instruction true to the screen.
    final isLeft = direction == _SwipeDirection.left;
    final visualLeft = isRtl ? !isLeft : isLeft;
    // Use west/east instead of arrow_back/arrow_forward — the latter have
    // `matchTextDirection: true`, which silently flips the glyph again under
    // an RTL Directionality and lands the arrow opposite the hint text.
    final arrowIcon = visualLeft ? Icons.west : Icons.east;
    final iconWidget = Icon(arrowIcon, size: 14, color: cs.onInverseSurface);
    final textWidget = Text(
      text,
      style: TextStyle(
        color: cs.onInverseSurface,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Force LTR layout so the arrow always sits on the side it points to,
      // regardless of the locale's reading direction. With RTL Row layout,
      // children appear in reverse, which would land the arrow on the
      // opposite visual side from where it points.
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: visualLeft
            ? [iconWidget, const SizedBox(width: 6), textWidget]
            : [textWidget, const SizedBox(width: 6), iconWidget],
      ),
    );
  }
}

class _DemoActionButton extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final Color tint;
  final Color background;

  const _DemoActionButton({
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

/// Mocked list-item row — checkbox + name + quantity pill + category chip,
/// styled to match the real ChecklistItemTile content.
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
                    _MockChip(
                      label: ob.mockItemCategory,
                      color: cs.primary,
                      background: cs.primary.withValues(alpha: 0.14),
                      icon: Icons.local_florist,
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
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
