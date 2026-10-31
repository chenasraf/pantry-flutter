import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_put_away.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// The review's "Put away" card: where each item bought on the trip goes.
/// Every item starts where its tick restocked it; the user splits, moves or
/// drops storages, and the edited [draft] comes back through [onChanged].
class ShoppingPutAwaySection extends StatelessWidget {
  /// The items ticked on the trip, once each.
  final List<ListItem> items;
  final List<ChecklistList> inventories;
  final PutAwayDraft draft;
  final ValueChanged<PutAwayDraft> onChanged;

  const ShoppingPutAwaySection({
    super.key,
    required this.items,
    required this.inventories,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.kitchen_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  m.shopping.putAwayTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              m.shopping.putAwayHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            for (final item in items) ...[
              const Divider(height: 20),
              _PutAwayItem(
                item: item,
                inventories: inventories,
                storages: draft[item.id] ?? const [],
                onChanged: (storages) =>
                    onChanged({...draft, item.id: storages}),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PutAwayItem extends StatelessWidget {
  final ListItem item;
  final List<ChecklistList> inventories;
  final List<PutAwayStorage> storages;
  final ValueChanged<List<PutAwayStorage>> onChanged;

  const _PutAwayItem({
    required this.item,
    required this.inventories,
    required this.storages,
    required this.onChanged,
  });

  ChecklistList? _inventory(int listId) =>
      inventories.where((l) => l.id == listId).firstOrNull;

  /// A new storage takes what is left to put away, or the whole purchase
  /// again.
  void _add(int listId) {
    final left = amountLeft(item, storages);
    onChanged([
      ...storages,
      PutAwayStorage(
        listId: listId,
        amount: left > 0 ? left : amountLeft(item, const []),
      ),
    ]);
  }

  void _setAmount(int index, double? amount) => onChanged([
    for (var i = 0; i < storages.length; i++)
      i == index ? storages[i].withAmount(amount) : storages[i],
  ]);

  void _remove(int index) => onChanged([
    for (var i = 0; i < storages.length; i++)
      if (i != index) storages[i],
  ]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final used = {for (final s in storages) s.listId};
    final free = [
      for (final l in inventories)
        if (!used.contains(l.id)) l,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                textDirection: detectTextDirection(item.name),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item.quantity?.isNotEmpty ?? false)
              Text(
                item.quantity!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        for (var i = 0; i < storages.length; i++)
          _StorageRow(
            key: ValueKey('${item.id}:${storages[i].listId}'),
            itemName: item.name,
            inventory: _inventory(storages[i].listId),
            amount: storages[i].amount,
            onAmount: (amount) => _setAmount(i, amount),
            onRemove: () => _remove(i),
          ),
        if (storages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              m.shopping.notPutAway,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (free.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: m.shopping.putAwayAdd,
            onSelected: _add,
            itemBuilder: (_) => [
              for (final l in free)
                PopupMenuItem(
                  value: l.id,
                  child: Row(
                    children: [
                      Icon(
                        checklistIcon(l.icon),
                        size: 20,
                        color: parseHexColor(l.color) ?? cs.primary,
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(l.name)),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    m.shopping.putAwayAdd,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One inventory an item goes to, with the amount put there. An emptied field
/// fills the inventory item to its target; a 0 drops the storage once the
/// field is left.
class _StorageRow extends StatefulWidget {
  final String itemName;
  final ChecklistList? inventory;
  final double? amount;
  final ValueChanged<double?> onAmount;
  final VoidCallback onRemove;

  const _StorageRow({
    super.key,
    required this.itemName,
    required this.inventory,
    required this.amount,
    required this.onAmount,
    required this.onRemove,
  });

  @override
  State<_StorageRow> createState() => _StorageRowState();
}

class _StorageRowState extends State<_StorageRow> {
  late final TextEditingController _ctrl = TextEditingController(
    text: _format(widget.amount),
  );

  static String _format(double? amount) =>
      amount == null ? '' : formatNumber(amount);

  @override
  void didUpdateWidget(_StorageRow old) {
    super.didUpdateWidget(old);
    // Follow an amount set from outside the field, never one it just typed.
    if (widget.amount != old.amount && widget.amount != _typed) {
      _ctrl.text = _format(widget.amount);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// The typed amount, or null when the field is empty or holds no amount of
  /// 0 or more.
  double? get _typed {
    final value = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    return value == null || value < 0 ? null : value;
  }

  void _onChanged(String raw) {
    if (raw.trim().isEmpty) {
      widget.onAmount(null);
    } else if (_typed case final amount?) {
      widget.onAmount(amount);
    }
  }

  void _commit() {
    if (_typed == 0) widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = widget.inventory?.name ?? m.shopping.unknownInventory;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            checklistIcon(widget.inventory?.icon),
            size: 20,
            color: parseHexColor(widget.inventory?.color) ?? cs.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              textDirection: detectTextDirection(name),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Semantics(
              label: m.shopping.putAwayAmount(widget.itemName, name),
              child: TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: m.shopping.putAwayFull,
                ),
                onChanged: _onChanged,
                onTapOutside: (_) {
                  _commit();
                  FocusScope.of(context).unfocus();
                },
                onEditingComplete: _commit,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: m.shopping.putAwayRemove,
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
