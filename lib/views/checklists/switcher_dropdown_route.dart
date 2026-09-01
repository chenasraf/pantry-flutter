import 'package:flutter/material.dart';

import 'package:pantry/views/checklists/checklists_controller.dart';

import 'checklist_switcher_sheet.dart';

/// Custom popup route that positions the switcher panel beneath the AppBar
/// title row. Mirrors the bottom-sheet panel design but drops the grabber
/// bar and rounds all four corners so it reads as a dropdown menu.
class SwitcherDropdownRoute extends PopupRoute<void> {
  final RenderBox anchor;
  final ChecklistsController checklistsController;
  final Future<int> Function(int listId) itemCountForList;

  SwitcherDropdownRoute({
    required this.anchor,
    required ChecklistsController controller,
    required this.itemCountForList,
  }) : checklistsController = controller;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.18);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    if (!anchor.attached) return const SizedBox.shrink();
    final anchorTopLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorSize = anchor.size;
    return _DropdownPositioner(
      anchorTopLeft: anchorTopLeft,
      anchorSize: anchorSize,
      child: SheetHost(
        controller: checklistsController,
        itemCountForList: itemCountForList,
        desktop: true,
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Soft fade + tiny downward slide so the panel reads as "dropping" from
    // under the title.
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

/// Pins the dropdown panel to a fixed width directly below the anchor, with
/// the start edge aligned to the anchor's start. Clamps to the screen so the
/// panel never falls off the right edge.
class _DropdownPositioner extends StatelessWidget {
  final Offset anchorTopLeft;
  final Size anchorSize;
  final Widget child;

  static const double _panelWidth = 360;
  static const double _gap = 8;
  static const double _screenPad = 12;

  const _DropdownPositioner({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final top = anchorTopLeft.dy + anchorSize.height + _gap;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Anchor by the directional start edge so the dropdown's leading edge
    // lines up with the title's leading edge in both LTR and RTL.
    final desiredStart = isRtl
        ? anchorTopLeft.dx + anchorSize.width - _panelWidth
        : anchorTopLeft.dx;
    final left = desiredStart.clamp(
      _screenPad,
      screen.width - _panelWidth - _screenPad,
    );
    return Stack(
      children: [
        Positioned(left: left, top: top, width: _panelWidth, child: child),
      ],
    );
  }
}
