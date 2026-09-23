import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';

/// One row in an AppBar overflow: a section [OverflowDivider], a plain
/// [OverflowAction], or a toggle [OverflowCheckboxAction].
sealed class OverflowEntry {
  const OverflowEntry();
}

class OverflowDivider extends OverflowEntry {
  const OverflowDivider();
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

/// Radio-style indicator used by the sort options in an AppBar overflow.
/// Hollow circle when unselected; filled accent circle with a white check
/// when selected. Reads as a radio but matches the language of the list-item
/// checkbox.
class OverflowRadioIndicator extends StatelessWidget {
  final bool selected;

  const OverflowRadioIndicator({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: selected ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
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
      final cs = Theme.of(sheetContext).colorScheme;
      final media = MediaQuery.of(sheetContext);
      // Open sized to the content instead of the default ~half-height cap.
      // Estimate the natural height so a short menu stays short and a long
      // one grows (up to most of the screen) before it needs to scroll.
      const rowHeight = 56.0;
      const handleHeight = 30.0;
      final contentHeight =
          handleHeight +
          media.padding.bottom +
          entries.fold<double>(
            0,
            (h, e) => h + (e is OverflowDivider ? 1.0 : rowHeight),
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
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              for (final entry in entries)
                switch (entry) {
                  OverflowDivider() => const Divider(height: 1),
                  OverflowAction(:final value, :final icon, :final label) =>
                    ListTile(
                      leading: Icon(icon),
                      title: Text(label),
                      onTap: () => Navigator.of(sheetContext).pop(value),
                    ),
                  OverflowCheckboxAction(
                    :final value,
                    :final label,
                    :final checked,
                  ) =>
                    ListTile(
                      leading: Icon(
                        checked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      title: Text(label),
                      onTap: () => Navigator.of(sheetContext).pop(value),
                    ),
                },
              SizedBox(height: media.padding.bottom),
            ],
          ),
        ),
      );
    },
  );
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
