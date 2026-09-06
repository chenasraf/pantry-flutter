import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';

/// What the rail says you are looking at.
typedef RailTitle = ({String label, IconData icon, Color color});

/// The list (or, in a session, the store), the focused card's group, sync and
/// the page indicator.
///
/// The house is deliberately absent: one household is the overwhelming case,
/// so naming it every frame spends the rail's scarcest line on something that
/// almost never changes. It lives on the account page, beside the control that
/// switches it.
///
/// The group label is the sticky half of the header: the header itself scrolls
/// up as an ordinary short row, and the rail takes it over as it slides under.
///
/// Expanded, the rail takes height of its own rather than borrowing the
/// group label's line: a button a wearer aims at cannot be 13 logical pixels
/// tall. It grows downward over the list, so the centre line the focus falloff
/// measures from never moves.
///
/// A rejected credential washes the rail and takes a line above the buttons.
/// The rail listens for that itself: the shell rebuilds on controller data, and
/// a 401 produces none.
class WearRail extends StatelessWidget {
  final RailTitle title;
  final String? group;
  final IconData? groupIcon;
  final Color? groupColor;
  final int page;
  final int pages;

  /// The height the rail occupies collapsed. Expansion is added to it here,
  /// so the shell has one number to give and the rail owns what it spends.
  final double baseHeight;

  /// Tapping the title expands the rail to its buttons rather than acting
  /// outright: a mistap on a rail this small would otherwise cost the wearer
  /// their place.
  final VoidCallback? onTapTitle;
  final VoidCallback? onChangeList;

  /// Null in a session, which has a progression page of its own and no trip to
  /// start.
  final VoidCallback? onStartShopping;
  final bool expanded;

  /// Where the degraded line points. Tapping it is a page turn, not a pairing
  /// flow: the line is a signpost, and *Set up again* is a full-size button
  /// beside the identity it concerns.
  final VoidCallback? onSetUpAgain;

  const WearRail({
    super.key,
    required this.title,
    required this.group,
    required this.groupIcon,
    required this.groupColor,
    required this.page,
    required this.pages,
    required this.baseHeight,
    this.onTapTitle,
    this.onChangeList,
    this.onStartShopping,
    this.onSetUpAgain,
    this.expanded = false,
  });

  /// What the expansion costs on top of [baseHeight]. The buttons replace the
  /// group label's line; a degraded state keeps a line of its own above them,
  /// which is what makes the switcher reachable while the state stands.
  static double extentFor({required bool expanded, required bool degraded}) {
    if (!expanded) return 0;
    final buttons = WearMetrics.railButtonExtent - WearMetrics.railLineExtent;
    if (!degraded) return buttons;
    return buttons + WearMetrics.railLineExtent + WearMetrics.railStackGap;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AuthService.instance.isUnauthorized,
    builder: (context, degraded, _) => _build(context, degraded),
  );

  Widget _build(BuildContext context, bool degraded) {
    final window = dotWindow(pages, page);
    // Collapsed the buttons are absent, so the line the group label usually
    // has is the state's; expanded it takes one of its own above them.
    final slot = expanded
        ? WearMetrics.railButtonExtent
        : degraded
        ? 0.0
        : WearMetrics.railLineExtent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: baseHeight + extentFor(expanded: expanded, degraded: degraded),
      decoration: BoxDecoration(
        color: wearGround,
        gradient: degraded ? _wash : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _bounded(
            GestureDetector(
              onTap: onTapTitle,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SyncDot(),
                  const SizedBox(width: 6),
                  Icon(title.icon, size: 12, color: title.color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: detectTextDirection(title.label),
                      style: TextStyle(
                        fontSize: 11,
                        color: title.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (degraded)
            _bounded(
              SizedBox(
                height: WearMetrics.railLineExtent,
                child: _DegradedLine(onTap: onSetUpAgain),
              ),
            ),
          if (degraded && expanded)
            const SizedBox(height: WearMetrics.railStackGap),
          if (slot > 0)
            SizedBox(
              height: slot,
              // Driven by the label changing, not by a header's distance from
              // the centre line. Those are different events: the header starts
              // approaching while the last row of the outgoing group is still
              // focused, so a geometric transition began a row early and had
              // nothing left to play when the new label actually arrived.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.7),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: expanded
                    ? _bounded(
                        _RailButtons(
                          onStart: onStartShopping,
                          onChangeList: onChangeList,
                        ),
                        // The buttons sit lower than the title, where a round
                        // screen is already wider, and two labels need every
                        // pixel of it.
                        factor: WearShape.isRound ? 0.90 : 0.96,
                      )
                    : group == null
                    ? const SizedBox.shrink()
                    : _bounded(
                        Row(
                          key: ValueKey(group),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (groupIcon != null) ...[
                              Icon(
                                groupIcon,
                                size: 10,
                                color: groupColor ?? Colors.white38,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                group!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: detectTextDirection(group!),
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.1,
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w700,
                                  color: groupColor ?? Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 3),
          // Bars, not dots: the current page grows into a line so the
          // indicator says *where* you are as well as how many there are,
          // and it animates rather than cutting between the two widths.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < window.count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
                  width: i == window.selected ? 14 : 8,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i == window.selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white24,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Held back from the glass by however much the row's own height needs. Each
  /// line answers for itself rather than the rail taking one width: the title
  /// rides high on a round screen where the chord is short, and the buttons
  /// sit lower where it is not.
  Widget _bounded(Widget child, {double? factor}) => FractionallySizedBox(
    widthFactor: factor ?? (WearShape.isRound ? 0.68 : 0.92),
    child: child,
  );
}

/// Behind the whole rail, and fading out before it ends: a 9pt line needs a
/// ground under it to read as a state rather than one more label, and a flat
/// fill would meet a round screen as a hard chord under the page indicator.
const _wash = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x8C2A1D1D), Color(0x8C2A1D1D), Color(0x002A1D1D)],
  stops: [0, 0.72, 1],
);

/// The rejected credential, on a line of its own above whatever else the rail
/// is carrying.
///
/// The wording is the phone's — 15 characters, already translated, and exactly
/// right. Only the account page's body splits, that one being phone-length
/// prose.
class _DegradedLine extends StatelessWidget {
  final VoidCallback? onTap;

  const _DegradedLine({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = m.common.sessionExpiredTitle;
    return GestureDetector(
      key: const ValueKey('degraded-line'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 10, color: wearNoticeInk),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(label),
              style: const TextStyle(
                fontSize: 9,
                height: 1.1,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: wearNoticeInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Queue depth, and nothing else. Whether the watch believes it is online is a
/// different question from whether it is holding writes, and only the second
/// is something the wearer can act on.
class _SyncDot extends StatelessWidget {
  const _SyncDot();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SyncManager.instance.pendingCount,
      builder: (context, queued, _) {
        if (queued == 0) {
          return Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_queue, size: 10, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              m.wear.queued(queued),
              style: const TextStyle(fontSize: 9, color: Colors.white54),
            ),
          ],
        );
      },
    );
  }
}

/// What the expansion is for: the trip you could start, and the list you could
/// be looking at instead.
///
/// Ranked rather than equal — starting a trip is the thing a wearer standing in
/// a doorway came here for, and switching lists is the thing they do once.
class _RailButtons extends StatelessWidget {
  final VoidCallback? onStart;
  final VoidCallback? onChangeList;

  const _RailButtons({required this.onStart, required this.onChangeList});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (onStart != null)
        Flexible(
          child: _RailButton(
            key: const ValueKey('start-shopping'),
            icon: Icons.shopping_cart_checkout,
            label: m.shopping.startShopping,
            primary: true,
            onTap: onStart,
          ),
        ),
      if (onStart != null && onChangeList != null) const SizedBox(width: 5),
      if (onChangeList != null)
        Flexible(
          child: _RailButton(
            key: const ValueKey('change-list'),
            label: m.wear.changeList,
            primary: false,
            onTap: onChangeList,
          ),
        ),
    ],
  );
}

class _RailButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _RailButton({
    super.key,
    this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = primary ? scheme.primary : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: primary
              ? scheme.primary.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(WearMetrics.railButtonExtent / 2),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: ink),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: detectTextDirection(label),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: ink,
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
