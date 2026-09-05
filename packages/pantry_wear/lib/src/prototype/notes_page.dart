import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'focus_list.dart';
import 'note_blocks.dart';
import 'note_markdown.dart';
import 'proto_mechanics.dart';
import 'proto_note_data.dart';
import 'proto_tuning.dart';

/// PROTOTYPE — the notes page, as Q20 settled it.
///
/// Notes ride the mirror whole, bodies included, so a note is readable on the
/// wrist without a fetch. Bodies are **raw markdown** — the same string the
/// web app co-edits — so the watch reads and writes exactly what the phone
/// stores, and there is no conversion to lose anything in.
///
/// The watch never accepts text. The one write is **setting a task line's
/// checkbox**, which `toggleChecklistItem` does in core by rewriting a single
/// character. Creating, retitling and editing prose are phone jobs.
class NotesPage extends StatefulWidget {
  final ProtoTuning tuning;
  final bool active;

  /// Note bodies as raw markdown, owned by the pager so a tick can feed the
  /// same queue counter the checklist's commits feed.
  final Map<int, String> bodies;
  final void Function(int noteId, int ordinal, bool checked) onSetTask;

  const NotesPage({
    super.key,
    required this.tuning,
    required this.active,
    required this.bodies,
    required this.onSetTask,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(ProtoNote note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteRoute(
          note: note,
          tuning: widget.tuning,
          bodyOf: () => widget.bodies[note.id]!,
          onSetTask: (ordinal, checked) =>
              widget.onSetTask(note.id, ordinal, checked),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SnapFocusList(
      controller: _controller,
      itemExtent: 72,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      rotaryActive: widget.active,
      horizontalInset: widget.tuning.tallSideInset,
      elements: [
        for (final note in protoNotes)
          FocusElement(
            extent: 72,
            builder: (context, d) => _NoteCard(
              note: note,
              body: widget.bodies[note.id]!,
              distance: d,
              // The wall inherits the checklists page's rule: only the centred
              // card opens, an off-centre tap just scrolls it there.
              onTap: d < 0.18 ? () => _open(note) : null,
            ),
          ),
      ],
    );
  }
}

/// A note on the wall.
///
/// Ticking is the only thing the watch can do to a note, so a note holding
/// tasks says how many are left rather than previewing prose the wearer will
/// open it to read anyway.
class _NoteCard extends StatelessWidget {
  final ProtoNote note;
  final String body;
  final double distance;
  final VoidCallback? onTap;

  const _NoteCard({
    required this.note,
    required this.body,
    required this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = taskProgress(body);
    final preview = parseNoteBlocks(body)
        .where((b) => b.kind != NoteBlockKind.task)
        .map((b) => flattenInline(b.text))
        .join(' · ');

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          // State both, always: a Column of Text sizes to its longest line, so
          // short notes would otherwise draw short cards.
          width: double.infinity,
          height: 66,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF17171A),
                const Color(0xFF121215),
                distance,
              ),
              borderRadius: BorderRadius.circular(WearShape.isRound ? 18 : 12),
            ),
            child: Row(
              children: [
                // The note's own colour as an edge rather than a fill: the
                // theme is two planes of near-black, and six user-picked hues
                // filling six cards would be the loudest thing on the watch.
                if (note.color != null)
                  Container(
                    width: 3,
                    margin: const EdgeInsetsDirectional.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: note.color!.withValues(alpha: 1 - distance * 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.pinned) ...[
                              const Icon(
                                Icons.push_pin,
                                size: 11,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: detectTextDirection(note.title),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.1,
                                  fontWeight: distance < 0.5
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: progress.total > 0
                              ? _Progress(
                                  done: progress.done,
                                  total: progress.total,
                                )
                              : Text(
                                  preview.isEmpty ? '—' : preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: detectTextDirection(preview),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    height: 1.25,
                                    color: Colors.white60,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int done;
  final int total;

  const _Progress({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final complete = done == total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          complete ? 'All done' : '${total - done} left',
          style: TextStyle(
            fontSize: 10,
            height: 1.0,
            color: complete ? primary : Colors.white70,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 3,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(primary),
          ),
        ),
      ],
    );
  }
}

/// One note, pushed over the wall: a focus list of markdown blocks.
///
/// Task rows are the only snappable ones, so Q19's rule carries over unchanged
/// — the centred task commits on tap, an off-centre tap only scrolls it there.
/// A row you cannot act on was never a landing candidate, which is the same
/// reasoning that keeps a group header out of the snap table.
///
/// It needs its own back gesture: route (a) turns off the system dismiss
/// app-wide, so a pushed route inherits no way out at all.
class NoteRoute extends StatefulWidget {
  final ProtoNote note;
  final ProtoTuning tuning;
  final String Function() bodyOf;
  final void Function(int ordinal, bool checked) onSetTask;

  const NoteRoute({
    super.key,
    required this.note,
    required this.tuning,
    required this.bodyOf,
    required this.onSetTask,
  });

  @override
  State<NoteRoute> createState() => _NoteRouteState();
}

class _NoteRouteState extends State<NoteRoute> with TickerProviderStateMixin {
  final _controller = ScrollController();

  /// Ticks that have fired but not yet run out their undo window, keyed by
  /// task ordinal, exactly as a check is held on the checklists page.
  final _pending = <int, AnimationController>{};

  /// The state each in-flight tick is heading for, so the row draws its new
  /// value while the window drains.
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
    final target = !block.checked;
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.tuning.undoMs),
    )..reverse(from: 1);
    controller.addStatusListener((status) {
      if (status != AnimationStatus.dismissed || !mounted) return;
      controller.dispose();
      _pending.remove(ordinal);
      _echo.remove(ordinal);
      widget.onSetTask(ordinal, target);
      setState(() {});
    });
    setState(() {
      _pending[ordinal] = controller;
      _echo[ordinal] = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final blocks = parseNoteBlocks(widget.bodyOf());
    final inset = widget.tuning.tallSideInset;

    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth * (1 - inset * 2) - 20;
            return Stack(
              children: [
                Positioned.fill(
                  child: SnapFocusList(
                    controller: _controller,
                    itemExtent: 46,
                    falloffRows: widget.tuning.falloffRows,
                    snapEnabled: widget.tuning.snapEnabled,
                    rotaryActive: true,
                    horizontalInset: inset,
                    elements: [
                      for (final block in blocks)
                        FocusElement(
                          extent: _measure(block, contentWidth),
                          snappable: block.kind == NoteBlockKind.task,
                          isHeader: block.kind != NoteBlockKind.task,
                          builder: (context, d) => _BlockRow(
                            block: block,
                            distance: d,
                            checked: _echo[block.taskOrdinal] ?? block.checked,
                            pending: _pending[block.taskOrdinal],
                            onTap: block.kind == NoteBlockKind.task && d < 0.18
                                ? () => _fire(block)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  top: WearShape.isRound ? 20 : 10,
                  child: IgnorePointer(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 40,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0B0B0C),
                            const Color(0xFF0B0B0C).withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(widget.note.title),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The height a block needs at [width], plus the padding its row draws.
///
/// A cost the checklists page never paid: its rows were uniform by
/// construction, where a paragraph's height is a function of its text and the
/// width it gets. The real page wants this cached against `(text, width)` —
/// it re-runs for every block on every rebuild.
double _measure(NoteBlock block, double width) {
  final style = switch (block.kind) {
    NoteBlockKind.heading => const TextStyle(fontSize: 14, height: 1.2),
    _ => noteBodyStyle,
  };
  // Task and bullet rows lose width to their marker.
  final indent =
      block.kind == NoteBlockKind.task || block.kind == NoteBlockKind.bullet
      ? 22.0 + 8.0 * block.level
      : 0.0;
  final painter = TextPainter(
    text: TextSpan(text: flattenInline(block.text), style: style),
    textDirection: detectTextDirection(block.text),
    maxLines: 6,
  )..layout(maxWidth: (width - indent).clamp(40.0, double.infinity));
  final vertical = block.kind == NoteBlockKind.task ? 20.0 : 14.0;
  // A task row claims the full snap extent even when its text is one short
  // line: slack a row gives up becomes a gap, not a tighter list.
  final floor = block.kind == NoteBlockKind.task ? 46.0 : 24.0;
  return (painter.height + vertical).clamp(floor, 220.0);
}

class _BlockRow extends StatelessWidget {
  final NoteBlock block;
  final double distance;
  final bool checked;
  final AnimationController? pending;
  final VoidCallback? onTap;

  const _BlockRow({
    required this.block,
    required this.distance,
    required this.checked,
    this.pending,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (block.kind != NoteBlockKind.task) {
      return Opacity(
        // Prose recedes with distance like everything else, but never carries
        // the card treatment — it is not a thing you can land on.
        opacity: 1 - distance * 0.45,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: NoteBlockView(block: block),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final dir = detectTextDirection(block.text);
    Widget card = SizedBox(
      // State the card's width and height; never let either be inferred from
      // the text, or identical rows come out different sizes.
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
                      // Pin the line height: left to the font's own metrics a
                      // two-line row lands within a pixel of its extent.
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
/// the thing running out is the thing you would be undoing. The checklists
/// page draws a check the same way.
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
