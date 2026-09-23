import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';

/// Height of the strip the bar puts above the app.
const double kMacTitleBarHeight = 30;

/// Room the window's close / minimise / zoom buttons need at either end. macOS
/// places them itself — at the leading corner of the window, whichever corner
/// that is for the system's language — so the title stays clear of both.
const double _windowButtonGutter = 78;

const double _iconSize = 20;

/// Corner radius as a share of the tile, which is what macOS cuts an app icon
/// to — a smaller one reads as a rounded square and a larger one as a button.
const double _iconCornerRatio = 0.2237;

/// Puts a title bar above [child] on macOS, where the window draws its content
/// under the system chrome and the buttons in its corner would otherwise sit
/// over whatever is at the top of the app.
///
/// Every platform but macOS gets [child] untouched: nothing overlaps there, and
/// a bar naming the window a second time is what the system chrome already says.
class MacTitleBar extends StatelessWidget {
  final Widget child;

  const MacTitleBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!PlatformInfo.isMacOS) return child;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: kMacTitleBarHeight,
          child: Material(
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _windowButtonGutter,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: cs.primary,
                      // The rounded superellipse an app icon is cut to, so the
                      // tile reads as this app's mark and not as a button.
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(
                          _iconSize * _iconCornerRatio,
                        ),
                      ),
                    ),
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      width: _iconSize * 0.66,
                      height: _iconSize * 0.66,
                      // The mark is drawn white on its colour wherever it
                      // appears, the app icon included — the scheme's contrast
                      // pair would flip it to dark on the lighter accents.
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      m.common.appTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
