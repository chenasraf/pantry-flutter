import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/views/checklists/inventory_row_parts.dart';
import 'package:pantry/views/onboarding/widgets/onboarding_how_to.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces inventories. The rows are drawn with the inventory's own status
/// mark, chips and gauge, so the colours a viewer learns here are the ones
/// their own inventory warns them in.
class InventoryOnboardingPage extends StatelessWidget {
  const InventoryOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.inventoryTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.inventoryBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const IgnorePointer(child: _MockInventory()),
          const SizedBox(height: 20),
          OnboardingHowTo(
            icon: Icons.playlist_add_check,
            text: ob.inventoryHow,
          ),
          const ServerRequirementNote(requiredVersion: '0.38.0'),
        ],
      ),
    );
  }
}

/// One of each thing an inventory says: running low, about to expire, and
/// fine.
class _MockInventory extends StatelessWidget {
  const _MockInventory();

  static ListItem _item(
    int id,
    String name, {
    required StockMode mode,
    String? quantity,
    String? target,
    String? reorderPoint,
    StockLevel? level,
    StockStatus status = StockStatus.ok,
    String? shortfall,
    ExpiryStatus expiry = ExpiryStatus.none,
    int? expiresAt,
  }) => ListItem(
    id: id,
    listId: 0,
    name: name,
    quantity: quantity,
    done: false,
    repeatFromCompletion: false,
    deleteOnDone: false,
    stockMode: mode,
    stockLevel: level,
    target: target,
    reorderPoint: reorderPoint,
    stockStatus: status,
    shortfall: shortfall,
    expiryStatus: expiry,
    expiresAt: expiresAt,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  );

  @override
  Widget build(BuildContext context) {
    final ob = m.onboarding;
    final items = [
      _item(
        1,
        ob.inventoryMockEggs,
        mode: StockMode.count,
        quantity: '3',
        target: '12',
        reorderPoint: '4',
        status: StockStatus.low,
        shortfall: '9',
      ),
      _item(
        2,
        ob.inventoryMockMilk,
        mode: StockMode.count,
        quantity: '2',
        target: '2',
        expiry: ExpiryStatus.expiring,
        expiresAt: todayEpoch(DateTime.now().add(const Duration(days: 1))),
      ),
      _item(
        3,
        ob.inventoryMockFlour,
        mode: StockMode.level,
        level: StockLevel.full,
      ),
    ];
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: AppSurfaces.of(context).card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            _MockRow(item: item),
          ],
        ],
      ),
    );
  }
}

class _MockRow extends StatelessWidget {
  final ListItem item;

  const _MockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = stockStatusChips(item);
    final level = item.stockLevel;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 12, 10),
      child: Row(
        children: [
          StockStatusIcon(
            item: item,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            hitHeight: 32,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  textDirection: detectTextDirection(item.name),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final spec in chips) StockStatusChip(spec: spec),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                StockGauge(item: item),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (level != null)
            Text(
              stockLevelName(level),
              style: theme.textTheme.labelLarge?.copyWith(
                color: stockToneColor(context, stockToneOf(item)),
              ),
            )
          else
            StockAmountChip(item: item),
        ],
      ),
    );
  }
}
