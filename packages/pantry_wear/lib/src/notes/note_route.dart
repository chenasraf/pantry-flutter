import 'package:flutter/material.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_page_bars.dart';
import 'note_blocks.dart';
import 'note_detail_page.dart';
import 'note_markdown.dart';
import 'notes_controller.dart';

/// One note, pushed over the wall: the body, and beside it what is known about
/// the note itself.
///
/// The body is a focus list of markdown blocks. Task rows are the only
/// snappable ones, so the commit-on-centre rule carries over — the centred task
/// commits on tap, an off-centre tap only scrolls it there. A row you cannot
/// act on was never a landing candidate, which is the same reasoning that keeps
/// a group header out of the snap table.
///
/// The second page is the note's own facts and the hand-off to the phone. It is
/// a page rather than a route because the wearer gets at it two ways — paging
/// across from the body, or holding a card on the wall — and both want the
/// other half a swipe away rather than a level down.
///
/// Both pages are drawn edge to edge in the note's own colour, so opening a
/// note is continuous with the card it came from and paging across is one
/// screen rather than two.
///
/// It needs its own back gesture: route (a) turns off the system dismiss
/// app-wide, so a pushed route inherits no way out at all. The pager's own edge
/// strip is that gesture, which is why the route does not carry a second one —
/// on the body it leaves, and on the facts it pages back to the body first.
class NoteRoute extends StatefulWidget {
  final NotesController controller;
  final Note note;

  /// Which page the route opens on: the body, or the note's own facts. A hold
  /// on a wall card asks for the second.
  final int initialPage;

  const NoteRoute({
    super.key,
    required this.controller,
    required this.note,
    this.initialPage = 0,
  });

  @override
  State<NoteRoute> createState() => _NoteRouteState();
}

class _NoteRouteState extends State<NoteRoute> with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());
  final _metrics = NoteBlockMetrics();

  late final PageController _pager = PageController(
    initialPage: widget.initialPage,
  );
  late var _page = widget.initialPage;

  /// Ticks that have fired but not yet run out their undo window, keyed by
  /// task ordinal, on the mechanism a check is held by everywhere else. Once a
  /// window runs out the write is queued and the queue overlay draws it
  /// instead.
  late final UndoWindows<int> _pending;

  @override
  void initState() {
    super.initState();
    _pending = UndoWindows(
      vsync: this,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    widget.controller.addListener(_onData);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onData);
    _pending.dispose();
    _pager.dispose();
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

  /// Same rule as the wall and the checklists page: a task the wearer was only
  /// aiming at comes within reach, and only a row already there is written.
  void _onTaskTap(int index, NoteBlock block) {
    final list = _listKey.currentState;
    if (list == null || !list.canActOn(index)) {
      list?.reveal(index);
      return;
    }
    _fire(block);
  }

  void _fire(NoteBlock block) {
    final ordinal = block.taskOrdinal!;
    // The line as the page drew it, carried into the write so it follows this
    // line rather than this position when another is inserted above it. Held
    // here rather than re-read at drain, which would defeat the point.
    final text = block.text;
    _pending.fire(
      ordinal,
      target: !block.checked,
      commit: (checked) => widget.controller.setTaskLine(
        _note,
        ordinal: ordinal,
        text: text,
        checked: checked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final ground = parseHexColor(note.color) ?? kNotePlane;
    final ink = noteInk(ground);

    return Scaffold(
      backgroundColor: ground,
      body: Stack(
        children: [
          Positioned.fill(
            child: EdgeAwarePageView(
              controller: _pager,
              page: _page,
              onPageChanged: (p) => setState(() => _page = p),
              onDismiss: () => Navigator.of(context).pop(),
              children: [
                _body(note, ink),
                NoteDetailPage(
                  note: note,
                  progress: widget.controller.progressOf(note),
                  rotary: _page == 1,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                    const SizedBox(height: 4),
                    // In the note's own ink rather than the theme accent: on a
                    // page filled with a user-picked hue the seeded accent is
                    // one more colour competing with it, and against some of
                    // them it is close to invisible.
                    WearPageBars(
                      page: _page,
                      pages: 2,
                      tint: ink.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The note's prose and tasks, as a focus list of markdown blocks.
  Widget _body(Note note, Color ink) {
    const inset = WearMetrics.tallSideInset;
    final blocks = parseNoteBlocks(widget.controller.bodyOf(note) ?? '');
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth * (1 - inset * 2) - 20;
        return SnapFocusList(
          key: _listKey,
          controller: _scroll,
          itemExtent: kTaskRowExtent,
          falloffRows: WearMetrics.falloffRows,
          // The crown belongs to the page in front of the wearer. The pager
          // keeps both mounted and the detent stream is broadcast, so without
          // this one turn scrolls the body and the facts at once.
          rotaryActive: _page == 0,
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
                      _pending.targetOf(blocks[i].taskOrdinal) ??
                      blocks[i].checked,
                  pending: _pending.controllerOf(blocks[i].taskOrdinal),
                  onTap: blocks[i].kind == NoteBlockKind.task
                      ? () => _onTaskTap(i, blocks[i])
                      : null,
                ),
              ),
          ],
        );
      },
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

    card = UndoStroke(
      window: pending,
      color: ink,
      radius: WearShape.isRound ? 15 : 10,
      strokeWidth: 1.6,
      child: card,
    );

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
