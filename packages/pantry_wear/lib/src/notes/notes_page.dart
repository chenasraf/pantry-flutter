import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_metrics.dart';
import 'note_blocks.dart';
import 'note_markdown.dart';
import 'note_route.dart';
import 'notes_controller.dart';

/// The notes wall: the household's notes, one card each.
///
/// Notes ride the mirror whole, bodies included, so a note is readable on the
/// wrist without a fetch — and ticking a task line is the one thing the watch
/// can do to one. The watch never accepts text: no dictation, handwriting,
/// keyboard, note creation, retitling or prose editing.
///
/// Because ticking is the only write, a note holding tasks is worth opening
/// for what is left of it, so its card says `n left` with a progress bar
/// instead of previewing prose the wearer would open it to read anyway. Notes
/// without tasks keep the preview.
class NotesPage extends StatefulWidget {
  /// Supplied only by tests, which pump the real tree against a controller
  /// holding a fixed answer. The page starts the one it makes itself.
  final NotesController? controller;

  /// Only the page being looked at may poll or fetch.
  final bool active;

  /// Whether the crown is this wall's to steer: [active], and only while
  /// turning it scrolls rather than turns pages.
  final bool rotary;

  /// Where a refused write is said out loud. The shell owns the one notice
  /// slot, so the page hands its message over rather than drawing a second.
  final void Function(String message)? onNotice;

  const NotesPage({
    super.key,
    this.controller,
    required this.active,
    required this.rotary,
    this.onNotice,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final NotesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NotesController();
    _controller.addListener(_onData);
    if (widget.controller == null) {
      unawaited(_controller.start());
      _controller.setActive(widget.active);
    }
  }

  @override
  void didUpdateWidget(NotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && widget.active != oldWidget.active) {
      _controller.setActive(widget.active);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onData);
    // Only the one this page made: an injected controller outlives it.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onData() {
    if (!mounted) return;
    final dropped = _controller.droppedMessage;
    if (dropped != null) {
      widget.onNotice?.call(dropped);
      _controller.clearDropped();
    }
    setState(() {});
  }

  /// Nothing to draw has two causes, and only one of them is an empty wall.
  String get _emptyMessage => AuthService.instance.isLoggedIn
      ? m.notesWall.noNotes
      : m.wear.notSignedIn;

  @override
  Widget build(BuildContext context) {
    final notes = _controller.notes;
    if (_controller.hasNoScope || notes.isEmpty) {
      return _Empty(message: _emptyMessage);
    }
    return NotesWall(
      controller: _controller,
      notes: notes,
      rotary: widget.rotary,
    );
  }
}

/// The wall itself, as a centred-focus list of note cards.
class NotesWall extends StatefulWidget {
  final NotesController controller;
  final List<Note> notes;

  /// Whether the crown is this wall's to steer.
  final bool rotary;

  const NotesWall({
    super.key,
    required this.controller,
    required this.notes,
    required this.rotary,
  });

  @override
  State<NotesWall> createState() => _NotesWallState();
}

class _NotesWallState extends State<NotesWall> {
  final _scroll = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this wall must take the crown with it. The detent
  /// stream is broadcast and a covered list stays mounted, so without this one
  /// turn of the bezel scrolls both the note on top and the wall underneath.
  var _covered = false;

  @override
  void dispose() {
    _scroll.dispose();
    _geometry.dispose();
    super.dispose();
  }

  /// The checklists page's rule, unchanged: a card that is not on the centre
  /// line scrolls there and nothing opens, so a mis-aim costs a scroll.
  Future<void> _onCardTap(int index, Note note) async {
    if (index != _geometry.value.centredIndex) {
      _listKey.currentState?.centreOn(index);
      return;
    }
    setState(() => _covered = true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteRoute(controller: widget.controller, note: note),
      ),
    );
    if (mounted) setState(() => _covered = false);
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.notes;
    return SnapFocusList(
      key: _listKey,
      controller: _scroll,
      itemExtent: WearMetrics.noteRowExtent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.rotary && !_covered,
      horizontalInset: WearMetrics.tallSideInset,
      geometry: _geometry,
      elements: [
        for (var i = 0; i < notes.length; i++)
          FocusElement(
            extent: WearMetrics.noteRowExtent,
            builder: (context, d) => _NoteCard(
              key: ValueKey('note-${notes[i].id}'),
              note: notes[i],
              progress: widget.controller.progressOf(notes[i]),
              preview: _previewOf(widget.controller.bodyOf(notes[i])),
              distance: d,
              onTap: () => unawaited(_onCardTap(i, notes[i])),
            ),
          ),
      ],
    );
  }
}

/// The prose of a note, flattened into one line. Task lines are left out: a
/// card carrying tasks says what is left of them instead.
String _previewOf(String? body) {
  if (body == null) return '';
  return parseNoteBlocks(body)
      .where((b) => b.kind != NoteBlockKind.task)
      .map((b) => flattenInline(b.text))
      .join(' · ');
}

/// A note on the wall.
///
/// The card is **filled with the note's own colour**, as it is on the phone, so
/// a wearer finds a note by its hue before reading a word of it. Text is black
/// or white by the colour's luminance. The falloff arrives as opacity rather
/// than the checklists page's colour lerp: lerping a hue toward the ground
/// plane would walk it across the luminance threshold mid-scroll and flip the
/// ink from black to white under the wearer's eye.
class _NoteCard extends StatelessWidget {
  final Note note;
  final ({int done, int total}) progress;
  final String preview;
  final double distance;
  final VoidCallback onTap;

  const _NoteCard({
    super.key,
    required this.note,
    required this.progress,
    required this.preview,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ground = parseHexColor(note.color) ?? kNotePlane;
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
            height: WearMetrics.noteCardHeight,
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
                        if (note.isPinned) ...[
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
          complete ? m.wear.allTasksDone : m.wear.tasksLeft(total - done),
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

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
      child: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: detectTextDirection(message),
        style: TextStyle(
          fontSize: 12,
          height: 1.3,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    ),
  );
}
