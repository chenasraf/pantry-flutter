import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// Every transient message in the app goes through here.
///
/// Toasts float in from the top over an overlay the app installs above its
/// navigator, so they sit clear of the compose bars, FABs and bottom sheets a
/// bottom-anchored snackbar used to cover, and stay readable over dialogs and
/// modal sheets too.

/// How a toast reads at a glance. The kind picks the accent that tints the
/// card, its leading glyph and the draining border.
enum ToastKind { info, success, error }

/// An inline button on a toast — Undo being the one the app leans on.
@immutable
class ToastAction {
  final String label;
  final FutureOr<void> Function() onPressed;

  const ToastAction({required this.label, required this.onPressed});
}

/// Long enough to read as a slide rather than a jump, short enough that a
/// replaced toast is out of the way before the next one arrives.
const _animDuration = Duration(milliseconds: 360);

/// How far the card travels, in multiples of its own height.
///
/// Short on purpose. The card rests well down the screen, so a slide that
/// began off the top edge would have to cross it fast enough to jump several
/// tens of pixels between frames; the fade is what says "arriving", and the
/// slide only says which way.
const _slide = Offset(0, -1.2);

const _radius = 18.0;
const _strokeWidth = 2.0;

/// Marks the spot in the tree toasts are inserted at, so they can be shown
/// from anywhere — including from services holding no context of their own.
final _anchorKey = GlobalKey();

/// Installs the overlay toasts float in. Wrap the app in one; everything under
/// it can toast.
class AppToastHost extends StatelessWidget {
  final TextDirection textDirection;
  final Widget child;

  const AppToastHost({
    super.key,
    required this.textDirection,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StyledToast(
      textDirection: textDirection,
      child: KeyedSubtree(key: _anchorKey, child: child),
    );
  }
}

/// Shows [message] and auto-dismisses it after [duration]. Pass [action] for an
/// inline button. Returns null when the app's toast overlay isn't mounted yet.
ToastFuture? showAppToast({
  required String message,
  ToastKind kind = ToastKind.info,
  ToastAction? action,
  Duration duration = const Duration(seconds: 4),
}) {
  final context = _anchorKey.currentContext;
  if (context == null) return null;
  // The overlay starts its own exit animation this far before [duration] is
  // up, so the border has to reach empty there rather than at [duration].
  final life = duration - _animDuration;
  ToastFuture? handle;
  handle = showToastWidget(
    _AppToast(
      message: message,
      kind: kind,
      action: action,
      life: life > Duration.zero ? life : Duration.zero,
      onDismiss: () => handle?.dismiss(showAnim: true),
    ),
    context: context,
    duration: duration,
    animDuration: _animDuration,
    position: StyledToastPosition(
      align: Alignment.topCenter,
      offset: PlatformInfo.isMacOS ? 104 : 76,
    ),
    animation: StyledToastAnimation.slideFromTopFade,
    reverseAnimation: StyledToastAnimation.slideToTopFade,
    startOffset: _slide,
    reverseEndOffset: _slide,
    // The gentlest decelerating curve there is, because the toast has to read
    // on a debug build dropping frames: anything with a fast middle covers a
    // quarter of the travel between two frames and lands looking teleported.
    curve: Curves.easeOutSine,
    reverseCurve: Curves.easeInCubic,
    // The card carries buttons, so the overlay has to see pointers at all.
    isIgnoring: false,
  );
  return handle;
}

/// Shows an undo toast for [message]. Runs [onUndo] when tapped, surfacing
/// [undoFailedMessage] if it throws.
void showUndoToast({
  required String message,
  required String undoLabel,
  required Future<void> Function() onUndo,
  String? undoFailedMessage,
  Duration duration = const Duration(seconds: 6),
}) {
  showAppToast(
    message: message,
    duration: duration,
    action: ToastAction(
      label: undoLabel,
      onPressed: () async {
        try {
          await onUndo();
        } catch (_) {
          if (undoFailedMessage != null) {
            showAppToast(message: undoFailedMessage, kind: ToastKind.error);
          }
        }
      },
    ),
  );
}

/// Drops whatever toast is on screen, without waiting out its exit animation.
void dismissAppToasts() => dismissAllToast();

class _AppToast extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final ToastAction? action;

  /// How long the card stays before the overlay animates it away — the span
  /// the border drains over.
  final Duration life;
  final VoidCallback onDismiss;

  const _AppToast({
    required this.message,
    required this.kind,
    required this.action,
    required this.life,
    required this.onDismiss,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _remaining = AnimationController(
    vsync: this,
    duration: widget.life,
  );

  @override
  void initState() {
    super.initState();
    if (widget.life > Duration.zero) _remaining.reverse(from: 1);
  }

  @override
  void dispose() {
    _remaining.dispose();
    super.dispose();
  }

  Future<void> _runAction() async {
    await widget.action!.onPressed();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = switch (widget.kind) {
      ToastKind.info => scheme.primary,
      ToastKind.success => scheme.tertiary,
      ToastKind.error => scheme.error,
    };
    final icon = switch (widget.kind) {
      ToastKind.info => Icons.info_outline_rounded,
      ToastKind.success => Icons.check_circle_outline_rounded,
      ToastKind.error => Icons.error_outline_rounded,
    };
    // Blended rather than layered: the card sits over arbitrary content, and a
    // translucent fill would take the colour of whatever it happens to cover.
    final background = Color.alphaBlend(
      accent.withValues(alpha: 0.09),
      scheme.surfaceContainerHigh,
    );
    final action = widget.action;

    return Semantics(
      container: true,
      // Announced when it arrives: a toast is the only telling of what just
      // happened, and it is gone before a screen reader would reach it.
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Material(
            color: background,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: _remaining,
              builder: (context, child) => CustomPaint(
                foregroundPainter: _RemainingBorder(
                  remaining: _remaining.value,
                  color: accent,
                ),
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 14),
                    child: Icon(icon, size: 20, color: accent),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        10,
                        14,
                        4,
                        14,
                      ),
                      child: Text(
                        widget.message,
                        textDirection: detectTextDirection(widget.message),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  if (action != null)
                    TextButton(
                      onPressed: _runAction,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: theme.textTheme.labelLarge,
                      ),
                      child: Text(action.label),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 2, end: 8),
                    child: IconButton(
                      onPressed: widget.onDismiss,
                      tooltip: m.common.dismiss,
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                        padding: const EdgeInsets.all(7),
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The toast's own clock, drawn as a stroke draining off its border — so the
/// thing running out is the thing you would be dismissing.
class _RemainingBorder extends CustomPainter {
  final double remaining;
  final Color color;

  const _RemainingBorder({required this.remaining, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Half the stroke rides either side of the path, so the path is held in by
    // that much to keep the whole width inside the card's own edge.
    const inset = _strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - _strokeWidth,
            size.height - _strokeWidth,
          ),
          Radius.circular((_radius - inset).clamp(0.0, size.shortestSide / 2)),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    // The spent part stays as a faint rim, so the card keeps a defined edge
    // once the clock has run out rather than losing its outline.
    canvas.drawPath(path, paint..color = color.withValues(alpha: 0.22));
    if (remaining <= 0) return;
    paint.color = color;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * remaining.clamp(0.0, 1.0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RemainingBorder old) =>
      old.remaining != remaining || old.color != color;
}
