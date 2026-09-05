import 'package:flutter/material.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'note_blocks.dart';
import 'note_markdown.dart';
import 'notes_controller.dart';

/// One note, pushed over the wall: a focus list of markdown blocks.
///
/// Task rows are the only snappable ones, so Q19's rule carries over unchanged
/// — the centred task commits on tap, an off-centre tap only scrolls it there.
/// A row you cannot act on was never a landing candidate, which is the same
/// reasoning that keeps a group header out of the snap table.
///
/// The page is drawn edge to edge in the note's own colour, so opening a note
/// is continuous with the card it came from rather than a drop back onto the
/// app's ground.
///
/// It needs its own back gesture: route (a) turns off the system dismiss
/// app-wide, so a pushed route inherits no way out at all.
class NoteRoute extends StatefulWidget {
  final NotesController controller;
  final Note note;

  const NoteRoute({super.key, required this.controller, required this.note});

  @override
  State<NoteRoute> createState() => _NoteRouteState();
}

class _NoteRouteState extends State<NoteRoute> with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());
  final _metrics = NoteBlockMetrics();

  /// Ticks that have fired but not yet run out their undo window, keyed by
  /// task ordinal, exactly as a check is held on the checklists page.
  final _pending = <int, AnimationController>{};

  /// The state each in-flight tick is heading for, so the row draws its new
  /// value while the window drains. Once the window runs out the write is
  /// queued and the queue overlay draws it instead.
  final _echo = <int, bool>{};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onData);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onData);
    for (final c in _pending.values) {
      c.dispose();
    }
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  /// A pushed route does not rebuild when the page beneath it does, so the note
  /// would go stale under the wearer while a snapshot lands.
  void _onData() {
    if (mounted) setState(() {});
  }

  /// The note as the controller currently holds it — the wall's list is the one
  /// source, so a mirrored snapshot reaches the open note too.
  Note get _note => widget.controller.notes.firstWhere(
    (n) => n.id == widget.note.id,
    orElse: () => widget.note,
  );

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
    // The line as the page drew it, carried into the write so it follows this
    // line rather than this position when another is inserted above it. Held
    // here rather than re-read at drain, which would defeat the point.
    final text = block.text;
    final controller = AnimationController(
      vsync: this,
      duration: WearMetrics.undoWindow,
    )..reverse(from: 1);
    controller.addStatusListener((status) {
      if (status != AnimationStatus.dismissed || !mounted) return;
      controller.dispose();
      _pending.remove(ordinal);
      _echo.remove(ordinal);
      widget.controller.setTaskLine(
        _note,
        ordinal: ordinal,
        text: text,
        checked: target,
      );
      setState(() {});
    });
    setState(() {
      _pending[ordinal] = controller;
      _echo[ordinal] = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final blocks = parseNoteBlocks(widget.controller.bodyOf(note) ?? '');
    const inset = WearMetrics.tallSideInset;
    final ground = parseHexColor(note.color) ?? kNotePlane;
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
                    controller: _scroll,
                    itemExtent: kTaskRowExtent,
                    falloffRows: WearMetrics.falloffRows,
                    rotaryActive: true,
                    horizontalInset: inset,
                    geometry: _geometry,
                    elements: [
                      for (var i = 0; i < blocks.length; i++)
                        FocusElement(
                          extent: _metrics.extentOf(blocks[i], contentWidth),
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
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(note.title),
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
      height: kTaskRowExtent - 6,
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
