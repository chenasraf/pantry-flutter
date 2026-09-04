import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import 'proto_data.dart';
import 'proto_mechanics.dart';

/// PROTOTYPE — variant A, "Full bleed".
///
/// No persistent chrome at all. Every page owns the whole screen, and the
/// things a header would have carried are folded into the content: the list
/// name is the first row and scrolls away once you are reading, and sync only
/// interrupts when it has something to say. Rows follow the chord of the
/// circle, so the middle of the screen is as wide as the screen gets.
class VariantFullBleed extends StatefulWidget {
  final ProtoSyncCycler sync;

  const VariantFullBleed({super.key, required this.sync});

  static const label = 'Full bleed';

  @override
  State<VariantFullBleed> createState() => _VariantFullBleedState();
}

class _VariantFullBleedState extends State<VariantFullBleed> {
  final _pager = PageController();
  final _controllers = List.generate(3, (_) => ScrollController());
  var _page = 0;

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
      textTheme: base.textTheme.apply(fontSizeFactor: 1.05),
      colorScheme: base.colorScheme.copyWith(surface: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme(context),
      child: Stack(
        children: [
          Positioned.fill(
            child: EdgeAwarePageView(
              controller: _pager,
              page: _page,
              onPageChanged: (p) => setState(() => _page = p),
              children: [
                _page3(0, _checklists),
                _page3(1, _photos),
                _page3(2, _notes),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(child: _FloatingDots(page: _page)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(child: _TransientSync(sync: widget.sync)),
          ),
        ],
      ),
    );
  }

  Widget _page3(int index, Widget Function(ScrollController) build) =>
      RotaryScrollable(
        controller: _controllers[index],
        active: _page == index,
        child: build(_controllers[index]),
      );

  Widget _title(String text, String sub) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: detectTextDirection(text),
          style: const TextStyle(
            fontSize: 17,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            height: 1.15,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    ),
  );

  Widget _checklists(ScrollController controller) => CurvedRowList(
    controller: controller,
    itemExtent: 42,
    itemCount: protoItems.length + 1,
    curve: circleChordCurve,
    padding: const EdgeInsets.only(top: 14, bottom: 34),
    itemBuilder: (context, index) {
      if (index == 0) return _title(protoListName, protoHouse);
      final item = protoItems[index - 1];
      return _ItemRow(item: item);
    },
  );

  Widget _photos(ScrollController controller) => CurvedRowList(
    controller: controller,
    itemExtent: 74,
    itemCount: protoPhotos.length + 1,
    curve: circleChordCurve,
    padding: const EdgeInsets.only(top: 14, bottom: 34),
    itemBuilder: (context, index) {
      if (index == 0) return _title('Photos', protoHouse);
      final photo = protoPhotos[index - 1];
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [photo.a, photo.b]),
          ),
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(8),
              child: Text(photo.caption, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ),
      );
    },
  );

  Widget _notes(ScrollController controller) => CurvedRowList(
    controller: controller,
    itemExtent: 54,
    itemCount: protoNotes.length + 1,
    curve: circleChordCurve,
    padding: const EdgeInsets.only(top: 14, bottom: 34),
    itemBuilder: (context, index) {
      if (index == 0) return _title('Notes', protoHouse);
      final note = protoNotes[index - 1];
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(note.title),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(note.body),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ItemRow extends StatelessWidget {
  final ProtoItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          item.done ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
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
              fontSize: 14,
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
    );
  }
}

/// Dots over the content, on a scrim just dark enough to keep a row from
/// reading through them.
class _FloatingDots extends StatelessWidget {
  final int page;

  const _FloatingDots({required this.page});

  @override
  Widget build(BuildContext context) {
    final window = dotWindow(3, page);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < window.count; i++)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 3),
              child: Container(
                width: i == window.selected ? 6 : 4,
                height: i == window.selected ? 6 : 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == window.selected ? scheme.primary : Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sync speaks only when it changes, then gets out of the way.
class _TransientSync extends StatefulWidget {
  final ProtoSyncCycler sync;

  const _TransientSync({required this.sync});

  @override
  State<_TransientSync> createState() => _TransientSyncState();
}

class _TransientSyncState extends State<_TransientSync> {
  Timer? _hide;
  var _visible = false;

  @override
  void initState() {
    super.initState();
    widget.sync.addListener(_onChange);
  }

  void _onChange() {
    _hide?.cancel();
    // A clean state has nothing worth spending the top of the screen on.
    if (widget.sync.state == ProtoSync.idle) {
      setState(() => _visible = false);
      return;
    }
    setState(() => _visible = true);
    _hide = Timer(
      const Duration(milliseconds: 2500),
      () => mounted ? setState(() => _visible = false) : null,
    );
  }

  @override
  void dispose() {
    _hide?.cancel();
    widget.sync.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = protoSyncLook(context, widget.sync.state, widget.sync.pending);
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: Container(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(look.icon, size: 13, color: look.color),
              const SizedBox(width: 5),
              Text(
                look.label,
                style: TextStyle(fontSize: 11, color: look.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
