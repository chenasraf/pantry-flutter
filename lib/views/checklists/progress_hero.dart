import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// A card with a circular progress ring and "{N} items left / {done} of
/// {total} done" labels. Animates the ring on state changes.
///
/// When [onDismiss] is non-null, a small X button is rendered at the trailing
/// top corner so the card can be dismissed without a swipe gesture. The
/// caller decides when to provide it (typically on desktop, where horizontal
/// swipes aren't reliably available).
class ProgressHero extends StatelessWidget {
  final int total;
  final int done;
  final VoidCallback? onDismiss;

  const ProgressHero({
    super.key,
    required this.total,
    required this.done,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final left = (total - done).clamp(0, total);
    final pct = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.12),
            cs.primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _Ring(percent: pct, color: cs.primary),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  // Keep the labels clear of the X button so a long
                  // "Items left" string doesn't underflow it.
                  padding: EdgeInsetsDirectional.only(
                    end: onDismiss != null ? 24 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        left == 0
                            ? m.checklists.allDone
                            : m.checklists.itemsLeft(left),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.checklists.listProgress(done, total),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (onDismiss != null)
            PositionedDirectional(
              top: -6,
              end: -6,
              child: _DismissButton(
                onPressed: onDismiss!,
                tooltip: m.checklists.hideProgressHero,
              ),
            ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _DismissButton({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      style: IconButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
      icon: const Icon(Icons.close),
    );
  }
}

class _Ring extends StatelessWidget {
  final double percent;
  final Color color;

  const _Ring({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (_, value, _) => CustomPaint(
              size: const Size(50, 50),
              painter: _RingPainter(
                percent: value,
                color: color,
                trackColor: cs.onSurface.withValues(alpha: 0.09),
              ),
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      percent.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
