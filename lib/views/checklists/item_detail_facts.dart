import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'package:pantry/utils/entity_icons.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/rrule.dart';

class FactTiles extends StatelessWidget {
  final ListItem item;
  final ItemLifecycle lifecycle;

  const FactTiles({super.key, required this.item, required this.lifecycle});

  @override
  Widget build(BuildContext context) {
    final v = m.checklists.viewItem;
    // IntrinsicHeight + CrossAxisAlignment.stretch makes both tiles match
    // the taller one's height. Plain `stretch` inside an unbounded sliver
    // would resolve to infinite child height and crash layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 10,
            child: _FactTile(
              label: v.quantityLabel,
              child: Text(
                item.quantity?.trim().isNotEmpty == true
                    ? item.quantity!.trim()
                    : '—',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 14,
            child: _FactTile(
              label: v.typeLabel,
              child: _TypeValue(item: item, lifecycle: lifecycle),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _FactTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class PriceTile extends StatelessWidget {
  final ListItem item;

  const PriceTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _FactTile(
      label: m.checklists.viewItem.priceLabel,
      child: Row(
        children: [
          Icon(EntityIcons.price, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              item.formattedPrice ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeValue extends StatelessWidget {
  final ListItem item;
  final ItemLifecycle lifecycle;

  const _TypeValue({required this.item, required this.lifecycle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = m.checklists.itemTypes;
    final String label;
    final String? sub;
    switch (lifecycle) {
      case ItemLifecycle.staple:
        label = t.staple;
        sub = t.stapleBody;
      case ItemLifecycle.once:
        label = t.onceTime;
        sub = t.onceTimeBody;
      case ItemLifecycle.recurring:
        label = t.recurring;
        sub = (item.rrule != null && item.rrule!.isNotEmpty)
            ? formatRrule(item.rrule!)
            : t.recurringBody;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (lifecycle == ItemLifecycle.recurring) ...[
              Icon(Icons.cached, size: 17, color: cs.primary),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
