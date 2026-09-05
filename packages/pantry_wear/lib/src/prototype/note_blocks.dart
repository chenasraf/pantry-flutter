import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import 'note_markdown.dart';

/// PROTOTYPE — one markdown block, drawn at watch size.
///
/// The note page is a focus list of these: prose blocks read as themselves and
/// cannot be landed on, task rows carry the card treatment and commit on the
/// centre line. This is the prose half.
class NoteBlockView extends StatelessWidget {
  final NoteBlock block;

  const NoteBlockView({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final dir = detectTextDirection(block.text);
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
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        );

      case NoteBlockKind.paragraph:
      case NoteBlockKind.literal:
        return Directionality(
          textDirection: dir,
          child: Text.rich(
            TextSpan(children: inlineSpans(block.text, noteBodyStyle)),
          ),
        );

      case NoteBlockKind.bullet:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 8.0 * block.level),
          child: Directionality(
            textDirection: dir,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: 5, end: 6),
                  child: _Dot(),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: inlineSpans(block.text, noteBodyStyle)),
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

const noteBodyStyle = TextStyle(
  fontSize: 12,
  height: 1.32,
  color: Colors.white70,
);

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 3,
    decoration: const BoxDecoration(
      color: Colors.white38,
      shape: BoxShape.circle,
    ),
  );
}
