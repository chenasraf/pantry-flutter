import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'note_markdown.dart';

/// PROTOTYPE — variant **A**, the note as a document.
///
/// The body scrolls as continuous prose, the way it reads on every other
/// surface the household uses, and a task line's checkbox is tapped where it
/// sits. Nothing snaps: a paragraph is not a row, and pretending otherwise is
/// what the other two variants are testing.
///
/// The cost it is here to expose: a checkbox in flowing text is a small target
/// on a wrist, and card 715 bought the checklist page its safety by making the
/// only writable thing the one under the centre line. This variant spends that
/// safety to keep the reading honest.
class VariantNoteDocument extends StatelessWidget {
  static const label = 'Document';

  final String body;

  /// Null makes the document read-only, which is how variant C uses it.
  final void Function(int ordinal)? onToggle;

  const VariantNoteDocument({super.key, required this.body, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final blocks = parseNoteBlocks(body);
    // A round screen's corners are unusable, and a document runs to the very
    // top and bottom of the viewport where the circle is at its narrowest.
    final inset = WearShape.isRound ? 0.14 : 0.07;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth * inset;
        return ListView(
          padding: EdgeInsetsDirectional.only(
            start: side,
            end: side,
            top: constraints.maxHeight * 0.34,
            bottom: constraints.maxHeight * 0.45,
          ),
          children: [
            for (final block in blocks)
              NoteBlockView(block: block, onToggle: onToggle),
          ],
        );
      },
    );
  }
}

/// One markdown block, drawn at watch size. Shared by variants A and C so the
/// reading surface is literally the same one in both.
class NoteBlockView extends StatelessWidget {
  final NoteBlock block;
  final void Function(int ordinal)? onToggle;

  const NoteBlockView({super.key, required this.block, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final dir = detectTextDirection(block.text);
    switch (block.kind) {
      case NoteBlockKind.heading:
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: 12, bottom: 4),
          child: Directionality(
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
          ),
        );

      case NoteBlockKind.paragraph:
      case NoteBlockKind.literal:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8),
          child: Directionality(
            textDirection: dir,
            child: Text.rich(
              TextSpan(children: inlineSpans(block.text, _bodyStyle)),
            ),
          ),
        );

      case NoteBlockKind.bullet:
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: 8.0 * block.level,
            bottom: 5,
          ),
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
                    TextSpan(children: inlineSpans(block.text, _bodyStyle)),
                  ),
                ),
              ],
            ),
          ),
        );

      case NoteBlockKind.task:
        final ordinal = block.taskOrdinal!;
        final enabled = onToggle != null;
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: 8.0 * block.level,
            bottom: 3,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? () => onToggle!(ordinal) : null,
            child: Directionality(
              textDirection: dir,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2, end: 7),
                    child: Icon(
                      block.checked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 15,
                      color: block.checked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white54,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: inlineSpans(
                          block.text,
                          block.checked
                              ? _bodyStyle.copyWith(
                                  color: Colors.white38,
                                  decoration: TextDecoration.lineThrough,
                                )
                              : _bodyStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}

const _bodyStyle = TextStyle(fontSize: 12, height: 1.32, color: Colors.white70);

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
