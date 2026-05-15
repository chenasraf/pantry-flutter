import 'package:flutter/material.dart';

/// Wraps [child] so that a secondary-tap (right-click on desktop / web)
/// opens [items] as a popup menu anchored at the pointer position.
///
/// Pair with a [PopupMenuButton] / [TileMenuButton] using the same
/// items + onSelected so touch and pointer users get the same affordance.
class ContextMenuRegion<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> Function() itemBuilder;
  final ValueChanged<T> onSelected;
  final Widget child;

  const ContextMenuRegion({
    super.key,
    required this.itemBuilder,
    required this.onSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) => _show(context, details.globalPosition),
      child: child,
    );
  }

  Future<void> _show(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: itemBuilder(),
    );
    if (value != null) onSelected(value);
  }
}
