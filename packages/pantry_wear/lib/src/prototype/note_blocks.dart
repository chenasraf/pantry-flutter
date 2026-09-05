import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import 'note_markdown.dart';

/// The ground a note draws on: its own colour, or the card plane when the user
/// never gave it one.
const kNotePlane = Color(0xFF17171A);

/// Black or white, whichever the note's colour can carry — the same rule the
/// phone's note tile uses, so a note reads the same on both.
Color noteInk(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

/// PROTOTYPE — one markdown block, drawn at watch size.
///
/// The note page is a focus list of these: prose blocks read as themselves and
/// cannot be landed on, task rows carry the card treatment and commit on the
/// centre line. This is the prose half.
///
/// [ink] rather than a fixed colour, because a note is drawn on its own hue and
/// a light one needs dark text.
class NoteBlockView extends StatelessWidget {
  final NoteBlock block;
  final Color ink;

  const NoteBlockView({super.key, required this.block, required this.ink});

  @override
  Widget build(BuildContext context) {
    final dir = detectTextDirection(block.text);
    final body = noteBodyStyle.copyWith(color: ink.withValues(alpha: 0.78));

    switch (block.kind) {
      case NoteBlockKind.heading:
        return Directionality(
          textDirection: dir,
          child: Text.rich(
            TextSpan(
              children: inlineSpans(
                block.text,
                TextStyle(
                  fontSize: block.level == 1 ? 15 : 13,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        );

      case NoteBlockKind.paragraph:
      case NoteBlockKind.literal:
        return Directionality(
          textDirection: dir,
          child: Text.rich(TextSpan(children: inlineSpans(block.text, body))),
        );

      case NoteBlockKind.bullet:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 8.0 * block.level),
          child: Directionality(
            textDirection: dir,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 5, end: 6),
                  child: _Dot(color: ink.withValues(alpha: 0.45)),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: inlineSpans(block.text, body)),
                  ),
                ),
              ],
            ),
          ),
        );

      // A task line is never drawn here: it is a card on the focus list, not
      // prose, and it is the only thing on the page that can be acted on.
      case NoteBlockKind.task:
        return const SizedBox.shrink();
    }
  }
}

/// Metrics only — the colour is supplied per note. Kept const so the block
/// measuring pass can lay text out without building a style per call.
const noteBodyStyle = TextStyle(fontSize: 12, height: 1.32);

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 3,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
