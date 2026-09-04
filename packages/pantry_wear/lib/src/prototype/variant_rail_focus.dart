import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';
import 'proto_data.dart';
import 'proto_mechanics.dart';

/// PROTOTYPE — variant D, "Rail focus".
///
/// The rail and the card language of B, over the snapping centred-focus list
/// of C. The rail keeps saying which house and list you are in and where you
/// are in the pager; the list underneath has one card in charge, so the target
/// is always the same place on the glass however far down the list you are.
///
/// Only round gets the focus list. On a square screen every row is equally
/// legible and there is nothing for a curve to buy, so square is B unchanged:
/// a plain, uniformly-spaced list.
class VariantRailFocus extends StatefulWidget {
  final ProtoSyncCycler sync;

  const VariantRailFocus({super.key, required this.sync});

  static const label = 'Rail focus';

  @override
  State<VariantRailFocus> createState() => _VariantRailFocusState();
}

class _VariantRailFocusState extends State<VariantRailFocus> {
  final _pager = PageController();
  final _wheels = List.generate(3, (_) => FixedExtentScrollController());
  final _lists = List.generate(3, (_) => ScrollController());
  var _page = 0;

  /// A percentage of the screen, because `SafeArea` inserts nothing here.
  /// Google's responsive layout asks for 5.2%, but that is a figure for a
  /// uniform list: here the falloff already pulls every off-centre card in
  /// from the bezel, so only the centre row runs full width — and at the
  /// centre line a circle is at its widest.
  static const _hPad = 0.02;

  /// How many rows out the falloff reaches before it bottoms out.
  static const _falloffRows = 2.2;

  static const _titles = [protoListName, 'Photos', 'Notes'];

  @override
  void dispose() {
    _pager.dispose();
    for (final c in _wheels) {
      c.dispose();
    }
    for (final c in _lists) {
      c.dispose();
    }
    super.dispose();
  }

  ThemeData _theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      // Two planes, not one: the rail has to read as separate from the cards
      // that scroll under it.
      scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xFF0B0B0C),
        surfaceContainerHighest: const Color(0xFF17171A),
      ),
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
          final railHeight = WearShape.isRound ? h * 0.21 : h * 0.15;
          final rail = SizedBox(
            height: railHeight,
            child: ColoredBox(
              color: const Color(0xFF0B0B0C),
              child: _Rail(
                page: _page,
                title: _titles[_page],
                sync: widget.sync,
              ),
            ),
          );
          final pager = EdgeAwarePageView(
            controller: _pager,
            page: _page,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              _body(0, w, protoItems.length, 54, _itemCard),
              _body(1, w, (protoPhotos.length + 1) ~/ 2, 92, _photoGridRow),
              _body(2, w, protoNotes.length, 80, _noteCard),
            ],
          );

          return ColoredBox(
            color: const Color(0xFF0B0B0C),
            child: WearShape.isSquare
                ? Column(
                    children: [
                      rail,
                      Expanded(child: pager),
                    ],
                  )
                // The centred card has to sit at the centre of the *screen*,
                // not of the space the rail left over — so the list runs the
                // full height and the rail covers its top rather than
                // displacing it.
                : Stack(
                    children: [
                      Positioned.fill(child: pager),
                      Positioned(top: 0, left: 0, right: 0, child: rail),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _body(
    int index,
    double w,
    int count,
    double extent,
    Widget Function(BuildContext, int, double) card,
  ) {
    final pad = EdgeInsets.symmetric(horizontal: w * _hPad);
    if (WearShape.isSquare) {
      return RotaryScrollable(
        controller: _lists[index],
        active: _page == index,
        child: ListView.separated(
          controller: _lists[index],
          padding: pad.copyWith(top: 4, bottom: 10),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) =>
              SizedBox(height: extent - 6, child: card(context, i, 0)),
        ),
      );
    }
    final controller = _wheels[index];
    return _RotaryItems(
      controller: controller,
      active: _page == index,
      lastIndex: count - 1,
      child: Padding(
        padding: pad,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: extent,
          physics: const FixedExtentScrollPhysics(),
          // The wheel's own perspective is flattened out of the way; the
          // falloff below is the whole visual effect, so it stays predictable
          // and tunable in one place.
          diameterRatio: 100,
          perspective: 0.00001,
          overAndUnderCenterOpacity: 1,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (context, i) => AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                // Distance in rows from the centre line, continuous while the
                // list is moving rather than only once it has snapped.
                final centre = controller.hasClients
                    ? controller.offset / extent
                    : 0.0;
                final d = ((i - centre).abs() / _falloffRows).clamp(0.0, 1.0);
                final g = railFocusCurve(d);
                return FractionallySizedBox(
                  widthFactor: g.widthFactor,
                  child: Transform.scale(
                    scale: g.scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: card(context, i, d),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// The card on the centre line is the one an action would land on, so it is
  /// the one drawn as reachable — and it earns that back gradually rather than
  /// at a threshold. Size and surface carry it; an outline would put a second
  /// edge around something the falloff already singles out.
  BoxDecoration _cardSkin(BuildContext context, double d) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Color.lerp(
        scheme.surfaceContainerHighest,
        const Color(0xFF121215),
        d,
      ),
      borderRadius: BorderRadius.circular(14),
    );
  }

  Widget _itemCard(BuildContext context, int index, double d) {
    final item = protoItems[index];
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: _cardSkin(context, d),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        child: Row(
          children: [
            Icon(
              item.done ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: item.done ? scheme.primary : Colors.white38,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: detectTextDirection(item.name),
                style: TextStyle(
                  fontSize: 15,
                  // Weight is the one thing the scale cannot carry: a scaled
                  // regular is still a regular.
                  fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                  color: item.done ? Colors.white38 : Colors.white,
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.qty != null)
              Text(
                item.qty!,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }

  /// Photos read as a grid rather than a stack of full-width cards — a wrist
  /// is scanning for the one it remembers, and two to a row halves how far it
  /// has to scan. The grid is still the focus list underneath: a *row* of
  /// tiles is what the centre line holds.
  Widget _photoGridRow(BuildContext context, int row, double d) {
    final first = row * 2;
    return Row(
      children: [
        Expanded(child: _photoTile(protoPhotos[first])),
        const SizedBox(width: 6),
        Expanded(
          child: first + 1 < protoPhotos.length
              ? _photoTile(protoPhotos[first + 1])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _photoTile(ProtoPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [photo.a, photo.b]),
        ),
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(6),
            child: Text(
              photo.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }

  /// Every note card is the same height, sized for the longest body it will
  /// draw. Letting each one shrink to its own text left the difference as dead
  /// space between cards — the list is fixed-extent, so height a card gives up
  /// becomes a gap rather than closing the list up.
  Widget _noteCard(BuildContext context, int index, double d) {
    final note = protoNotes[index];
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: _cardSkin(context, d),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: detectTextDirection(note.title),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                note.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: detectTextDirection(note.body),
                style: TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One detent, one card. A snapping list has nothing to say about half a row,
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
    // The axis reports the opposite of what the wrist means: turning the bezel
    // clockwise reads negative, and clockwise has to move down the list.
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
