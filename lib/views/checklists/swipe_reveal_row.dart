import 'package:flutter/material.dart';

import 'package:pantry/utils/platform_info.dart';

/// A row whose action buttons slide IN from the trailing edge on swipe, on
/// top of a stationary foreground. The list item content (checkbox, name,
/// chips) stays fully visible while the action buttons overlay the trailing
/// portion of the row. Snap-open past ~1/3 threshold, snap-closed otherwise,
/// transform animation disabled while actively dragging.
///
/// On desktop platforms (macOS / Windows / Linux) the swipe gesture isn't
/// reliably available — many users are on mice without touchpads — so the
/// actions render permanently pinned at the trailing edge instead, with the
/// content shrinking to make room. Gated on [PlatformInfo.isDesktop].
class SwipeRevealRow extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final bool enabled;

  /// Trims action-button width, icon size and label spacing so the swipe
  /// actions match the checklist's dense visual density.
  final bool dense;
  final VoidCallback? onOpened;

  const SwipeRevealRow({
    super.key,
    required this.child,
    required this.actions,
    this.enabled = true,
    this.dense = false,
    this.onOpened,
  });

  @override
  State<SwipeRevealRow> createState() => SwipeRevealRowState();
}

class SwipeRevealRowState extends State<SwipeRevealRow> {
  double _offset = 0;
  bool _dragging = false;

  double get _actionWidth => widget.dense ? 52.0 : 62.0;

  double get _maxSwipe => widget.actions.length * _actionWidth;

  void close() {
    if (_offset == 0) return;
    setState(() {
      _offset = 0;
      _dragging = false;
    });
  }

  void _onPanStart(DragStartDetails d) {
    _dragging = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // In LTR, dragging foreground left (negative dx) opens trailing actions.
    // In RTL, dragging right (positive dx) opens trailing actions.
    final delta = isRtl ? -d.delta.dx : d.delta.dx;
    setState(() {
      _offset = (_offset + delta).clamp(-_maxSwipe, 0.0);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    final shouldOpen = _offset.abs() > _maxSwipe / 3;
    setState(() {
      _offset = shouldOpen ? -_maxSwipe : 0;
      _dragging = false;
    });
    if (shouldOpen) widget.onOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isDesktop) {
      // Desktop layout: lay content + actions out in a Row. The foreground
      // keeps its full hit area for taps, but loses the trailing space to
      // the always-visible action buttons. No clip, no slide, no gesture.
      // `stretch` so the action tiles span the row's full height — without
      // it the Row sizes to its tallest child and the action backgrounds
      // sit centered, leaving visible gaps above and below.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.child),
            for (final a in widget.actions)
              _ActionButton(
                action: a,
                width: _actionWidth,
                dense: widget.dense,
                onTap: a.onPressed,
              ),
          ],
        ),
      );
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Translate the action row in from off-screen. `_offset` ranges from 0
    // (closed) to -_maxSwipe (fully open). When closed the actions are
    // shifted by +_maxSwipe past the trailing edge (so they're hidden behind
    // the ClipRect); when open they're at translation 0 and fully visible.
    // In RTL the "trailing edge" is on the left, so the translation flips.
    final slide = (_maxSwipe + _offset) * (isRtl ? -1 : 1);
    return ClipRect(
      child: Stack(
        children: [
          // Foreground stays put — the list item content (checkbox, name,
          // chips) remains fully visible regardless of swipe state.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.enabled ? _onPanStart : null,
            onHorizontalDragUpdate: widget.enabled ? _onPanUpdate : null,
            onHorizontalDragEnd: widget.enabled ? _onPanEnd : null,
            child: widget.child,
          ),
          // Action row, anchored at the trailing edge and translated in/out
          // by `slide`. Sits on top of the foreground so the buttons cover
          // (but don't displace) the row's content while open.
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            child: AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(slide, 0, 0),
              child: Row(
                children: [
                  for (final a in widget.actions)
                    _ActionButton(
                      action: a,
                      width: _actionWidth,
                      dense: widget.dense,
                      onTap: () {
                        close();
                        a.onPressed();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeAction {
  final IconData icon;
  final String label;
  final Color tint;
  final Color background;
  final VoidCallback onPressed;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.background,
    required this.onPressed,
  });
}

class _ActionButton extends StatelessWidget {
  final SwipeAction action;
  final double width;
  final bool dense;
  final VoidCallback onTap;

  const _ActionButton({
    required this.action,
    required this.width,
    required this.dense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.background,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.tint, size: dense ? 17 : 20),
              SizedBox(height: dense ? 2 : 4),
              Text(
                action.label,
                style: TextStyle(
                  color: action.tint,
                  fontSize: dense ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
