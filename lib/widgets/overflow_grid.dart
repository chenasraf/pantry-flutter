import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'overflow_menu.dart';
import 'top_sheet.dart';

const _transitionDuration = Duration(milliseconds: 300);

/// The grid-style overflow: a tile per [OverflowGroup]. A tile holding several
/// rows opens a page of them within the panel; a tile holding one acts on it.
///
/// Toggles and radio choices apply through [onToggle] and keep the panel open
/// so several can be changed in one visit; any other row is handed to
/// [onAction], which is expected to close the panel.
class OverflowGridPanel extends StatefulWidget {
  const OverflowGridPanel({
    super.key,
    required this.groups,
    required this.onAction,
    required this.onToggle,
    this.listenable,
    this.dense = false,
    this.columns = 3,
  });

  /// Called on every rebuild so rows reflect state changed by [onToggle].
  final List<OverflowGroup> Function() groups;
  final ValueChanged<String> onAction;
  final ValueChanged<String> onToggle;

  /// Rebuilds the panel when the state behind [groups] changes.
  final Listenable? listenable;

  /// Tightens rows for a pointer-driven popover.
  final bool dense;
  final int columns;

  @override
  State<OverflowGridPanel> createState() => _OverflowGridPanelState();
}

class _OverflowGridPanelState extends State<OverflowGridPanel> {
  String? _openId;

  void _pick(OverflowEntry entry) {
    final value = overflowEntryValue(entry);
    if (value == null) return;
    if (overflowEntryIsToggle(entry)) {
      widget.onToggle(value);
    } else {
      widget.onAction(value);
    }
  }

  void _back() => setState(() => _openId = null);

  @override
  Widget build(BuildContext context) {
    final listenable = widget.listenable;
    if (listenable == null) return _build(context);
    return ListenableBuilder(
      listenable: listenable,
      builder: (c, _) => _build(c),
    );
  }

  Widget _build(BuildContext context) {
    final groups = [
      for (final g in widget.groups())
        if (!g.isEmpty) g,
    ];
    // A toggle can empty or remove the open group (e.g. a feature switching
    // off); fall back to the grid rather than showing a stale page.
    final open = groups.where((g) => g.id == _openId).firstOrNull;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // The grid always enters and leaves on the start side and a page on the
    // end side, so opening a group reads as a push and going back as a pop.
    // A fade-through: the outgoing view is gone by the halfway mark before the
    // incoming one appears, so the two never show through each other.
    Widget transition(Widget child, Animation<double> animation) {
      final fromStart = child.key == const ValueKey('grid');
      final dx = (fromStart ? -0.06 : 0.06) * (rtl ? -1 : 1);
      return FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: const Interval(0.5, 1, curve: Curves.easeOut)),
        ),
        child: SlideTransition(
          position: animation.drive(
            Tween(
              begin: Offset(dx, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Easing.emphasizedDecelerate)),
          ),
          child: child,
        ),
      );
    }

    return PopScope(
      canPop: open == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedSize(
        duration: _transitionDuration,
        curve: Curves.easeInOutCubic,
        alignment: AlignmentDirectional.topCenter,
        child: AnimatedSwitcher(
          duration: _transitionDuration,
          transitionBuilder: transition,
          // Only the incoming view sizes the panel, so the height eases
          // straight from the old view's to the new one's instead of first
          // growing to fit both.
          layoutBuilder: (current, previous) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (final p in previous)
                Positioned(top: 0, left: 0, right: 0, child: p),
              ?current,
            ],
          ),
          child: open == null
              ? KeyedSubtree(
                  key: const ValueKey('grid'),
                  child: _grid(context, groups),
                )
              : KeyedSubtree(
                  key: ValueKey('group:${open.id}'),
                  child: _page(context, open),
                ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<OverflowGroup> groups) {
    final columns = math.max(1, widget.columns);
    const gap = 10.0;
    final rows = <Widget>[];
    for (var i = 0; i < groups.length; i += columns) {
      final slice = groups.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: gap),
                Expanded(
                  child: c < slice.length
                      ? _tileFor(slice[c])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _tileFor(OverflowGroup group) {
    final sole = group.soleEntry;
    if (sole != null) {
      return OverflowGroupTile(
        dense: widget.dense,
        icon: sole is OverflowAction ? sole.icon : group.icon,
        label: switch (sole) {
          OverflowAction(:final label) => label,
          OverflowCheckboxAction(:final label) => label,
          OverflowRadioAction(:final label) => label,
          _ => group.label,
        },
        onTap: () => _pick(sole),
      );
    }
    return OverflowGroupTile(
      dense: widget.dense,
      icon: group.icon,
      label: group.label,
      drillsIn: true,
      onTap: () => setState(() => _openId = group.id),
    );
  }

  Widget _page(BuildContext context, OverflowGroup group) {
    final theme = Theme.of(context);
    final surfaces = AppSurfaces.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _back,
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: surfaces.iconTile(surfaces.accent, bordered: true),
                child: Icon(group.icon, size: 18, color: surfaces.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final entry in group.entries)
          OverflowSheetRow(
            entry: entry,
            dense: widget.dense,
            onTap: (_) => _pick(entry),
          ),
        SizedBox(height: widget.dense ? 8 : 4),
      ],
    );
  }
}

/// A grid-menu tile: an icon over a label, edged like a button. [drillsIn]
/// adds a chevron marking a tile that opens more choices rather than acting.
/// [dense] sizes it for a pointer-driven popover.
class OverflowGroupTile extends StatelessWidget {
  const OverflowGroupTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.drillsIn = false,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool drillsIn;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = AppSurfaces.of(context);
    final labelStyle = dense
        ? theme.textTheme.labelMedium
        : theme.textTheme.labelLarge;
    // Even sides keep the content centered; a chevron on the end edge needs
    // them wide enough to clear it.
    final side = drillsIn ? 24.0 : (dense ? 10.0 : 14.0);
    return Material(
      color: surfaces.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
        side: BorderSide(color: surfaces.edge),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          // Top-aligned: a row of tiles is as tall as its longest label, and
          // centering would set a one-line tile's icon lower than its
          // neighbor's.
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                side,
                dense ? 14 : 16,
                side,
                dense ? 12 : 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: dense ? 22 : 26,
                    color: theme.colorScheme.onSurface,
                  ),
                  SizedBox(height: dense ? 8 : 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (drillsIn)
              PositionedDirectional(
                top: 0,
                bottom: 0,
                end: 2,
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows an [OverflowGridPanel] in a sheet dropping from the top, under the
/// app bar button that opens it, and resolves to the value of the action row
/// the user picked, or null if they dismissed it. Toggles apply through
/// [onToggle] without closing the sheet.
Future<String?> showOverflowGridSheet(
  BuildContext context, {
  required List<OverflowGroup> Function() groups,
  required ValueChanged<String> onToggle,
  Listenable? listenable,
}) {
  return showTopSheet<String>(
    context,
    builder: (sheetContext) => SingleChildScrollView(
      child: OverflowGridPanel(
        groups: groups,
        listenable: listenable,
        columns: MediaQuery.sizeOf(sheetContext).width >= 520 ? 4 : 3,
        onToggle: onToggle,
        onAction: (value) => Navigator.of(sheetContext).pop(value),
      ),
    ),
  );
}

/// Shows an [OverflowGridPanel] in a popover anchored under the widget that
/// owns [anchorContext]. Resolves like [showOverflowGridSheet].
Future<String?> showOverflowGridPopover(
  BuildContext anchorContext, {
  required List<OverflowGroup> Function() groups,
  required ValueChanged<String> onToggle,
  Listenable? listenable,
}) => _showPopover(
  anchorContext,
  // Three tiles a row with room for a two-word label on each.
  width: 460,
  builder: (routeContext) => OverflowGridPanel(
    groups: groups,
    listenable: listenable,
    dense: true,
    onToggle: onToggle,
    onAction: (value) => Navigator.of(routeContext).pop(value),
  ),
);

/// Shows [entries] as a list in a popover anchored under the widget that owns
/// [anchorContext], resolving to the value of the row picked, or null if it
/// was dismissed.
///
/// With [onToggle], toggles and radio choices apply through it and keep the
/// popover open, rebuilding from [entries] whenever [listenable] changes;
/// without it, every row closes the popover.
Future<String?> showOverflowListPopover(
  BuildContext anchorContext, {
  required List<OverflowEntry> Function() entries,
  ValueChanged<String>? onToggle,
  Listenable? listenable,
}) => _showPopover(
  anchorContext,
  width: 280,
  builder: (routeContext) => _OverflowListPanel(
    entries: entries,
    listenable: listenable,
    onToggle: onToggle,
    onAction: (value) => Navigator.of(routeContext).pop(value),
  ),
);

class _OverflowListPanel extends StatelessWidget {
  const _OverflowListPanel({
    required this.entries,
    required this.onAction,
    this.onToggle,
    this.listenable,
  });

  final List<OverflowEntry> Function() entries;
  final ValueChanged<String> onAction;
  final ValueChanged<String>? onToggle;
  final Listenable? listenable;

  void _pick(OverflowEntry entry) {
    final value = overflowEntryValue(entry);
    if (value == null) return;
    final toggle = onToggle;
    if (toggle != null && overflowEntryIsToggle(entry)) {
      toggle(value);
    } else {
      onAction(value);
    }
  }

  Widget _build() => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries())
          OverflowSheetRow(
            entry: entry,
            dense: true,
            onTap: (_) => _pick(entry),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final listenable = this.listenable;
    if (listenable == null) return _build();
    return ListenableBuilder(
      listenable: listenable,
      builder: (_, _) => _build(),
    );
  }
}

Future<String?> _showPopover(
  BuildContext anchorContext, {
  required double width,
  required WidgetBuilder builder,
}) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  final navigator = Navigator.of(anchorContext);
  final overlayBox =
      navigator.overlay!.context.findRenderObject()! as RenderBox;
  final anchor = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlayBox),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlayBox),
  );
  return navigator.push(
    _PopoverRoute<String>(
      anchor: anchor,
      textDirection: Directionality.of(anchorContext),
      barrierLabel: MaterialLocalizations.of(
        anchorContext,
      ).modalBarrierDismissLabel,
      capturedThemes: InheritedTheme.capture(
        from: anchorContext,
        to: navigator.context,
      ),
      width: width,
      builder: builder,
    ),
  );
}

class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.textDirection,
    required this.barrierLabel,
    required this.capturedThemes,
    required this.width,
    required this.builder,
  });

  final Rect anchor;
  final TextDirection textDirection;
  @override
  final String barrierLabel;
  final CapturedThemes capturedThemes;
  final double width;
  final WidgetBuilder builder;

  static const _margin = 8.0;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      200.0,
      media.size.height - anchor.bottom - _margin - media.padding.bottom,
    );
    return capturedThemes.wrap(
      CustomSingleChildLayout(
        delegate: _PopoverLayout(
          anchor: anchor,
          textDirection: textDirection,
          margin: _margin,
        ),
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              elevation: 8,
              color: theme.popupMenuTheme.color ?? theme.colorScheme.surface,
              shape:
                  theme.popupMenuTheme.shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SurfaceRadius.menu),
                  ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(child: Builder(builder: builder)),
            ),
          ),
        ),
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
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        alignment: textDirection == TextDirection.rtl
            ? Alignment.topLeft
            : Alignment.topRight,
        scale: Tween(begin: 0.94, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}

/// Hangs the popover under its anchor, aligned to the anchor's end edge and
/// kept inside the screen.
class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout({
    required this.anchor,
    required this.textDirection,
    required this.margin,
  });

  final Rect anchor;
  final TextDirection textDirection;
  final double margin;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest).deflate(EdgeInsets.all(margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = textDirection == TextDirection.rtl
        ? anchor.left
        : anchor.right - childSize.width;
    final maxX = size.width - childSize.width - margin;
    final maxY = size.height - childSize.height - margin;
    return Offset(
      x.clamp(margin, math.max(margin, maxX)),
      anchor.bottom.clamp(margin, math.max(margin, maxY)),
    );
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      anchor != old.anchor || textDirection != old.textDirection;
}
