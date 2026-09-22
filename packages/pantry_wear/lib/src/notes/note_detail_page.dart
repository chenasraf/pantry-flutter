import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/models/note_link.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../widgets/wear_detail.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_scroll_indicator.dart';
import 'note_blocks.dart';

/// What is known about one note, and the hand-off to the phone.
///
/// A note's body says what it is for; nothing in it says who wrote it, when it
/// was last touched, or how far through its tasks the household is — and on a
/// shared wall those are the questions a body cannot answer. It is the note
/// route's second page, and a press and hold on a wall card is the way straight
/// to it.
///
/// Drawn in the note's own ink over the note's own colour, like every other
/// surface a note appears on, so paging across from the body is one screen
/// rather than two.
class NoteDetailPage extends StatefulWidget {
  final Note note;

  /// Done and total task lines, as the wall's card counts them.
  final ({int done, int total}) progress;

  /// Whether the crown is this page's to scroll. False while the wearer is
  /// reading the body on the page beside it.
  final bool rotary;

  const NoteDetailPage({
    super.key,
    required this.note,
    required this.progress,
    this.rotary = true,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final progress = widget.progress;
    final ground = parseHexColor(note.color) ?? kNotePlane;
    final ink = noteInk(ground);
    // Written and last touched are the same moment on a note nobody has edited
    // since, and a row that says so twice is a row that says nothing.
    final edited = note.updatedAt > note.createdAt;
    final complete = progress.done == progress.total;

    return RotaryScrollable(
      controller: _scroll,
      active: widget.rotary,
      child: WearScrollIndicator(
        child: ListView(
          controller: _scroll,
          padding: WearMetrics.bandInsets(context),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (note.isPinned) ...[
                  Icon(
                    Icons.push_pin,
                    size: 13,
                    color: ink.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    note.title,
                    textAlign: TextAlign.center,
                    textDirection: detectTextDirection(note.title),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                // Reassurance that this is the same text the wearer keeps in
                // Notes, and nothing more: the path names a file the watch
                // cannot open, and a file out of reach is a prompt to go fix
                // something on a device that cannot.
                if (note.isSynced) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.sync_alt,
                    size: 13,
                    color: ink.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            WearFact(
              ink: ink,
              label: m.wear.addedBy,
              value: EntityChip(
                textColor: ink,
                label: note.createdBy,
                leading: Icon(Icons.person, size: 12, color: ink),
              ),
            ),
            // The relative time is the one read at a glance; the exact moment
            // under it is the one that tells two days of the same week apart.
            WearFact(
              ink: ink,
              label: m.wear.added,
              value: EntityChip(
                textColor: ink,
                label: relativeTime(note.createdAt),
              ),
              note: formatDateTime(note.createdAt),
            ),
            if (edited)
              WearFact(
                ink: ink,
                label: m.wear.updated,
                value: EntityChip(
                  textColor: ink,
                  label: relativeTime(note.updatedAt),
                ),
                note: formatDateTime(note.updatedAt),
              ),
            if (progress.total > 0)
              WearFact(
                ink: ink,
                label: m.wear.tasks,
                value: EntityChip(
                  textColor: ink,
                  label: complete
                      ? m.wear.allTasksDone
                      : m.wear.tasksLeft(progress.total - progress.done),
                  leading: Icon(
                    complete ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 12,
                    color: ink,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OpenOnPhoneButton(
              url: NoteLink.uri(note.houseId, note.id).toString(),
              ink: ink,
            ),
          ],
        ),
      ),
    );
  }
}
