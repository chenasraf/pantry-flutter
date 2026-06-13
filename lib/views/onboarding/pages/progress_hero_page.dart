import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Teaches the swipe-to-dismiss gesture on the top progress card, and how to
/// bring it back from settings. Mocks the actual `ProgressHero` widget so the
/// visual is recognizable, then animates a continuous swipe-away demo.
class ProgressHeroOnboardingPage extends StatefulWidget {
  const ProgressHeroOnboardingPage({super.key});

  @override
  State<ProgressHeroOnboardingPage> createState() =>
      _ProgressHeroOnboardingPageState();
}

class _ProgressHeroOnboardingPageState extends State<ProgressHeroOnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Maps controller progress to a 0..1 dismiss factor (0 = at rest, 1 = card
  /// fully swept off-screen). Pattern: idle, then ease out, then idle to
  /// reset for the next loop.
  double _dismissFor(double t) {
    const idle = 0.20;
    const swipe = 0.35;
    if (t < idle) return 0;
    if (t < idle + swipe) {
      return Curves.easeOutCubic.transform((t - idle) / swipe);
    }
    return 0;
  }

  double _hintOpacityFor(double t) {
    const idle = 0.20;
    if (t < 0.04) return t / 0.04;
    if (t < idle - 0.04) return 1;
    if (t < idle) return 1 - (t - (idle - 0.04)) / 0.04;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final settings = m.settings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.progressHeroTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.progressHeroBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return _SwipeAwayHero(
                dismiss: _dismissFor(t),
                hintOpacity: _hintOpacityFor(t),
                hintText: ob.progressHeroHint,
              );
            },
          ),
          const SizedBox(height: 24),
          _BringBackHint(
            text: ob.progressHeroBringBack(
              settings.title,
              settings.interfaceSection,
              settings.showProgressHero,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeAwayHero extends StatelessWidget {
  /// 0 = at rest, 1 = fully dismissed off-screen.
  final double dismiss;
  final double hintOpacity;
  final String hintText;

  const _SwipeAwayHero({
    required this.dismiss,
    required this.hintOpacity,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Dismiss direction follows the locale — LTR sweeps to the right,
    // RTL to the left — mirroring real Dismissible behavior.
    final dx = dismiss * 360 * (isRtl ? -1 : 1);
    // Card tilts slightly as it leaves, the way Dismissible feels.
    final tilt = dismiss * 0.08 * (isRtl ? -1 : 1);
    final opacity = (1 - dismiss).clamp(0.0, 1.0);

    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.rotate(
                  angle: tilt,
                  child: Opacity(opacity: opacity, child: const _MockHero()),
                ),
              ),
            ),
          ),
          // Hint pill above the card while it's still at rest. Fades out as
          // the swipe starts so it doesn't distract from the motion.
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Opacity(
                    opacity: hintOpacity,
                    child: _SwipeHintPill(text: hintText),
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

class _MockHero extends StatelessWidget {
  const _MockHero();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
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
      child: Row(
        children: [
          const _MockRing(percent: 0.6),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.checklists.itemsLeft(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.checklists.listProgress(3, 5),
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
        ],
      ),
    );
  }
}

class _MockRing extends StatelessWidget {
  final double percent;

  const _MockRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(50, 50),
            painter: _RingPainter(
              percent: percent,
              color: cs.primary,
              trackColor: cs.onSurface.withValues(alpha: 0.09),
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
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.trackColor != trackColor;
}

class _SwipeHintPill extends StatelessWidget {
  final String text;

  const _SwipeHintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Arrow points in the dismiss direction (locale-aware). Uses west/east
    // rather than arrow_back/arrow_forward — the latter auto-mirror under
    // RTL Directionality and would flip back to point the wrong way.
    final arrowIcon = isRtl ? Icons.west : Icons.east;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: cs.onInverseSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Icon(arrowIcon, size: 14, color: cs.onInverseSurface),
        ],
      ),
    );
  }
}

/// Small explanatory footer with the settings path for re-enabling the card.
class _BringBackHint extends StatelessWidget {
  final String text;

  const _BringBackHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
