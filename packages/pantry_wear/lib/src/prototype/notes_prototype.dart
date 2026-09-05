import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'focus_list.dart';
import 'note_markdown.dart';
import 'proto_mechanics.dart';
import 'proto_note_data.dart';
import 'variant_note_blocks.dart';
import 'variant_note_document.dart';
import 'variant_note_tick.dart';

/// PROTOTYPE — the notes page on the wrist, to be judged on a real watch and
/// then thrown away.
///
/// The watch never accepts text. The only write a note has here is flipping a
/// markdown task line, which [toggleChecklistItem] already does in core: it
/// rewrites one character and preserves indentation, marker and the rest of
/// the line. Everything else about a note — writing one, retitling one,
/// editing prose — is a phone job.
///
/// That leaves one question, and the three variants disagree about it: **where
/// does a checkbox live once the note around it is prose you have to read?**
///
///  * **A — Document**: the body flows, checkboxes are tapped where they sit.
///  * **B — Blocks**: every markdown block is a row in the shell's centred-focus
///    list, and only the centred task can be toggled.
///  * **C — Read · tick**: the body is read-only; a *Tick* button pushes the
///    task lines alone as a focus list with a draining undo window.
///
/// **Long-press anywhere on the wall to cycle.** The switcher is a gesture
/// because a permanent bar would spend the width the question is about. The
/// choice is in memory only, as is every toggle — a restart brings the notes
/// back unticked.
class NotesPrototype extends StatefulWidget {
  const NotesPrototype({super.key});

  @override
  State<NotesPrototype> createState() => _NotesPrototypeState();
}

class _NotesPrototypeState extends State<NotesPrototype> {
  static const _labels = [
    ('A', VariantNoteDocument.label),
    ('B', VariantNoteBlocks.label),
    ('C', VariantNoteTick.label),
  ];

  /// Note bodies as raw markdown, rewritten in place by each toggle. Held in a
  /// notifier because a pushed route does not rebuild when the page beneath it
  /// does — the note route has to listen for its own toggles.
  final _bodies = ValueNotifier<Map<int, String>>({
    for (final n in protoNotes) n.id: n.body,
  });

  final _controller = ScrollController();
  final _geometry = ValueNotifier(const FocusGeometry(centredIndex: 0));

  var _variant = 0;
  Timer? _toast;
  var _showToast = false;

  @override
  void dispose() {
    _toast?.cancel();
    _controller.dispose();
    _geometry.dispose();
    _bodies.dispose();
    super.dispose();
  }

  void _cycle() {
    setState(() {
      _variant = (_variant + 1) % _labels.length;
      _showToast = true;
    });
    _toast?.cancel();
    _toast = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  /// The one write the watch has. Note that it rewrites the **whole body** —
  /// which is also what a queued `SyncEntity.note` update carries.
  void _toggle(int noteId, int ordinal) {
    final bodies = Map<int, String>.from(_bodies.value);
    bodies[noteId] = toggleChecklistItem(bodies[noteId]!, ordinal);
    _bodies.value = bodies;
  }

  void _open(ProtoNote note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _NoteRoute(
          note: note,
          bodies: _bodies,
          variant: _variant,
          onToggle: (ordinal) => _toggle(note.id, ordinal),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: GestureDetector(
        onLongPress: _cycle,
        child: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: _bodies,
                builder: (context, bodies, _) => SnapFocusList(
                  controller: _controller,
                  itemExtent: 72,
                  falloffRows: 2.2,
                  // Taller rows sit further from the centre line, where a
                  // round screen has already narrowed, so they hold back from
                  // the bezel roughly twice as far as a checklist card does.
                  horizontalInset: 0.08,
                  rotaryActive: true,
                  geometry: _geometry,
                  elements: [
                    for (var i = 0; i < protoNotes.length; i++)
                      FocusElement(
                        extent: 72,
                        builder: (context, d) => _NoteCard(
                          note: protoNotes[i],
                          body: bodies[protoNotes[i].id]!,
                          distance: d,
                          // The wall inherits the checklist page's rule: only
                          // the centred card opens, an off-centre tap just
                          // scrolls it there.
                          onTap: d < 0.18 ? () => _open(protoNotes[i]) : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const _Rail(),
            if (_showToast)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearShape.isRound ? 30 : 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23232A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_labels[_variant].$1} — ${_labels[_variant].$2}',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.0,
                        color: Colors.white,
                      ),
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

/// The rail the shell puts across the top of every page: what you are looking
/// at, and the sync dot. The variant letter rides here only because this is a
/// prototype.
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: WearShape.isRound ? 20 : 10,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sticky_note_2_outlined,
              size: 13,
              color: Colors.white54,
            ),
            const SizedBox(width: 5),
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A note on the wall.
///
/// Under scope A the card's job changed: ticking is the only thing the watch
/// can do to a note, so a note that holds tasks says how many are left instead
/// of previewing prose the wearer will open it to read anyway.
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
    final blocks = parseNoteBlocks(body);
    final preview = blocks
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

/// One note, pushed over the wall. It needs its own back gesture: route (a)
/// turns off the system dismiss app-wide, so a pushed route inherits no way
/// out at all.
class _NoteRoute extends StatelessWidget {
  final ProtoNote note;
  final ValueNotifier<Map<int, String>> bodies;
  final int variant;
  final void Function(int ordinal) onToggle;

  const _NoteRoute({
    required this.note,
    required this.bodies,
    required this.variant,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: ValueListenableBuilder(
          valueListenable: bodies,
          builder: (context, map, _) {
            final body = map[note.id]!;
            return Stack(
              children: [
                Positioned.fill(
                  child: switch (variant) {
                    0 => VariantNoteDocument(body: body, onToggle: onToggle),
                    1 => VariantNoteBlocks(body: body, onToggle: onToggle),
                    _ => VariantNoteTick(
                      title: note.title,
                      body: body,
                      onToggle: onToggle,
                    ),
                  },
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
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: detectTextDirection(note.title),
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
