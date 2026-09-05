import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'focus_list.dart';
import 'note_markdown.dart';
import 'variant_note_document.dart';

/// PROTOTYPE — variant **B**, the note as a focus list of blocks.
///
/// Every markdown block becomes a row in the same centred-focus list the
/// checklist page uses, so the wearer learns one scrolling behaviour for the
/// whole watch and a task line inherits card 715's safety rule unchanged: the
/// centred task commits on tap, an off-centre tap only scrolls it there.
///
/// Prose rows are **not snappable**. A row you cannot act on was never a
/// landing candidate — the same reasoning that keeps a group header out of the
/// snap table. Whether that makes reading a prose-heavy note feel wrong is
/// exactly the thing a wrist has to say.
///
/// It also drags in a cost the checklist page never paid: a fixed-extent list
/// needs every row's height **before** layout, and a paragraph's height is a
/// function of its text and the width it gets. So the blocks are measured with
/// a [TextPainter] against the content width, once, at build.
class VariantNoteBlocks extends StatefulWidget {
  static const label = 'Blocks';

  final String body;
  final void Function(int ordinal) onToggle;

  const VariantNoteBlocks({
    super.key,
    required this.body,
    required this.onToggle,
  });

  @override
  State<VariantNoteBlocks> createState() => _VariantNoteBlocksState();
}

class _VariantNoteBlocksState extends State<VariantNoteBlocks> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = parseNoteBlocks(widget.body);
    final inset = WearShape.isRound ? 0.12 : 0.06;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth * (1 - inset * 2) - 20;
        return SnapFocusList(
          controller: _controller,
          // The snap grid a task line lands on. Prose blocks are taller than
          // this and simply say so through their own extent.
          itemExtent: 44,
          falloffRows: 2.2,
          horizontalInset: inset,
          rotaryActive: true,
          elements: [
            for (final block in blocks)
              FocusElement(
                extent: _measure(block, contentWidth),
                snappable: block.kind == NoteBlockKind.task,
                isHeader: block.kind != NoteBlockKind.task,
                builder: (context, d) => _BlockRow(
                  block: block,
                  distance: d,
                  onToggle: block.kind == NoteBlockKind.task && d < 0.18
                      ? () => widget.onToggle(block.taskOrdinal!)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The height a block needs at [width], plus the padding its row draws.
///
/// A prototype can afford to measure at build; a real page would want this
/// cached against (text, width), since it re-runs for every block on every
/// rebuild of the page.
double _measure(NoteBlock block, double width) {
  final style = switch (block.kind) {
    NoteBlockKind.heading => const TextStyle(fontSize: 14, height: 1.2),
    _ => const TextStyle(fontSize: 12, height: 1.32),
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
  // Task rows claim the full snap extent even when their text is one short
  // line: on a fixed-extent list the slack a row gives up becomes a gap.
  final floor = block.kind == NoteBlockKind.task ? 44.0 : 24.0;
  return (painter.height + vertical).clamp(floor, 220.0);
}

class _BlockRow extends StatelessWidget {
  final NoteBlock block;
  final double distance;
  final VoidCallback? onToggle;

  const _BlockRow({required this.block, required this.distance, this.onToggle});

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

    final centred = onToggle != null;
    final dir = detectTextDirection(block.text);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: SizedBox(
          // State the card's width and height; never let either be inferred
          // from the text, or identical rows come out different sizes.
          width: double.infinity,
          height: 38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF17171A),
                const Color(0xFF121215),
                distance,
              ),
              borderRadius: BorderRadius.circular(WearShape.isRound ? 14 : 10),
              border: centred
                  ? Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.55),
                      width: 1,
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 11),
              child: Directionality(
                textDirection: dir,
                child: Row(
                  children: [
                    Icon(
                      block.checked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 15,
                      color: block.checked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flattenInline(block.text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          // Pin the line height: left to the font's metrics a
                          // two-line row lands within a pixel of its extent.
                          height: 1.18,
                          color: block.checked ? Colors.white38 : Colors.white,
                          decoration: block.checked
                              ? TextDecoration.lineThrough
                              : null,
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
