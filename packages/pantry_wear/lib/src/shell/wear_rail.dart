import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';

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
/// A rejected credential takes the group label's line and washes the rail
/// behind it. The rail listens for that itself: the shell rebuilds on
/// controller data, and a 401 produces none.
class WearRail extends StatelessWidget {
  final RailTitle title;
  final String? group;
  final IconData? groupIcon;
  final Color? groupColor;
  final int page;
  final int pages;

  /// Tapping the title expands the rail to a single button rather than opening
  /// the switcher outright: a mistap on a rail this small would otherwise cost
  /// the wearer their place.
  final VoidCallback? onTapTitle;
  final VoidCallback? onChangeList;
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
    this.onTapTitle,
    this.onChangeList,
    this.onSetUpAgain,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AuthService.instance.isUnauthorized,
    builder: (context, degraded, _) => _build(context, degraded),
  );

  Widget _build(BuildContext context, bool degraded) {
    final window = dotWindow(pages, page);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: degraded ? _wash : null),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: WearShape.isRound ? 0.68 : 0.92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                // While the state stands the whole rail is its signpost, so a
                // title tap cannot expand the rail over the line that carries
                // it. The switcher costs a page turn until sign-in is renewed.
                onTap: degraded ? onSetUpAgain : onTapTitle,
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
              SizedBox(
                height: 13,
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
                  // The state outranks both of the slot's usual occupants: the
                  // group label is the one rail element that changes as you
                  // scroll, and it is the cheapest thing here to spend.
                  child: degraded
                      ? _DegradedLine(onTap: onSetUpAgain)
                      : expanded
                      ? _ChangeListButton(onTap: onChangeList)
                      : group == null
                      ? const SizedBox.shrink()
                      : Row(
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
                      margin: const EdgeInsetsDirectional.symmetric(
                        horizontal: 2,
                      ),
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
        ),
      ),
    );
  }
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

/// The rejected credential, on the line the group label usually has.
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

class _ChangeListButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ChangeListButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      key: const ValueKey('change-list'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: 1,
          ),
          child: Text(
            m.wear.changeList,
            style: TextStyle(
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
