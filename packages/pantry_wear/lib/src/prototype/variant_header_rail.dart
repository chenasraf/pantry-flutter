import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'proto_data.dart';
import 'proto_mechanics.dart';

/// PROTOTYPE — variant B, "Header rail".
///
/// The rectangular answer, and the control for the whole curved-row question:
/// rows here are uniform even on a round screen. A rail across the top always
/// says which house and list you are in, carries the page indicator and holds
/// a sync dot, and it costs a fifth of the screen to do it. If curving buys
/// nothing, this is what the shell should be.
class VariantHeaderRail extends StatefulWidget {
  final ProtoSyncCycler sync;

  const VariantHeaderRail({super.key, required this.sync});

  static const label = 'Header rail';

  @override
  State<VariantHeaderRail> createState() => _VariantHeaderRailState();
}

class _VariantHeaderRailState extends State<VariantHeaderRail> {
  final _pager = PageController();
  final _controllers = List.generate(3, (_) => ScrollController());
  var _page = 0;

  /// Google's responsive layout for watches: a percentage of the screen, the
  /// same fraction on both shapes, because `SafeArea` inserts nothing here.
  static const _hPad = 0.052;
  static const _vPad = 0.10;

  static const _titles = ['Groceries', 'Photos', 'Notes'];

  @override
  void dispose() {
    _pager.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  ThemeData _theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // Not pure black: the rail has to read as a separate plane from the
      // content, which needs two surfaces rather than one.
      scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xFF0B0B0C),
        surfaceContainerHighest: const Color(0xFF17171A),
      ),
      textTheme: base.textTheme.apply(fontSizeFactor: 0.95),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return ColoredBox(
            color: const Color(0xFF0B0B0C),
            child: Column(
              children: [
                SizedBox(
                  height: WearShape.isRound ? h * 0.21 : h * 0.15,
                  child: _Rail(
                    page: _page,
                    title: _titles[_page],
                    sync: widget.sync,
                  ),
                ),
                Expanded(
                  child: EdgeAwarePageView(
                    controller: _pager,
                    page: _page,
                    onPageChanged: (p) => setState(() => _page = p),
                    children: [
                      _list(0, w, h, protoItems.length, _itemRow),
                      _list(1, w, h, protoPhotos.length, _photoRow),
                      _list(2, w, h, protoNotes.length, _noteRow),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _list(
    int index,
    double w,
    double h,
    int count,
    Widget Function(BuildContext, int) row,
  ) => RotaryScrollable(
    controller: _controllers[index],
    active: _page == index,
    child: ListView.separated(
      controller: _controllers[index],
      padding: EdgeInsets.symmetric(
        horizontal: w * _hPad,
        vertical: h * _vPad * 0.5,
      ),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: row,
    ),
  );

  Widget _itemRow(BuildContext context, int index) {
    final item = protoItems[index];
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        child: Row(
          children: [
            Icon(
              item.done ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: item.done ? scheme.primary : Colors.white38,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: detectTextDirection(item.name),
                style: TextStyle(
                  fontSize: 13,
                  color: item.done ? Colors.white38 : Colors.white,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.qty != null)
              Text(
                item.qty!,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoRow(BuildContext context, int index) {
    final photo = protoPhotos[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [photo.a, photo.b]),
          ),
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(7),
              child: Text(photo.caption, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteRow(BuildContext context, int index) {
    final note = protoNotes[index];
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(note.title),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(note.body),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// House, list, page indicator and sync, in the band across the top.
class _Rail extends StatelessWidget {
  final int page;
  final String title;
  final ProtoSyncCycler sync;

  const _Rail({required this.page, required this.title, required this.sync});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final window = dotWindow(3, page);
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        // The top of a circle is narrow, so a full-width rail would clip its
        // own ends against the bezel.
        widthFactor: WearShape.isRound ? 0.68 : 0.92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: sync,
                  builder: (context, _) {
                    final look = protoSyncLook(
                      context,
                      sync.state,
                      sync.pending,
                    );
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsetsDirectional.only(end: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: look.color,
                      ),
                    );
                  },
                ),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(title),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              protoHouse,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 5),
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
                          ? scheme.primary
                          : Colors.white24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
