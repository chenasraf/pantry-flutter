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
  final _listKey = GlobalKey<SnapFocusListState>();

  /// Which row is on the centre line. Read from the list rather than from the
  /// falloff distance handed to a builder: the distance is a rendering value
  /// that several rows can share near the middle, where "is this the focused
  /// row" has exactly one answer.
  final _geometry = ValueNotifier(const FocusGeometry());

  @override
  void dispose() {
    _controller.dispose();
    _geometry.dispose();
    super.dispose();
  }

  /// The checklists page's rule, unchanged: an off-centre tap scrolls that row
  /// to the centre line instead of acting on it, so a mis-aim costs a scroll.
  void _onCardTap(int index, ProtoNote note) {
    if (index != _geometry.value.centredIndex) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    _open(note);
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
      key: _listKey,
      controller: _controller,
      itemExtent: 72,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      rotaryActive: widget.active,
      horizontalInset: widget.tuning.tallSideInset,
      geometry: _geometry,
      elements: [
        for (var i = 0; i < protoNotes.length; i++)
          FocusElement(
            extent: 72,
            builder: (context, d) => _NoteCard(
              note: protoNotes[i],
              body: widget.bodies[protoNotes[i].id]!,
              distance: d,
              onTap: () => _onCardTap(i, protoNotes[i]),
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
///
/// The card is **filled with the note's own colour**, as it is on the phone, so
/// a wearer finds a note by its hue before reading a word of it. Text is black
/// or white by the colour's luminance. The falloff arrives as opacity rather
/// than the checklists page's colour lerp: lerping a hue toward the ground
/// plane would walk it across the luminance threshold mid-scroll and flip the
/// ink from black to white under the wearer's eye.
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

    final ground = note.color ?? kNotePlane;
    final ink = noteInk(ground);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: 1 - distance * 0.45,
          child: SizedBox(
            // State both, always: a Column of Text sizes to its longest line,
            // so short notes would otherwise draw short cards.
            width: double.infinity,
            height: 66,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ground,
                borderRadius: BorderRadius.circular(
                  WearShape.isRound ? 18 : 12,
                ),
              ),
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
                          Icon(
                            Icons.push_pin,
                            size: 11,
                            color: ink.withValues(alpha: 0.6),
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
                              color: ink,
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
                              ink: ink,
                            )
                          : Text(
                              preview.isEmpty ? '—' : preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: detectTextDirection(preview),
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.25,
                                color: ink.withValues(alpha: 0.72),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
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

  /// Progress is drawn in the note's own ink rather than the theme accent: on a
  /// card filled with a user-picked hue, the seeded accent is one more colour
  /// competing with it, and it may be near-invisible against some of them.
  final Color ink;

  const _Progress({required this.done, required this.total, required this.ink});

  @override
  Widget build(BuildContext context) {
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
            fontWeight: complete ? FontWeight.w700 : FontWeight.w400,
            color: ink.withValues(alpha: complete ? 0.95 : 0.8),
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 3,
            backgroundColor: ink.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(ink.withValues(alpha: 0.9)),
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
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

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
    _geometry.dispose();
    super.dispose();
  }

  /// Same rule as the wall and the checklists page: an off-centre task scrolls
  /// to the centre line, and only the row already there is written.
  void _onTaskTap(int index, NoteBlock block) {
    if (index != _geometry.value.centredIndex) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    _fire(block);
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
    // The detail page carries the note's colour edge to edge, so opening a
    // note is continuous with the card it was opened from rather than a drop
    // back onto the app's ground.
    final ground = widget.note.color ?? kNotePlane;
    final ink = noteInk(ground);

    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: ground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth * (1 - inset * 2) - 20;
            return Stack(
              children: [
                Positioned.fill(
                  child: SnapFocusList(
                    key: _listKey,
                    controller: _controller,
                    itemExtent: 46,
                    falloffRows: widget.tuning.falloffRows,
                    snapEnabled: widget.tuning.snapEnabled,
                    rotaryActive: true,
                    horizontalInset: inset,
                    geometry: _geometry,
                    elements: [
                      for (var i = 0; i < blocks.length; i++)
                        FocusElement(
                          extent: _measure(blocks[i], contentWidth),
                          snappable: blocks[i].kind == NoteBlockKind.task,
                          isHeader: blocks[i].kind != NoteBlockKind.task,
                          builder: (context, d) => _BlockRow(
                            block: blocks[i],
                            distance: d,
                            ink: ink,
                            checked:
                                _echo[blocks[i].taskOrdinal] ??
                                blocks[i].checked,
                            pending: _pending[blocks[i].taskOrdinal],
                            onTap: blocks[i].kind == NoteBlockKind.task
                                ? () => _onTaskTap(i, blocks[i])
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
                          colors: [ground, ground.withValues(alpha: 0)],
                        ),
                      ),
                      child: Text(
                        widget.note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(widget.note.title),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          color: ink.withValues(alpha: 0.8),
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
  final Color ink;
  final bool checked;
  final AnimationController? pending;
  final VoidCallback? onTap;

  const _BlockRow({
    required this.block,
    required this.distance,
    required this.ink,
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
          child: NoteBlockView(block: block, ink: ink),
        ),
      );
    }

    final dir = detectTextDirection(block.text);
    Widget card = SizedBox(
      // State the card's width and height; never let either be inferred from
      // the text, or identical rows come out different sizes.
      width: double.infinity,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // A task card is the note's own ink laid thinly over the note's own
          // colour, so it reads on any hue — a fixed dark plane would vanish
          // on a dark note and shout on a light one.
          color: ink.withValues(alpha: 0.16 - distance * 0.07),
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
                  color: ink.withValues(alpha: checked ? 0.9 : 0.55),
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
                      color: ink.withValues(alpha: checked ? 0.45 : 1),
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: ink.withValues(alpha: 0.45),
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
            color: ink,
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
