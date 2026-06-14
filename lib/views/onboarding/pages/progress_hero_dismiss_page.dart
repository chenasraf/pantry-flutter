import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

/// Desktop counterpart to `ProgressHeroOnboardingPage`. Where the mobile
/// flow animates a swipe-away gesture, this one calls out the X button at
/// the trailing top corner of the progress card. Static mock — no motion
/// needed; the affordance is the lesson.
class ProgressHeroDismissOnboardingPage extends StatelessWidget {
  const ProgressHeroDismissOnboardingPage({super.key});

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
            ob.progressHeroDismissTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.progressHeroDismissBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _MockHeroWithX(),
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

/// Static mock with a subtle pulse around the X button so the eye lands on
/// the dismiss target immediately. Mirrors the real card's gradient/border
/// so users can recognise it on the checklist screen later.
class _MockHeroWithX extends StatefulWidget {
  const _MockHeroWithX();

  @override
  State<_MockHeroWithX> createState() => _MockHeroWithXState();
}

class _MockHeroWithXState extends State<_MockHeroWithX>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

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
      child: Stack(
        children: [
          Row(
            children: [
              const _MockRing(percent: 0.6),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 24),
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
              ),
            ],
          ),
          PositionedDirectional(
            top: -6,
            end: -6,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                // Two-phase pulse: scale from 1.0 → 1.18 → 1.0; the halo
                // fades in/out in sync so it reads as a soft heartbeat.
                final t = _pulse.value;
                final eased = (math.sin(t * math.pi * 2 - math.pi / 2) + 1) / 2;
                final scale = 1 + eased * 0.18;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.18 * eased),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: _MockXButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockXButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
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
