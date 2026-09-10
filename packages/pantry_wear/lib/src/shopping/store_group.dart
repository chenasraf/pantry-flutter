import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/currencies.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../checklists/checklists_controller.dart';
import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'billed_amount_page.dart';

/// One shop as a review reads it: its name, what went in the basket there, and
/// the row that says — and takes — what its till charged.
///
/// Shared by the page that ends the trip and the one that leaves a shop, so a
/// till is asked for the same way whichever of them is asking.
void appendStoreGroup({
  required WearMetrics metrics,
  required List<FocusElement> elements,
  required Store? shop,
  required List<ListItem> items,
  required ({double? total, String? currency}) billed,
  required void Function(int index, VoidCallback action) tap,
  required VoidCallback onEditBilled,
}) {
  final name = shop?.name ?? m.shopping.anyStore;
  final tint = shop == null
      ? Colors.white54
      : parseHexColor(shop.color) ?? Colors.white54;

  elements.add(
    FocusElement(
      extent: metrics.headerExtent,
      snappable: false,
      isHeader: true,
      groupLabel: name,
      builder: (context, _) => _StoreHeader(
        label: name,
        icon: shop == null ? EntityIcons.store : storeIcon(shop.icon),
        tint: tint,
      ),
    ),
  );

  for (final item in items) {
    elements.add(
      FocusElement(
        extent: metrics.summaryLineExtent,
        snappable: false,
        isHeader: true,
        builder: (context, _) => _BoughtLine(item: item),
      ),
    );
  }

  // Captured before the row is added, so the tap guard is asked about the row
  // it is actually drawn on.
  final index = elements.length;
  elements.add(
    FocusElement(
      extent: metrics.itemExtent,
      builder: (context, d) => Padding(
        padding: EdgeInsetsDirectional.only(bottom: metrics.cardGap),
        child: WearRow(
          icon: EntityIcons.price,
          tint: tint,
          label: m.shopping.actualPaid,
          value: billedLabel(billed) ?? m.wear.notBilled,
          distance: d,
          onTap: () => tap(index, onEditBilled),
        ),
      ),
    ),
  );
}

/// A till's figure as it reads on the wrist, or null when it has none.
String? billedLabel(({double? total, String? currency}) billed) {
  final total = billed.total;
  if (total == null) return null;
  return CurrencyAmount(
    currency: billed.currency ?? defaultCurrency,
    amount: total,
  ).label;
}

/// Ask what a till charged and record the answer.
///
/// The figure is queued, so it is on screen before it is sent and survives the
/// relaunch a watch is always one moment from. Backing out of the field records
/// nothing, which is not the same as recording zero.
Future<void> askBilled(
  BuildContext context,
  ChecklistsController controller, {
  required int? storeId,
  required String storeName,
}) async {
  final billed = controller.billedFor(storeId);
  final entered = await Navigator.of(context).push<BilledAmount>(
    wearRoute<BilledAmount>(
      BilledAmountPage(
        storeName: storeName,
        total: billed.total,
        currency: billed.currency ?? controller.lastCurrency,
      ),
    ),
  );
  if (entered == null) return;
  controller.setBilled(
    storeId: storeId,
    total: entered.total,
    currency: entered.currency,
  );
}

/// The shop a run of bought lines came from, in the phone's own language: its
/// icon and name in its own colour over a hairline rule.
class _StoreHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tint;

  const _StoreHeader({
    required this.label,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: WearShape.isRound ? 22 : 16,
    ),
    child: Container(
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tint.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(label),
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One thing that went in the basket. Content passing through rather than a
/// target, so it is drawn as a line and not as a card.
class _BoughtLine extends StatelessWidget {
  final ListItem item;

  const _BoughtLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final quantity = item.quantity;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: WearShape.isRound ? 24 : 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(item.name),
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                color: Colors.white70,
              ),
            ),
          ),
          if (quantity != null) ...[
            const SizedBox(width: 6),
            Text(
              quantity,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: detectTextDirection(quantity),
              style: const TextStyle(
                fontSize: 11,
                height: 1.1,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
