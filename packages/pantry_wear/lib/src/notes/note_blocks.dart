import 'package:flutter/material.dart';

import 'package:pantry_core/utils/text_direction.dart';

import 'note_markdown.dart';
import '../widgets/wear_surfaces.dart';

/// The ground a note draws on: its own colour, or the card plane when the user
/// never gave it one.
const kNotePlane = Color(0xFF17171A);

/// Black or white, whichever the note's colour can carry — the same rule the
/// phone's note tile uses, so a note reads the same on both.
Color noteInk(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

/// Metrics only — the colour is supplied per note. Kept const so the block
/// measuring pass can lay text out without building a style per call.
const noteBodyStyle = TextStyle(fontSize: 12, height: 1.32);

const _headingStyle = TextStyle(fontSize: 14, height: 1.2);

/// The extent a task row claims, however short its text.
const kTaskRowExtent = 46.0;

/// One markdown block, drawn at watch size.
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

/// The height each block needs at a given content width.
///
/// A cost the checklists page never paid: its rows were uniform by
/// construction, where a paragraph's height is a function of its text and the
/// width it gets. Measuring runs for every block on every rebuild, so the
/// answers are held against `(text, width)` — the width is part of the key
/// rather than a reason to invalidate, so a rotation or a shape change simply
/// starts filling a second set.
class NoteBlockMetrics {
  final _heights = <_MetricKey, double>{};

  /// Beyond this the map is holding answers for notes the wearer has long
  /// since scrolled past. Nothing here is expensive to recompute.
  static const _limit = 512;

  double extentOf(NoteBlock block, double width) {
    final key = _MetricKey(block.kind, block.text, block.level, width);
    final held = _heights[key];
    if (held != null) return held;

    final style = block.kind == NoteBlockKind.heading
        ? _headingStyle
        : noteBodyStyle;
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
    // line: slack a row gives up becomes a gap, not a tighter list. The rows
    // around it are deliberately variable, which is what makes this one easy
    // to talk yourself out of.
    final floor = block.kind == NoteBlockKind.task ? kTaskRowExtent : 24.0;
    final extent = (painter.height + vertical).clamp(floor, 220.0);
    painter.dispose();

    if (_heights.length >= _limit) _heights.clear();
    _heights[key] = extent;
    return extent;
  }
}

@immutable
class _MetricKey {
  final NoteBlockKind kind;
  final String text;
  final int level;
  final double width;

  const _MetricKey(this.kind, this.text, this.level, this.width);

  @override
  bool operator ==(Object other) =>
      other is _MetricKey &&
      other.kind == kind &&
      other.text == text &&
      other.level == level &&
      other.width == width;

  @override
  int get hashCode => Object.hash(kind, text, level, width);
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 3, height: 3, decoration: WearSurface.indicator(color));
}
