import 'package:flutter/material.dart';

import 'wear_mechanics.dart';
import 'wear_surfaces.dart';

/// Where the wearer is in a row of pages.
///
/// Bars, not dots: the current page grows into a line so the indicator says
/// *where* you are as well as how many there are, and it animates rather than
/// cutting between the two widths.
///
/// It reads the way the pager moves, which is the **device's** direction — a
/// row running against the swipe that walks it would say the wearer is
/// travelling the wrong way.
class WearPageBars extends StatelessWidget {
  final int page;
  final int pages;

  /// The bar for the page being looked at. Left unset on a surface with a
  /// colour of its own, where the theme accent is one more colour competing
  /// with it.
  final Color? tint;

  const WearPageBars({
    super.key,
    required this.page,
    required this.pages,
    this.tint,
  });

  /// The row's own height.
  static const double extent = 3;

  @override
  Widget build(BuildContext context) {
    final window = dotWindow(pages, page);
    final selected = tint ?? Theme.of(context).colorScheme.primary;
    return Directionality(
      textDirection: systemTextDirection,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < window.count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
              width: i == window.selected ? 14 : 8,
              height: extent,
              decoration: WearSurface.indicator(
                i == window.selected ? selected : Colors.white24,
                radius: 2,
              ),
            ),
        ],
      ),
    );
  }
}
