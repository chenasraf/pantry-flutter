import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/stock_display.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/utils/app_toast.dart';

import 'checklists_controller.dart';
import 'form_components.dart';
import 'item_picker_dialogs.dart';
import 'restock_feedback.dart';

/// What a member can do to an inventory item's link. Absent where they can't
/// edit it, which leaves the link state readable but inert.
class StockLinkActions {
  const StockLinkActions({
    required this.onUnlink,
    required this.onPick,
    required this.onSetAutoLink,
    required this.onLinkByHand,
    this.onAddToList,
  });

  final VoidCallback onUnlink;
  final ValueChanged<StockLinkRow> onPick;
  final ValueChanged<bool> onSetAutoLink;

  /// Opens the search over every checklist item the member can link to.
  final VoidCallback onLinkByHand;

  /// Adds the item to a checklist the member picks and links it there. Null
  /// when there is no checklist to add it to.
  final VoidCallback? onAddToList;
}

/// The link controls of [item] as the member in [controller] may use them.
StockLinkActions? stockLinkActionsFor(
  BuildContext context,
  ChecklistsController controller,
  ListItem item,
) {
  if (!controller.canLinkStock(item)) return null;
  final lists = controller.stockRowListsFor(item);
  return StockLinkActions(
    onUnlink: () => controller.unlinkStock(item),
    onPick: (row) => controller.linkStock(item, row),
    onSetAutoLink: (value) => controller.setAutoLink(item, value),
    onLinkByHand: () async {
      final row = await pickStockLinkTarget(
        context,
        (query) => controller.stockLinkTargets(item, query),
      );
      if (row != null) controller.linkStock(item, row);
    },
    onAddToList: lists.isEmpty
        ? null
        : () async {
            final id = await pickTargetList(
              context,
              title: m.stock.links.addToListTitle,
              lists: lists,
            );
            final checklist = lists.where((l) => l.id == id).firstOrNull;
            if (checklist == null) return;
            try {
              await controller.addStockRowAndLink(item, checklist);
            } catch (_) {
              showAppToast(
                message: m.stock.links.addToListFailed,
                kind: ToastKind.error,
              );
            }
          },
  );
}

/// The narrow row's link chip, or nothing when the item's link state is
/// unremarkable: unlinked, finding a row on its own.
class StockLinkChip extends StatelessWidget {
  const StockLinkChip({super.key, required this.item});

  final ListItem item;

  static bool showsFor(ListItem item) => switch (stockLinkStatusOf(item)) {
    StockLinkStatus.linked || StockLinkStatus.needsPick => true,
    StockLinkStatus.autoOff => item.needsStockRestock,
    StockLinkStatus.autoOn => false,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = m.stock.links;
    final link = item.stockLink;
    final Widget chip;
    switch (stockLinkStatusOf(item)) {
      case StockLinkStatus.linked:
        final color = parseHexColor(link!.listColor) ?? cs.primary;
        chip = EntityChip(
          leading: Icon(Icons.link, size: 13, color: color),
          label: link.listName,
          textColor: color,
        );
      case StockLinkStatus.needsPick:
        final warning = AppSurfaces.of(context).warning;
        chip = EntityChip(
          leading: Icon(Icons.error_outline, size: 13, color: warning),
          label: l.chipNeedsPick(item.linkCandidates.length),
          textColor: warning,
        );
      case StockLinkStatus.autoOff:
      case StockLinkStatus.autoOn:
        chip = EntityChip(
          leading: Icon(Icons.link_off, size: 13, color: cs.onSurfaceVariant),
          label: l.chipNotAdded,
          textColor: cs.onSurfaceVariant,
          background: cs.onSurface.withValues(alpha: 0.06),
        );
    }
    return Tooltip(message: stockLinkTooltip(item), child: chip);
  }
}

/// The wide row's link button: its icon and colour say how the item reaches
/// a shopping list, and it opens what can be done about it.
class StockLinkButton extends StatelessWidget {
  const StockLinkButton({super.key, required this.item, this.actions});

  final ListItem item;
  final StockLinkActions? actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = stockLinkStatusOf(item);
    final (icon, color) = switch (status) {
      StockLinkStatus.linked => (Icons.link, cs.primary),
      StockLinkStatus.needsPick => (
        Icons.error_outline,
        AppSurfaces.of(context).warning,
      ),
      StockLinkStatus.autoOn => (Icons.link, cs.onSurfaceVariant),
      StockLinkStatus.autoOff => (Icons.link_off, cs.onSurfaceVariant),
    };
    final tooltip = stockLinkTooltip(item);
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: _menu(context),
      builder: (context, menu, _) => IconButton(
        icon: Icon(icon, size: 20, color: color),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }

  List<Widget> _menu(BuildContext context) {
    final theme = Theme.of(context);
    final l = m.stock.links;
    final actions = this.actions;
    final link = item.stockLink;
    Widget caption(String text) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
    return [
      caption(l.caption),
      if (link != null) ...[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 8),
            child: _LinkedRowText(row: link),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.link_off, size: 18),
          onPressed: actions?.onUnlink,
          child: Text(l.unlink),
        ),
      ] else ...[
        if (item.linkCandidates.isNotEmpty) ...[
          caption(l.whichOne),
          for (final row in item.linkCandidates)
            MenuItemButton(
              leadingIcon: const Icon(Icons.add_link, size: 18),
              onPressed: actions == null ? null : () => actions.onPick(row),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  l.candidate(row.name, row.listName, stockLinkStateText(row)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
        MenuItemButton(
          closeOnActivate: false,
          onPressed: actions == null
              ? null
              : () => actions.onSetAutoLink(!(item.autoLink ?? true)),
          trailingIcon: IgnorePointer(
            child: Switch(
              value: item.autoLink ?? true,
              onChanged: actions == null ? null : (_) {},
            ),
          ),
          child: Text(l.autoLink),
        ),
      ],
      const Divider(height: 8),
      MenuItemButton(
        leadingIcon: const Icon(Icons.search, size: 18),
        onPressed: actions?.onLinkByHand,
        child: Text(l.linkByHand),
      ),
    ];
  }
}

/// "**Eggs** on Groceries · × 4".
class _LinkedRowText extends StatelessWidget {
  const _LinkedRowText({required this.row, this.prefix = false});

  final StockLinkRow row;

  /// Starts it "Linked to …".
  final bool prefix;

  @override
  Widget build(BuildContext context) {
    final l = m.stock.links;
    final state = stockLinkStateText(row);
    final text = prefix
        ? l.cardLinked(row.name, row.listName, state)
        : l.rowOnList(row.name, row.listName, state);
    // The row's name is bolded where the translation put it.
    final at = text.indexOf(row.name);
    final style = Theme.of(context).textTheme.bodyMedium;
    return Text.rich(
      at < 0
          ? TextSpan(text: text)
          : TextSpan(
              children: [
                TextSpan(text: text.substring(0, at)),
                TextSpan(
                  text: row.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text.substring(at + row.name.length)),
              ],
            ),
      style: style,
      textDirection: detectTextDirection(text),
    );
  }
}

/// The item dialog's Shopping list card: what an inventory item is linked to
/// and the controls to change it, at every width.
class StockLinkCard extends StatefulWidget {
  const StockLinkCard({
    super.key,
    required this.item,
    required this.restockChecklistName,
    this.actions,
  });

  final ListItem item;

  /// The inventory's restock checklist, when it has one.
  final String? restockChecklistName;
  final StockLinkActions? actions;

  @override
  State<StockLinkCard> createState() => _StockLinkCardState();
}

class _StockLinkCardState extends State<StockLinkCard> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final l = m.stock.links;
    final item = widget.item;
    final actions = widget.actions;
    final link = item.stockLink;

    final List<Widget> children;
    if (link != null) {
      children = [
        _LinkedRowText(row: link, prefix: true),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: actions?.onUnlink,
              icon: const Icon(Icons.link_off, size: 18),
              label: Text(l.unlink),
            ),
            TextButton(
              onPressed: actions?.onLinkByHand,
              child: Text(l.linkDifferent),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(l.linkedHint, style: hint),
      ];
    } else if (item.linkCandidates.isNotEmpty) {
      final warning = AppSurfaces.of(context).warning;
      final candidates = item.linkCandidates;
      final picked = candidates.any((r) => r.itemId == _picked)
          ? _picked
          : null;
      children = [
        // Material rather than a decorated box: the radio rows ink on it.
        Material(
          color: warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SurfaceRadius.chip),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.matchesQuestion(l.matches(candidates.length))),
                RadioGroup<int>(
                  groupValue: picked,
                  onChanged: (id) => setState(() => _picked = id),
                  child: Column(
                    children: [
                      for (final row in candidates)
                        RadioListTile<int>(
                          value: row.itemId,
                          enabled: actions != null,
                          contentPadding: EdgeInsetsDirectional.zero,
                          dense: true,
                          title: Text(
                            l.candidate(
                              row.name,
                              row.listName,
                              stockLinkStateText(row),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonal(
                    onPressed: actions == null || picked == null
                        ? null
                        : () => actions.onPick(
                            candidates.firstWhere((r) => r.itemId == picked),
                          ),
                    child: Text(l.link),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    } else {
      final auto = item.autoLink ?? true;
      final checklist = widget.restockChecklistName;
      children = [
        SwitchListTile(
          contentPadding: EdgeInsetsDirectional.zero,
          title: Text(l.autoLink),
          value: auto,
          onChanged: actions?.onSetAutoLink,
        ),
        Text(
          !auto
              ? l.autoHintOff
              : checklist == null
              ? l.autoHintNoChecklist
              : l.autoHintOn(item.name, checklist),
          style: hint,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: actions?.onLinkByHand,
              icon: const Icon(Icons.add_link, size: 18),
              label: Text(l.linkToItem),
            ),
            if (actions?.onAddToList case final onAddToList?)
              TextButton.icon(
                onPressed: onAddToList,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(l.addToList),
              ),
          ],
        ),
      ];
    }
    return LabeledFieldCard(
      label: l.caption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Asks for a checklist item to link to, searching with [search]. Null when
/// the member backs out.
Future<StockLinkRow?> pickStockLinkTarget(
  BuildContext context,
  Future<List<StockLinkRow>> Function(String query) search,
) => showDialog<StockLinkRow>(
  context: context,
  builder: (_) => _StockLinkPicker(search: search),
);

class _StockLinkPicker extends StatefulWidget {
  const _StockLinkPicker({required this.search});

  final Future<List<StockLinkRow>> Function(String query) search;

  @override
  State<_StockLinkPicker> createState() => _StockLinkPickerState();
}

class _StockLinkPickerState extends State<_StockLinkPicker> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<StockLinkRow> _rows = const [];
  bool _searching = true;
  bool _failed = false;

  /// Answers arrive out of order; only the latest search's counts.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _load);
    setState(() {});
  }

  Future<void> _load() async {
    final run = ++_run;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final rows = await widget.search(_query.text.trim());
      if (!mounted || run != _run) return;
      setState(() {
        _rows = rows;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || run != _run) return;
      setState(() {
        _rows = const [];
        _searching = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = m.stock.links;
    final Widget body;
    if (_searching && _rows.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l.pickerSearching, textAlign: TextAlign.center),
      );
    } else if (_failed || _rows.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _failed ? l.pickerFailed : l.pickerEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    } else {
      body = ListView.builder(
        shrinkWrap: true,
        itemCount: _rows.length,
        itemBuilder: (context, i) {
          final row = _rows[i];
          final archived = row.state == StockLinkState.archived;
          final label = l.pickerRow(row.name, row.listName);
          return ListTile(
            dense: true,
            leading: Icon(
              archived ? Icons.archive_outlined : Icons.checklist,
              size: 20,
              color: parseHexColor(row.listColor) ?? cs.onSurfaceVariant,
            ),
            title: Text(label, textDirection: detectTextDirection(label)),
            subtitle: archived ? Text(l.pickerArchived) : null,
            onTap: () => Navigator.of(context).pop(row),
          );
        },
      );
    }
    return AlertDialog(
      title: Text(l.pickerTitle),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              textDirection: detectTextDirection(_query.text),
              decoration: InputDecoration(
                labelText: l.pickerField,
                hintText: l.pickerSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 8),
            Flexible(child: body),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
