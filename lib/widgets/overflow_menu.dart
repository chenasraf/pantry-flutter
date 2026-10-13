import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';

import '../theme/app_theme.dart';

/// One row in an AppBar overflow: a section [OverflowDivider] or
/// [OverflowHeader], a plain [OverflowAction], a toggle
/// [OverflowCheckboxAction], or one choice of a set [OverflowRadioAction].
sealed class OverflowEntry {
  const OverflowEntry();
}

class OverflowDivider extends OverflowEntry {
  const OverflowDivider();
}

/// A label naming the rows below it.
class OverflowHeader extends OverflowEntry {
  const OverflowHeader(this.label);

  final String label;
}

class OverflowAction extends OverflowEntry {
  const OverflowAction({
    required this.value,
    required this.icon,
    required this.label,
  });

  /// Dispatched to the overflow's `onSelected` when the row is tapped.
  final String value;
  final IconData icon;
  final String label;
}

class OverflowCheckboxAction extends OverflowEntry {
  const OverflowCheckboxAction({
    required this.value,
    required this.label,
    required this.checked,
  });

  /// Dispatched to the overflow's `onSelected` when the row is tapped.
  final String value;
  final String label;
  final bool checked;
}

class OverflowRadioAction extends OverflowEntry {
  const OverflowRadioAction({
    required this.value,
    required this.label,
    required this.selected,
  });

  /// Dispatched to the overflow's `onSelected` when the row is tapped.
  final String value;
  final String label;
  final bool selected;
}

/// The value an actionable row dispatches, or null for a divider or header.
String? overflowEntryValue(OverflowEntry entry) => switch (entry) {
  OverflowAction(:final value) => value,
  OverflowCheckboxAction(:final value) => value,
  OverflowRadioAction(:final value) => value,
  OverflowDivider() || OverflowHeader() => null,
};

/// Whether picking [entry] changes a setting in place rather than opening
/// something — a menu that can stay open keeps showing it.
bool overflowEntryIsToggle(OverflowEntry entry) =>
    entry is OverflowCheckboxAction || entry is OverflowRadioAction;

/// A named set of overflow rows: a tile in the grid menu, a labelled section in
/// the list menu, or a toolbar button on desktop.
class OverflowGroup {
  const OverflowGroup({
    required this.id,
    required this.icon,
    required this.label,
    required this.entries,
  });

  final String id;
  final IconData icon;
  final String label;
  final List<OverflowEntry> entries;

  Iterable<OverflowEntry> get _rows =>
      entries.where((e) => e is! OverflowDivider && e is! OverflowHeader);

  bool get isEmpty => _rows.isEmpty;

  /// The group's only row, or null when it has several. A group holding one
  /// row acts on it directly instead of opening a page of one.
  OverflowEntry? get soleEntry {
    final rows = _rows.take(2).toList();
    return rows.length == 1 ? rows.single : null;
  }

  OverflowGroup normalized() => OverflowGroup(
    id: id,
    icon: icon,
    label: label,
    entries: normalizeOverflow(entries),
  );
}

/// Lays [groups] out as one labelled list. Each group of several rows gets a
/// header; runs of single-row groups share an unlabelled section.
List<OverflowEntry> flattenOverflowGroups(List<OverflowGroup> groups) {
  final out = <OverflowEntry>[];
  var inLooseRun = false;
  for (final group in groups) {
    if (group.isEmpty) continue;
    final sole = group.soleEntry;
    if (sole != null) {
      if (!inLooseRun) out.add(const OverflowDivider());
      out.add(sole);
      inLooseRun = true;
    } else {
      out
        ..add(const OverflowDivider())
        ..add(OverflowHeader(group.label))
        ..addAll(group.entries);
      inLooseRun = false;
    }
  }
  return normalizeOverflow(out);
}

/// Radio-style indicator used by the sort options in an AppBar overflow.
/// Hollow circle when unselected; filled accent circle with a check when
/// selected. Reads as a radio but matches the language of the list-item
/// checkbox.
class OverflowRadioIndicator extends StatelessWidget {
  final bool selected;

  const OverflowRadioIndicator({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final surfaces = AppSurfaces.of(context);
    return Container(
      width: 18,
      height: 18,
      decoration: selected
          ? surfaces.selectionDot()
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: surfaces.edge, width: 2),
            ),
      child: selected
          ? Icon(Icons.check, size: 12, color: surfaces.onAccent)
          : null,
    );
  }
}

/// Collapses consecutive dividers and strips leading/trailing ones so the
/// overflow never shows a stray or doubled separator — e.g. the divider below
/// a group whose rows are all gated off.
List<OverflowEntry> normalizeOverflow(List<OverflowEntry> entries) {
  final out = <OverflowEntry>[];
  for (final entry in entries) {
    if (entry is OverflowDivider &&
        (out.isEmpty || out.last is OverflowDivider)) {
      continue;
    }
    out.add(entry);
  }
  while (out.isNotEmpty && out.last is OverflowDivider) {
    out.removeLast();
  }
  return out;
}

/// Single source of truth for menu-row layout — guarantees that text in
/// every row sits at the same x offset regardless of whether its leading
/// is an icon, a radio indicator, a checkbox indicator, or nothing.
PopupMenuItem<String> overflowMenuRow({
  required String value,
  required Widget leading,
  required String label,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        SizedBox(width: 20, height: 20, child: Center(child: leading)),
        const SizedBox(width: 14),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

PopupMenuItem<String> overflowRadioRow({
  required String value,
  required String label,
  required bool selected,
}) => overflowMenuRow(
  value: value,
  leading: OverflowRadioIndicator(selected: selected),
  label: label,
);

/// Renders [entries] as anchored popup-menu rows for a desktop toolbar. The
/// bottom-sheet variant renders the same entries as [ListTile]s in
/// [showOverflowMenuSheet].
List<PopupMenuEntry<String>> overflowMenuItems(List<OverflowEntry> entries) {
  return [
    for (final entry in entries)
      switch (entry) {
        OverflowDivider() => const PopupMenuDivider(),
        OverflowHeader(:final label) => _PopupMenuHeader(label),
        OverflowRadioAction(:final value, :final label, :final selected) =>
          overflowRadioRow(value: value, label: label, selected: selected),
        OverflowAction(:final value, :final icon, :final label) =>
          overflowMenuRow(
            value: value,
            leading: Icon(icon, size: 20),
            label: label,
          ),
        OverflowCheckboxAction(:final value, :final label, :final checked) =>
          overflowMenuRow(
            value: value,
            leading: Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
            ),
            label: label,
          ),
      },
  ];
}

class _PopupMenuHeader extends PopupMenuEntry<String> {
  const _PopupMenuHeader(this.label);

  final String label;

  @override
  double get height => 32;

  @override
  bool represents(String? value) => false;

  @override
  State<_PopupMenuHeader> createState() => _PopupMenuHeaderState();
}

class _PopupMenuHeaderState extends State<_PopupMenuHeader> {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 2),
      child: OverflowHeaderLabel(widget.label),
    ),
  );
}

/// The text of an [OverflowHeader], shared by the popup menu and the sheet.
class OverflowHeaderLabel extends StatelessWidget {
  const OverflowHeaderLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Presents [entries] as a bottom sheet and resolves to the value of the row
/// the user picked, or null if they dismissed it.
///
/// A sheet rather than a popup menu: an overflow carrying view toggles, sort
/// choices and per-section actions reads and scrolls better on touch than a
/// tall anchored menu.
Future<String?> showOverflowMenuSheet(
  BuildContext context,
  List<OverflowEntry> entries,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      // Open sized to the content instead of the default ~half-height cap.
      // Estimate the natural height so a short menu stays short and a long
      // one grows (up to most of the screen) before it needs to scroll.
      const rowHeight = 56.0;
      const headerHeight = 34.0;
      const handleHeight = 30.0;
      final contentHeight =
          handleHeight +
          media.padding.bottom +
          entries.fold<double>(
            0,
            (h, e) =>
                h +
                switch (e) {
                  OverflowDivider() => 1.0,
                  OverflowHeader() => headerHeight,
                  _ => rowHeight,
                },
          );
      final available = media.size.height - media.padding.top;
      final fraction = (contentHeight / available).clamp(0.25, 0.9);
      // DraggableScrollableSheet ties the inner scroll to the sheet's own
      // drag: at the top of the list, a downward swipe drags the whole
      // sheet down (and dismisses it) rather than just overscrolling.
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: fraction,
        maxChildSize: fraction,
        minChildSize: (fraction - 0.2).clamp(0.15, fraction),
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: AppSurfaces.of(sheetContext).dragHandle(),
              ),
              for (final entry in entries)
                OverflowSheetRow(
                  entry: entry,
                  onTap: (value) => Navigator.of(sheetContext).pop(value),
                ),
              SizedBox(height: media.padding.bottom),
            ],
          ),
        ),
      );
    },
  );
}

/// One [OverflowEntry] as a touch-sized sheet row. [dense] tightens it for a
/// pointer-driven popover.
class OverflowSheetRow extends StatelessWidget {
  const OverflowSheetRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.dense = false,
  });

  final OverflowEntry entry;
  final ValueChanged<String> onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final density = dense ? VisualDensity.compact : null;
    ListTile tile(Widget leading, String label, String value) => ListTile(
      visualDensity: density,
      leading: SizedBox(width: 24, child: Center(child: leading)),
      title: Text(label),
      onTap: () => onTap(value),
    );
    return switch (entry) {
      OverflowDivider() => const Divider(height: 1),
      OverflowHeader(:final label) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: OverflowHeaderLabel(label),
        ),
      ),
      OverflowAction(:final value, :final icon, :final label) => tile(
        Icon(icon),
        label,
        value,
      ),
      OverflowCheckboxAction(:final value, :final label, :final checked) =>
        tile(
          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank),
          label,
          value,
        ),
      OverflowRadioAction(:final value, :final label, :final selected) => tile(
        OverflowRadioIndicator(selected: selected),
        label,
        value,
      ),
    };
  }
}

/// Presents the sort choices in a dialog — an overflow carrying all of them
/// inline gets long, so it shows a single "Sort: current" row that opens this.
/// Resolves to the chosen key, or null if the user dismissed it.
Future<String?> showOverflowSortDialog(
  BuildContext context, {
  required String title,
  required List<({String key, String label})> options,
  required String selected,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final o in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, o.key),
            child: Row(
              children: [
                OverflowRadioIndicator(selected: selected == o.key),
                const SizedBox(width: 14),
                Expanded(child: Text(o.label)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// AppBar overflow button: an anchored popup menu where there is room for one
/// and a pointer to aim it, a bottom sheet on touch.
class OverflowButton extends StatelessWidget {
  final List<OverflowEntry> entries;
  final ValueChanged<String> onSelected;

  const OverflowButton({
    super.key,
    required this.entries,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    if (PlatformInfo.isDesktop) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: m.common.more,
        onSelected: onSelected,
        itemBuilder: (_) => overflowMenuItems(entries),
      );
    }
    return IconButton(
      icon: const Icon(Icons.more_vert),
      tooltip: m.common.more,
      onPressed: () async {
        final selected = await showOverflowMenuSheet(context, entries);
        if (selected != null) onSelected(selected);
      },
    );
  }
}
