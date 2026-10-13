import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows [builder]'s content in a sheet that drops down from the top edge —
/// the mirror of a modal bottom sheet, for menus opened from the app bar so
/// they unfold where the finger already is. Dismissed by a tap outside, back,
/// or an upward swipe.
Future<T?> showTopSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, animation, _) =>
        _TopSheet(animation: animation, builder: builder),
    // The sheet slides itself (by its own height, not the screen's); the
    // route only fades the barrier.
    transitionBuilder: (_, _, _, child) => child,
  );
}

class _TopSheet extends StatefulWidget {
  const _TopSheet({required this.animation, required this.builder});

  final Animation<double> animation;
  final WidgetBuilder builder;

  @override
  State<_TopSheet> createState() => _TopSheetState();
}

class _TopSheetState extends State<_TopSheet>
    with SingleTickerProviderStateMixin {
  final _sheetKey = GlobalKey();

  /// Springs the sheet back down after a drag too short to dismiss it.
  late final AnimationController _settle;

  /// How far the sheet has been dragged up, in pixels (always <= 0).
  double _dragOffset = 0;

  late final CurvedAnimation _entrance;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _entrance = CurvedAnimation(
      parent: widget.animation,
      curve: Easing.emphasizedDecelerate,
      reverseCurve: Easing.emphasizedAccelerate,
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _settle.dispose();
    super.dispose();
  }

  double get _sheetHeight =>
      (_sheetKey.currentContext?.findRenderObject() as RenderBox?)
          ?.size
          .height ??
      1;

  void _onDragUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(-_sheetHeight, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final flungUp = details.velocity.pixelsPerSecond.dy < -700;
    if (flungUp || _dragOffset < -_sheetHeight / 3) {
      Navigator.of(context).maybePop();
      return;
    }
    final from = _dragOffset;
    final animation = Tween(
      begin: from,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _settle, curve: Curves.easeOutCubic));
    void tick() => setState(() => _dragOffset = animation.value);
    animation.addListener(tick);
    _settle.forward(from: 0).whenComplete(() => animation.removeListener(tick));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_entrance),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: media.size.height * 0.9,
            ),
            child: GestureDetector(
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Material(
                key: _sheetKey,
                color:
                    theme.bottomSheetTheme.backgroundColor ??
                    theme.colorScheme.surfaceContainerLow,
                elevation: 1,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(SurfaceRadius.sheet),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.only(top: media.padding.top),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Builder(builder: widget.builder)),
                      Container(
                        width: 38,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: AppSurfaces.of(context).dragHandle(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
