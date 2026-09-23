import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef NavDestination = ({IconData icon, String label});

/// One entry in the trailing button's fan-out menu.
typedef NavMenuAction = ({IconData icon, String label, VoidCallback onTap});

/// The action the active section contributes to the nav's trailing button.
///
/// [menu] turns the button into a fan-out: tapping it reveals the entries above
/// the bar instead of firing [onTap].
class NavPrimaryAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final List<NavMenuAction> menu;

  /// Draws the button as a labelled pill rather than a circle, for an action
  /// whose state the label is carrying (a shopping trip already in progress,
  /// say).
  final bool extended;

  const NavPrimaryAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.menu = const [],
    this.extended = false,
  });

  // Sections re-offer their action on every build, and each offer carries
  // freshly-built closures. Comparing those would make every offer a change,
  // and the change rebuilds the section that raised it — so equality is over
  // what the user can see, and an unchanged offer is silently dropped.
  @override
  bool operator ==(Object other) =>
      other is NavPrimaryAction &&
      other.icon == icon &&
      other.label == label &&
      other.extended == extended &&
      other.menu.length == menu.length &&
      Iterable<int>.generate(menu.length).every(
        (i) =>
            other.menu[i].icon == menu[i].icon &&
            other.menu[i].label == menu[i].label,
      );

  @override
  int get hashCode => Object.hash(
    icon,
    label,
    extended,
    Object.hashAll([for (final a in menu) Object.hash(a.icon, a.label)]),
  );
}

/// How much of the bottom edge the active section has taken for itself.
enum NavEdgeClaim {
  /// Nothing sits along the bottom edge; the nav has the strip to itself.
  none,

  /// A resting bar of the section's own runs along the edge. Where the nav is
  /// a lone button — beside a rail — the two share the row; where it is the
  /// full bar, it keeps its place above.
  shared,

  /// A focused compose bar or a selection action bar owns the edge, and the
  /// nav slides out of the way.
  whole,
}

/// Width the nav's trailing button takes at the end of the bottom row, for a
/// section sharing that row to keep clear of. Zero where the nav keeps the row
/// to itself.
class FloatingNavEdge extends InheritedWidget {
  final double end;

  const FloatingNavEdge({super.key, required this.end, required super.child});

  static double endOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FloatingNavEdge>()?.end ?? 0;

  @override
  bool updateShouldNotify(FloatingNavEdge oldWidget) => oldWidget.end != end;
}

/// Height the floating bar occupies above the bottom safe-area inset. Content
/// under the bar reserves this much so its last row stays reachable.
const double kFloatingNavReserve =
    _barHeight + _barMarginTop + _barMarginBottom;

const double _barHeight = 56;
const double _barMarginTop = 8;
const double _barMarginBottom = 12;
const double _barMarginSide = 12;
const double _gap = 8;
const double _slotWidth = 48;
const double _pillPadding = 6;
const double _slotGap = 10;

/// Room between the active destination's label and the next slot.
const double _labelGap = 16;

/// Floating navigation bar: a stadium pill of destinations with the active
/// section's primary action in a button beside it, laid over the page content.
///
/// With fewer than two destinations there is nothing to switch between and the
/// pill is dropped, leaving the primary action alone at the trailing edge —
/// which is also how the wide layout shows it, next to a navigation rail.
///
/// Fills its parent so an open fan-out menu can scrim the whole screen; only
/// the bar itself and an open menu take hits.
class HomeFloatingNav extends StatefulWidget {
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;
  final NavPrimaryAction? action;

  /// Endpoints of a move that skips over destinations, while one is running.
  /// The indicator then travels between those two alone, leaving the
  /// destinations it passes over untouched.
  final ValueListenable<({int from, int to})?>? jump;

  /// False while the active section has claimed the bottom edge for itself —
  /// a focused compose bar or a selection action bar — and the nav slides out
  /// of its way.
  final bool visible;

  /// Slot the trailing button's width, plus the gap beside it, is published
  /// into as it is laid out. An extended button is as wide as its label, so
  /// what a section must keep clear of is only knowable once drawn.
  final ValueNotifier<double>? footprintHolder;

  const HomeFloatingNav({
    super.key,
    required this.pageController,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
    required this.action,
    this.jump,
    this.visible = true,
    this.footprintHolder,
  });

  @override
  State<HomeFloatingNav> createState() => _HomeFloatingNavState();
}

class _HomeFloatingNavState extends State<HomeFloatingNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menuController;
  bool _menuOpen = false;
  final GlobalKey _actionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(HomeFloatingNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The menu belongs to the section that offered it; swiping away from that
    // section leaves an open fan with nothing behind it.
    if (widget.action?.menu != oldWidget.action?.menu || !widget.visible) {
      _closeMenu();
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _menuController.reverse();
  }

  void _publishFootprint() {
    final holder = widget.footprintHolder;
    if (holder == null) return;
    final box = _actionKey.currentContext?.findRenderObject() as RenderBox?;
    final footprint = box != null && box.hasSize ? box.size.width + _gap : 0.0;
    if (holder.value != footprint) holder.value = footprint;
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final hasMenu = action != null && action.menu.isNotEmpty;
    final showPill = widget.destinations.length > 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishFootprint();
    });

    if (!showPill && action == null) return const SizedBox.shrink();

    return PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menuOpen) _closeMenu();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_menuOpen,
              child: AnimatedOpacity(
                opacity: _menuOpen ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMenu,
                  child: const ColoredBox(color: Color(0x66000000)),
                ),
              ),
            ),
          ),
          Align(
            alignment: showPill
                ? Alignment.bottomCenter
                : AlignmentDirectional.bottomEnd,
            child: AnimatedSlide(
              offset: widget.visible ? Offset.zero : const Offset(0, 1.4),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: widget.visible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      _barMarginSide,
                      _barMarginTop,
                      _barMarginSide,
                      _barMarginBottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (hasMenu)
                          for (var i = 0; i < action.menu.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FanAction(
                                action: action.menu[i],
                                controller: _menuController,
                                index: action.menu.length - 1 - i,
                                total: action.menu.length,
                                onTap: _closeMenu,
                              ),
                            ),
                        Row(
                          mainAxisSize: showPill
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Loose, so the pill takes only the width its
                            // destinations need and the free space falls
                            // between it and the button — but still bounded, so
                            // a long label is capped rather than overflowing.
                            if (showPill) Flexible(child: _buildPill(context)),
                            if (action != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: _gap,
                                ),
                                child: _TrailingButton(
                                  key: _actionKey,
                                  action: action,
                                  menuController: _menuController,
                                  onTap: hasMenu ? _toggleMenu : action.onTap,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// How selected destination [i] is, at fractional page [page]: 1 where the
  /// indicator has settled, 0 where it isn't, and the values between while it
  /// travels — so a swipe carries the indicator and the label with it.
  ///
  /// A move that skips destinations runs between its own endpoints instead.
  /// Read off the page, the ones in between would each reach full selection as
  /// the page passed over them, expanding and collapsing in turn.
  double _selectionOf(int i, double page) {
    final jump = widget.jump?.value;
    if (jump != null) {
      final progress = ((page - jump.from) / (jump.to - jump.from)).clamp(
        0.0,
        1.0,
      );
      if (i == jump.to) return progress;
      if (i == jump.from) return 1 - progress;
      return 0;
    }
    return 1.0 - (page - i).abs().clamp(0.0, 1.0);
  }

  Widget _buildPill(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      elevation: 3,
      shadowColor: Colors.black26,
      surfaceTintColor: cs.surfaceTint,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // What is left for the active destination's label once every slot
            // has its icon. Caps the label so a long translation ellipsizes
            // instead of pushing the pill past the button beside it.
            final maxLabelWidth = math.max(
              0.0,
              constraints.maxWidth -
                  _slotWidth * widget.destinations.length -
                  _slotGap * (widget.destinations.length - 1) -
                  _pillPadding * 2 -
                  _labelGap,
            );
            return AnimatedBuilder(
              animation: Listenable.merge([widget.pageController, widget.jump]),
              builder: (context, _) {
                final page = widget.pageController.hasClients
                    ? (widget.pageController.page ??
                          widget.currentIndex.toDouble())
                    : widget.currentIndex.toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _pillPadding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: _slotGap,
                    children: [
                      for (var i = 0; i < widget.destinations.length; i++)
                        _NavSlot(
                          destination: widget.destinations[i],
                          selection: _selectionOf(i, page),
                          maxLabelWidth: maxLabelWidth,
                          onTap: () => widget.onTap(i),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final NavDestination destination;
  final double selection;
  final double maxLabelWidth;
  final VoidCallback onTap;

  const _NavSlot({
    required this.destination,
    required this.selection,
    required this.maxLabelWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconColor = Color.lerp(
      cs.onSurfaceVariant,
      cs.onSecondaryContainer,
      selection,
    )!;

    return InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: cs.secondaryContainer.withValues(alpha: selection),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _slotWidth,
              child: Icon(destination.icon, color: iconColor, size: 24),
            ),
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: selection,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: _labelGap),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSecondaryContainer.withValues(
                          alpha: selection,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailingButton extends StatelessWidget {
  final NavPrimaryAction action;
  final AnimationController menuController;
  final VoidCallback? onTap;

  const _TrailingButton({
    super.key,
    required this.action,
    required this.menuController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = AnimatedBuilder(
      animation: menuController,
      builder: (context, child) => Transform.rotate(
        angle: menuController.value * (math.pi * 3 / 4),
        child: child,
      ),
      child: Icon(action.icon, color: cs.onPrimaryContainer),
    );

    return Tooltip(
      message: action.label,
      child: Material(
        color: cs.primaryContainer,
        elevation: 3,
        shadowColor: Colors.black26,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _barHeight,
            child: action.extended
                ? Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 24, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(width: 8),
                        Text(
                          action.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: _barHeight,
                    child: Center(child: icon),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FanAction extends StatelessWidget {
  final NavMenuAction action;
  final AnimationController controller;
  final int index;
  final int total;
  final VoidCallback onTap;

  const _FanAction({
    required this.action,
    required this.controller,
    required this.index,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / total) * 0.4;
    final end = math.min(1.0, start + 0.7);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final v = anim.value.clamp(0.0, 1.0);
        if (v == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: child,
          ),
        );
      },
      child: _FanActionRow(
        action: action,
        onTap: () {
          onTap();
          action.onTap();
        },
      ),
    );
  }
}

class _FanActionRow extends StatelessWidget {
  final NavMenuAction action;
  final VoidCallback onTap;

  const _FanActionRow({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: cs.surfaceContainerHighest,
          elevation: 2,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                action.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: cs.secondaryContainer,
          elevation: 3,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(action.icon, color: cs.onSecondaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
