/// The watch, drawn on a phone screen.
///
/// A likeness of the watch's surfaces rather than the watch's own widgets: the
/// same dark ground, rail, pill rows and centre focus, redrawn at a fifth of
/// the glass so three rows and a label still read. Reusing the real ones would
/// drag a Wear-only widget tree — and its rotary, ambient and shape services —
/// into the phone for the sake of a picture.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The ground the watch draws on. Every face here is dark whichever theme the
/// phone is in, because the watch is.
const _ground = Color(0xFF0B0B0C);
const _bezel = Color(0xFF232327);
const _card = Color(0xFF26262B);
const _ink = Color(0xFFF2F2F4);
const _dimInk = Color(0xFF9A9AA2);

/// The extent one mock row occupies, gap included.
const double _rowExtent = 27;
const double _cardHeight = 23;

/// How far the centre falloff reaches, in rows — the watch's own figure.
const double _falloffRows = 2.2;

/// A round watch: bezel, crown, and a face holding [child].
///
/// Text inside is pinned against the phone's font scale. Everything here is a
/// diagram at a fixed size, and a scaled 9pt label inside a fixed circle is an
/// overflow rather than an accessibility win — the prose under the picture is
/// what carries the tip, and that scales.
class WatchMock extends StatelessWidget {
  final Widget child;
  final double size;

  /// Draws the crown lit, for the tip that is about turning it.
  final bool crownLit;

  const WatchMock({
    super.key,
    required this.child,
    this.size = 196,
    this.crownLit = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: size + 18,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The crown sits behind the case, so the case's edge crops it into
            // a nub the way a real one is cropped.
            PositionedDirectional(
              end: 0,
              top: size * 0.3,
              child: Transform.rotate(
                angle: -0.42,
                child: Container(
                  width: 22,
                  height: 13,
                  decoration: BoxDecoration(
                    color: crownLit ? scheme.primary : const Color(0xFF3A3A40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _bezel,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsetsDirectional.all(7),
              child: ClipOval(
                child: ColoredBox(color: _ground, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone beside the watch, for the tip where the two talk to each other.
class PhoneMock extends StatelessWidget {
  final Widget child;
  final double height;

  const PhoneMock({super.key, required this.child, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: height * 0.58,
        height: height,
        decoration: BoxDecoration(
          color: _bezel,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsetsDirectional.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(color: scheme.surface, child: child),
        ),
      ),
    );
  }
}

/// What the watch's rail says: sync, the page's name, the group under it, and
/// where you are in the pager.
class MockRail extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? tint;
  final String? group;
  final int page;
  final int pages;

  /// Writes the watch is holding. Zero draws the settled dot.
  final int queued;

  /// The buttons the rail drops when its title is tapped, if any.
  final Widget? panel;

  const MockRail({
    super.key,
    required this.title,
    required this.icon,
    this.tint,
    this.group,
    this.page = 0,
    this.pages = 4,
    this.queued = 0,
    this.panel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? _dimInk;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (queued == 0)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            else ...[
              const Icon(Icons.cloud_queue, size: 9, color: _dimInk),
              const SizedBox(width: 3),
              Text(
                '$queued',
                style: const TextStyle(fontSize: 8, color: _dimInk),
              ),
            ],
            const SizedBox(width: 5),
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.1,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 11,
          child: group == null
              ? null
              : Text(
                  group!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7.5,
                    height: 1.2,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                    color: _dimInk,
                  ),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pages; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsetsDirectional.symmetric(horizontal: 1.5),
                width: i == page ? 11 : 6,
                height: 2.5,
                decoration: BoxDecoration(
                  color: i == page ? scheme.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        if (panel != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6),
            child: panel,
          ),
      ],
    );
  }
}

/// One of the buttons the rail drops under itself.
class MockRailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;

  const MockRailButton({
    super.key,
    required this.icon,
    required this.label,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = primary ? scheme.primary : Colors.white70;
    return Container(
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary
            ? scheme.primary.withValues(alpha: 0.26)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ink),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row on one of the watch's lists.
class MockItem {
  final String label;
  final bool checked;
  final IconData? markedIcon;
  final IconData? leading;
  final Color? tint;
  final String? trailing;

  /// How much of the undo stroke is left, or null for a row holding none.
  final double? undo;

  const MockItem(
    this.label, {
    this.checked = false,
    this.markedIcon,
    this.leading,
    this.tint,
    this.trailing,
    this.undo,
  });
}

/// The centre-focus list, with [centre] as the fractional row on the line.
class MockItemList extends StatelessWidget {
  final List<MockItem> items;
  final double centre;

  const MockItemList({super.key, required this.items, required this.centre});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ClipRect(
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            _positioned(context, i, constraints.maxHeight),
        ],
      ),
    ),
  );

  Widget _positioned(BuildContext context, int index, double height) {
    final offset = (index - centre) * _rowExtent;
    final d = ((index - centre).abs() / _falloffRows).clamp(0.0, 1.0);
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: height / 2 - _rowExtent / 2 + offset,
      height: _rowExtent,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.96 - 0.2 * d,
          child: Opacity(
            opacity: 1 - 0.62 * d,
            child: _MockRow(item: items[index], d: d),
          ),
        ),
      ),
    );
  }
}

/// The same rows stacked to their own height, with no falloff and no centre.
///
/// For the faces that show a short fixed set — a settings page, the switcher,
/// the Tile — where nothing scrolls and so nothing is nearer the middle than
/// anything else.
class MockRows extends StatelessWidget {
  final List<MockItem> items;

  const MockRows(this.items, {super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: _rowExtent - _cardHeight,
          ),
          child: _MockRow(item: item, d: 0),
        ),
    ],
  );
}

class _MockRow extends StatelessWidget {
  final MockItem item;
  final double d;

  const _MockRow({required this.item, required this.d});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(_cardHeight / 2);
    final card = Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        color: Color.lerp(_card, const Color(0xFF141417), d),
        borderRadius: radius,
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 9),
      child: Row(
        children: [
          Icon(
            item.checked
                ? (item.markedIcon ?? Icons.check_circle)
                : (item.leading ?? Icons.circle_outlined),
            size: 11,
            color: item.checked
                ? scheme.primary
                : (item.tint ?? Colors.white38),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                color: item.checked ? Colors.white38 : _ink,
                decoration: item.checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (item.trailing != null)
            Text(
              item.trailing!,
              style: const TextStyle(fontSize: 8, color: _dimInk),
            ),
        ],
      ),
    );
    final undo = item.undo;
    if (undo == null) return card;
    return CustomPaint(
      foregroundPainter: _UndoStrokePainter(
        remaining: undo,
        color: scheme.primary,
        radius: _cardHeight / 2,
      ),
      child: card,
    );
  }
}

/// The stroke draining off a row's own border while the tap is still yours to
/// take back.
class _UndoStrokePainter extends CustomPainter {
  final double remaining;
  final Color color;
  final double radius;

  const _UndoStrokePainter({
    required this.remaining,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (remaining <= 0) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final length = metric.length;
    canvas.drawPath(
      metric.extractPath(0, length * remaining.clamp(0.0, 1.0)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_UndoStrokePainter old) =>
      old.remaining != remaining || old.color != color;
}

/// The one action a page offers, as a pill across the bottom of the face.
class MockCta extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool warning;

  const MockCta({
    super.key,
    required this.icon,
    required this.label,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = warning ? const Color(0xFFE0A0A0) : scheme.primary;
    return Container(
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: warning
            ? const Color(0xFF2A1D1D)
            : scheme.primary.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: ink),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A face: the rail over whatever the page draws, with the page's action
/// floating at the bottom.
///
/// The rail overlays the body rather than sitting above it, as it does on the
/// watch — the centre line is the screen's, so a rail in a column would push it
/// off centre.
class MockFace extends StatelessWidget {
  final MockRail? rail;
  final Widget? body;
  final Widget? cta;

  const MockFace({super.key, this.rail, this.body, this.cta});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Insets are fractions of the face rather than pixels, so the same face
    // drawn small beside a phone keeps the proportions of the one drawn large.
    builder: (context, constraints) => Stack(
      children: [
        if (body != null) Positioned.fill(child: body!),
        if (rail != null)
          PositionedDirectional(
            start: 0,
            end: 0,
            top: 0,
            // Filled to the glass, as the watch fills it: the list runs under
            // the rail rather than stopping at it, and a translucent rail
            // would show the rows sliding through its own text.
            child: ColoredBox(
              color: _ground,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: constraints.maxHeight * 0.11,
                ),
                child: Center(
                  child: FractionallySizedBox(widthFactor: 0.7, child: rail!),
                ),
              ),
            ),
          ),
        if (cta != null)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: constraints.maxHeight * 0.08,
            child: Center(
              child: FractionallySizedBox(widthFactor: 0.72, child: cta!),
            ),
          ),
      ],
    ),
  );
}

// -- Gesture cues -------------------------------------------------------------

/// Places a cue of [box] pixels so that its **centre** lands at [alignment] of
/// the face, rather than where `Align` would put it.
///
/// `Align` measures against the space left over once the child is subtracted,
/// so a cue as wide as a third of the watch never reaches the last third of it
/// — and the alignment a caller wrote against the thing they were pointing at
/// would quietly fall short of it.
class _AtPoint extends StatelessWidget {
  final Alignment alignment;
  final double box;
  final Widget child;

  const _AtPoint({
    required this.alignment,
    required this.box,
    required this.child,
  });

  /// The result runs past ±1 for a target near the edge, which is the point:
  /// `Align` is happy to hang the box over the side, and what hangs over is a
  /// ring the round clip was going to shave anyway.
  static double _spread(double v, double extent, double box) =>
      extent <= box ? v : (v * extent / (extent - box)).clamp(-2.0, 2.0);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Align(
      alignment: Alignment(
        _spread(alignment.x, constraints.maxWidth, box),
        _spread(alignment.y, constraints.maxHeight, box),
      ),
      child: SizedBox.square(dimension: box, child: child),
    ),
  );
}

/// A fingertip landing on the glass: the contact, and the ring it throws off.
///
/// [t] runs 0 to 1 across one press. The ring outlives the contact so the eye
/// has something to follow after the finger has gone.
class TapCue extends StatelessWidget {
  final double t;
  final Alignment alignment;

  const TapCue({super.key, required this.t, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final press = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
    final release = Curves.easeOut.transform(((t - 0.2) / 0.8).clamp(0.0, 1.0));
    return _AtPoint(
      alignment: alignment,
      box: 62,
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - release) * 0.7,
              child: Container(
                width: 16 + 44 * release,
                height: 16 + 44 * release,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            Opacity(
              opacity: press * (1 - Curves.easeIn.transform(release)),
              child: const _Fingertip(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A fingertip held down, with the hold drawn as an arc closing around it.
class HoldCue extends StatelessWidget {
  final double t;
  final Alignment alignment;

  const HoldCue({
    super.key,
    required this.t,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final fade = t < 0.1
        ? t / 0.1
        : t > 0.88
        ? (1 - t) / 0.12
        : 1.0;
    final swept = Curves.easeInOut.transform(((t - 0.1) / 0.7).clamp(0.0, 1.0));
    return _AtPoint(
      alignment: alignment,
      box: 44,
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _ArcPainter(
              sweep: swept,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Center(child: _Fingertip()),
          ),
        ),
      ),
    );
  }
}

/// A fingertip dragging across the glass, trailing the path it took.
///
/// [towardsStart] is in reading terms, so a swipe that means "the next page"
/// is drawn running the way the pager actually moves under the locale.
class SwipeCue extends StatelessWidget {
  final double t;
  final bool towardsStart;
  final double travel;

  const SwipeCue({
    super.key,
    required this.t,
    this.towardsStart = true,
    this.travel = 92,
  });

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = (towardsStart ? -1 : 1) * (rtl ? -1 : 1);
    final p = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    final fade = t < 0.12
        ? t / 0.12
        : t > 0.82
        ? (1 - t) / 0.18
        : 1.0;
    return Center(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: SizedBox(
          width: travel + 40,
          height: 40,
          child: CustomPaint(
            painter: _TrailPainter(progress: p, sign: sign, travel: travel),
            child: Align(
              alignment: Alignment(sign * (p * 2 - 1), 0),
              child: const _Fingertip(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The crown turning, as an arc sweeping the bezel beside it.
class CrownCue extends StatelessWidget {
  final double t;
  final double size;

  const CrownCue({super.key, required this.t, required this.size});

  @override
  Widget build(BuildContext context) {
    final fade = t < 0.12
        ? t / 0.12
        : t > 0.8
        ? (1 - t) / 0.2
        : 1.0;
    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CrownArcPainter(
              progress: Curves.easeInOut.transform(t.clamp(0.0, 1.0)),
              color: Theme.of(context).colorScheme.primary,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }
}

class _Fingertip extends StatelessWidget {
  const _Fingertip();

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
  );
}

class _ArcPainter extends CustomPainter {
  final double sweep;
  final Color color;

  const _ArcPainter({required this.sweep, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.sweep != sweep;
}

class _TrailPainter extends CustomPainter {
  final double progress;
  final int sign;
  final double travel;

  const _TrailPainter({
    required this.progress,
    required this.sign,
    required this.travel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final from = size.width / 2 - sign * travel / 2;
    final to = from + sign * travel * progress;
    canvas.drawLine(
      Offset(from, y),
      Offset(to, y),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: sign > 0
              ? [Colors.white.withValues(alpha: 0), Colors.white54]
              : [Colors.white54, Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.progress != progress;
}

class _CrownArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool rtl;

  const _CrownArcPainter({
    required this.progress,
    required this.color,
    required this.rtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Hugging the side the crown is on, which follows the case: the crown is
    // drawn at the trailing edge, so in RTL it is on the left and the arc has
    // to move with it.
    final start = rtl ? math.pi * 0.78 : -math.pi * 0.34;
    final sweep = (rtl ? -1 : 1) * math.pi * 0.5 * progress;
    final rect = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, start, sweep, false, paint);

    if (progress < 0.12) return;
    // The arrowhead, laid along the tangent at the arc's leading end.
    final angle = start + sweep;
    final centre = rect.center;
    final r = rect.width / 2;
    final tip = Offset(
      centre.dx + r * math.cos(angle),
      centre.dy + r * math.sin(angle),
    );
    final dir = (rtl ? -1 : 1);
    final tangent = angle + dir * math.pi / 2;
    final head = Path();
    for (final spread in [2.5, -2.5]) {
      final a = tangent + spread;
      head.moveTo(tip.dx, tip.dy);
      head.lineTo(tip.dx + 7 * math.cos(a), tip.dy + 7 * math.sin(a));
    }
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_CrownArcPainter old) => old.progress != progress;
}
