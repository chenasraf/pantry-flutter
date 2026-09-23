import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_page_bars.dart';

/// The note's name, standing over both of its pages.
///
/// It never takes a pointer, and it names the note on the facts page as well as
/// the body — so neither page repeats it. What a page draws starts below
/// [extentOf], which is the one number keeping the two in step. The band inset
/// a watch page usually starts at will not do it: the inset is a fraction of
/// the glass and this strip's offset is fixed, so on the ~200dp a watch
/// actually reports the band lands **above** the strip and the page is drawn
/// under it. It only clears on a viewport twice that size, which is a test
/// window rather than a wrist.
class NoteHeader extends StatelessWidget {
  final String title;

  /// Which of the route's two pages is in front.
  final int page;

  /// The note's own ink and ground. On a page filled with a user-picked hue
  /// the seeded accent is one more colour competing with it, and against some
  /// of them it is close to invisible.
  final Color ink;
  final Color ground;

  const NoteHeader({
    super.key,
    required this.title,
    required this.page,
    required this.ink,
    required this.ground,
  });

  /// Where the strip sits, which is lower on round glass: at the top of a
  /// circle the width has already closed in around it.
  static double get _top => WearShape.isRound ? 20 : 10;

  static const _padding = EdgeInsetsDirectional.symmetric(
    horizontal: 40,
    vertical: 4,
  );

  static const _titleSize = 12.0;
  static const _titleGap = 4.0;

  /// How much of the top of the screen the strip claims.
  static double extentOf(BuildContext context) =>
      _top +
      _padding.vertical +
      _titleSize * WearMetrics.of(context).scale +
      _titleGap +
      WearPageBars.extent;

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    start: 0,
    end: 0,
    top: _top,
    child: IgnorePointer(
      child: Container(
        padding: _padding,
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
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(title),
              style: TextStyle(
                fontSize: _titleSize,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: ink.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: _titleGap),
            WearPageBars(
              page: page,
              pages: 2,
              tint: ink.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    ),
  );
}
