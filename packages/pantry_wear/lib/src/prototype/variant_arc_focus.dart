import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';
import 'proto_data.dart';
import 'proto_mechanics.dart';

/// PROTOTYPE — variant C, "Arc focus".
///
/// Built for the circle rather than fitted into it. The chrome is pushed out
/// onto the bezel — the list name bends along the top arc and the page
/// indicator is a set of ticks around the bottom — which leaves the entire
/// rectangle to content. The list has one row in charge: it snaps, and the
/// centred row is the large one, so the target is always the same place on
/// the glass no matter where the list is.
class VariantArcFocus extends StatefulWidget {
  final ProtoSyncCycler sync;

  const VariantArcFocus({super.key, required this.sync});

  static const label = 'Arc focus';

  @override
  State<VariantArcFocus> createState() => _VariantArcFocusState();
}

class _VariantArcFocusState extends State<VariantArcFocus> {
  final _pager = PageController();
  final _controllers = List.generate(3, (_) => FixedExtentScrollController());
  final _selected = [0, 0, 0];
  var _page = 0;

  static const _titles = [protoListName, 'Photos', 'Notes'];

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
      textTheme: base.textTheme.apply(fontSizeFactor: 1.1),
      colorScheme: base.colorScheme.copyWith(surface: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme(context),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: EdgeAwarePageView(
                controller: _pager,
                page: _page,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _wheel(0, protoItems.length, 44, _itemRow),
                  _wheel(1, protoPhotos.length, 78, _photoRow),
                  _wheel(2, protoNotes.length, 58, _noteRow),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: widget.sync,
                  builder: (context, _) => _Bezel(
                    title: _titles[_page],
                    page: _page,
                    sync: widget.sync,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel(
    int index,
    int count,
    double extent,
    Widget Function(BuildContext, int, double) row,
  ) {
    return _RotaryItems(
      controller: _controllers[index],
      active: _page == index,
      lastIndex: count - 1,
      // The bezel ticks own the last strip of the circle, so the wheel stops
      // short of it rather than scrolling rows underneath.
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: ListWheelScrollView.useDelegate(
          controller: _controllers[index],
          itemExtent: extent,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.8,
          perspective: 0.003,
          squeeze: 1.05,
          overAndUnderCenterOpacity: 0.45,
          onSelectedItemChanged: (i) => setState(() => _selected[index] = i),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (context, i) {
              // Rows narrow as they leave the centre, so the round screen's
              // widest line is always the row that is in charge.
              final distance = WearShape.isRound
                  ? ((i - _selected[index]).abs() / 2.5).clamp(0.0, 1.0)
                  : 0.0;
              final geometry = focusCurve(distance);
              return FractionallySizedBox(
                widthFactor: geometry.widthFactor,
                child: row(context, i, distance),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _itemRow(BuildContext context, int index, double distance) {
    final item = protoItems[index];
    final scheme = Theme.of(context).colorScheme;
    final focused = distance == 0;
    return Row(
      children: [
        Icon(
          item.done ? Icons.check_circle : Icons.circle_outlined,
          size: focused ? 20 : 16,
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
              fontSize: focused ? 16 : 13,
              fontWeight: focused ? FontWeight.w600 : FontWeight.w400,
              color: item.done ? Colors.white38 : Colors.white,
              decoration: item.done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (item.qty != null)
          Text(
            item.qty!,
            style: TextStyle(
              fontSize: focused ? 12 : 10,
              color: Colors.white54,
            ),
          ),
      ],
    );
  }

  Widget _photoRow(BuildContext context, int index, double distance) {
    final photo = protoPhotos[index];
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [photo.a, photo.b]),
          ),
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(8),
              child: Text(
                photo.caption,
                style: TextStyle(fontSize: distance == 0 ? 13 : 11),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteRow(BuildContext context, int index, double distance) {
    final note = protoNotes[index];
    final focused = distance == 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: detectTextDirection(note.title),
          style: TextStyle(
            fontSize: focused ? 15 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    );
  }
}

/// One detent, one row. A snapping list has nothing to say about half a row,
/// so the bezel moves the selection rather than the pixels.
class _RotaryItems extends StatefulWidget {
  final FixedExtentScrollController controller;
  final bool active;
  final int lastIndex;
  final Widget child;

  const _RotaryItems({
    required this.controller,
    required this.active,
    required this.lastIndex,
    required this.child,
  });

  @override
  State<_RotaryItems> createState() => _RotaryItemsState();
}

class _RotaryItemsState extends State<_RotaryItems> {
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_RotaryItems old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    _sub?.cancel();
    _sub = widget.active
        ? RotaryService.instance.detents.listen(_onDetent)
        : null;
  }

  void _onDetent(double detent) {
    if (!widget.controller.hasClients) return;
    final next = (widget.controller.selectedItem - detent.sign.toInt()).clamp(
      0,
      widget.lastIndex,
    );
    widget.controller.animateToItem(
      next,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The chrome that lives on the bezel rather than in the rectangle.
class _Bezel extends StatelessWidget {
  final String title;
  final int page;
  final ProtoSyncCycler sync;

  const _Bezel({required this.title, required this.page, required this.sync});

  @override
  Widget build(BuildContext context) {
    final look = protoSyncLook(context, sync.state, sync.pending);
    final scheme = Theme.of(context).colorScheme;
    // Sync is not a separate widget here; it tints the chrome that is already
    // on screen, so a clean state costs nothing at all.
    final tint = sync.state == ProtoSync.idle
        ? Colors.white.withValues(alpha: 0.75)
        : look.color;

    if (WearShape.isSquare) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6),
            child: Text(
              title.toUpperCase(),
              textDirection: detectTextDirection(title),
              style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: tint),
            ),
          ),
          const Spacer(),
          _FlatTicks(page: page, color: scheme.primary),
          const SizedBox(height: 5),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ArcText(
            text: title.toUpperCase(),
            inset: 14,
            style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: tint),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ArcTicksPainter(
              page: page,
              pages: 3,
              active: scheme.primary,
              idle: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlatTicks extends StatelessWidget {
  final int page;
  final Color color;

  const _FlatTicks({required this.page, required this.color});

  @override
  Widget build(BuildContext context) {
    final window = dotWindow(3, page);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < window.count; i++)
          Container(
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
            width: i == window.selected ? 16 : 8,
            height: 2,
            color: i == window.selected ? color : Colors.white24,
          ),
      ],
    );
  }
}

/// Page ticks swept around the bottom of the bezel.
class _ArcTicksPainter extends CustomPainter {
  final int page;
  final int pages;
  final Color active;
  final Color idle;

  _ArcTicksPainter({
    required this.page,
    required this.pages,
    required this.active,
    required this.idle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final window = dotWindow(pages, page);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 5,
    );
    const perTick = 0.13;
    const gap = 0.05;
    final span = window.count * perTick + (window.count - 1) * gap;
    // Angles grow anticlockwise across the bottom of the circle, so the ticks
    // are laid out from the far end to keep the first page on the left.
    var start = math.pi / 2 + span / 2 - perTick;

    for (var i = 0; i < window.count; i++) {
      final selected = i == window.selected;
      canvas.drawArc(
        rect,
        start,
        perTick,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = selected ? 3.5 : 2
          ..color = selected ? active : idle,
      );
      start -= perTick + gap;
    }
  }

  @override
  bool shouldRepaint(_ArcTicksPainter old) =>
      old.page != page || old.pages != pages;
}
