import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'focus_list.dart';
import 'note_markdown.dart';
import 'proto_mechanics.dart';
import 'variant_note_document.dart';

/// PROTOTYPE — variant **C**, read here, tick over there.
///
/// The note reads as variant A's document, with every checkbox inert, and the
/// only way to change anything is a **Tick** button that pushes a surface
/// holding nothing but the note's task lines — a proper centred-focus list,
/// with card 715's commit-on-centre and its draining undo window.
///
/// The claim: reading and writing want different geometry, and a page that
/// serves both serves neither. Separating them means no gesture made while
/// reading can write, which is the strongest form of "a mis-aim costs a
/// scroll, never a write".
///
/// The cost it is here to expose: the task list loses its context. A note
/// whose tasks are interleaved with prose ("Boiler service") becomes three
/// bare lines with the sentences that explained them left on the other screen.
class VariantNoteTick extends StatelessWidget {
  static const label = 'Read · tick';

  final String title;
  final String body;
  final void Function(int ordinal) onToggle;

  const VariantNoteTick({
    super.key,
    required this.title,
    required this.body,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = taskProgress(body);
    return Stack(
      children: [
        Positioned.fill(child: VariantNoteDocument(body: body)),
        if (progress.total > 0)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: WearShape.isRound ? 18 : 10,
            child: Center(
              child: _TickButton(
                done: progress.done,
                total: progress.total,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _TickSurface(
                      title: title,
                      body: body,
                      onToggle: onToggle,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TickButton extends StatelessWidget {
  final int done;
  final int total;
  final VoidCallback onTap;

  const _TickButton({
    required this.done,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist, size: 15, color: primary),
            const SizedBox(width: 7),
            Text(
              '$done / $total',
              style: TextStyle(
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The task lines alone, as a centred-focus list. A pushed route, so it needs
/// its own back gesture — route (a) leaves it none.
class _TickSurface extends StatefulWidget {
  final String title;
  final String body;
  final void Function(int ordinal) onToggle;

  const _TickSurface({
    required this.title,
    required this.body,
    required this.onToggle,
  });

  @override
  State<_TickSurface> createState() => _TickSurfaceState();
}

class _TickSurfaceState extends State<_TickSurface>
    with TickerProviderStateMixin {
  static const _undoMs = 2000;

  final _controller = ScrollController();

  /// Toggles that have fired but not yet run out their undo window, keyed by
  /// task ordinal. The body is only rewritten when one survives.
  final _pending = <int, AnimationController>{};

  /// Local echo of the toggles in flight, so the row draws its new state while
  /// the window drains.
  final _echo = <int, bool>{};

  @override
  void dispose() {
    for (final c in _pending.values) {
      c.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _fire(NoteBlock block) {
    final ordinal = block.taskOrdinal!;
    final open = _pending.remove(ordinal);
    if (open != null) {
      // A second tap inside the window cancels the first rather than queueing
      // a second write.
      open.dispose();
      setState(() => _echo.remove(ordinal));
      return;
    }
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _undoMs),
    )..reverse(from: 1);
    controller.addStatusListener((status) {
      if (status != AnimationStatus.dismissed || !mounted) return;
      controller.dispose();
      _pending.remove(ordinal);
      _echo.remove(ordinal);
      widget.onToggle(ordinal);
      setState(() {});
    });
    setState(() {
      _pending[ordinal] = controller;
      _echo[ordinal] = !(block.checked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = parseNoteBlocks(
      widget.body,
    ).where((b) => b.kind == NoteBlockKind.task).toList();
    final inset = WearShape.isRound ? 0.1 : 0.05;

    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: Stack(
          children: [
            Positioned.fill(
              child: SnapFocusList(
                controller: _controller,
                itemExtent: 46,
                falloffRows: 2.2,
                horizontalInset: inset,
                rotaryActive: true,
                elements: [
                  for (final block in tasks)
                    FocusElement(
                      extent: 46,
                      builder: (context, d) => _TaskCard(
                        block: block,
                        distance: d,
                        checked: _echo[block.taskOrdinal!] ?? block.checked,
                        pending: _pending[block.taskOrdinal!],
                        onTap: d < 0.18 ? () => _fire(block) : null,
                      ),
                    ),
                ],
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              top: WearShape.isRound ? 22 : 12,
              child: Center(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: detectTextDirection(widget.title),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.0,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final NoteBlock block;
  final double distance;
  final bool checked;
  final AnimationController? pending;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.block,
    required this.distance,
    required this.checked,
    this.pending,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dir = detectTextDirection(block.text);
    Widget card = SizedBox(
      width: double.infinity,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF17171A),
            const Color(0xFF121215),
            distance,
          ),
          borderRadius: BorderRadius.circular(WearShape.isRound ? 15 : 10),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: Directionality(
            textDirection: dir,
            child: Row(
              children: [
                Icon(
                  checked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: checked ? primary : Colors.white54,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    flattenInline(block.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.18,
                      color: checked ? Colors.white38 : Colors.white,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final window = pending;
    if (window != null) {
      card = AnimatedBuilder(
        animation: window,
        builder: (context, child) => CustomPaint(
          foregroundPainter: _UndoStroke(
            progress: window.value,
            color: primary,
            radius: WearShape.isRound ? 15 : 10,
          ),
          child: child,
        ),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// The undo window drawn as a stroke draining off the card's own border, so
/// the thing running out is the thing you would be undoing.
class _UndoStroke extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  const _UndoStroke({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // An oversized RRect radius is not scaled down by `addRRect` the way
    // `BorderRadius` scales it, so it has to be clamped before it reaches a
    // Path or the outline comes out malformed.
    final r = radius.clamp(0.0, size.shortestSide / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(r),
        ),
      );
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_UndoStroke old) =>
      old.progress != progress || old.color != color;
}
