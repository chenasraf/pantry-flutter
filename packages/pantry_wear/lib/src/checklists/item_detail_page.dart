import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/models/list_link.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/stock_display.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../widgets/image_route.dart';
import '../widgets/preview_image.dart';
import '../widgets/preview_sizes.dart';
import '../widgets/wear_detail.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_scroll_indicator.dart';
import 'checklists_controller.dart';
import 'inventory_card.dart';
import 'item_image.dart';
import '../widgets/wear_surfaces.dart';

/// Read-only. The watch writes check-state and nothing else, so the actions
/// here are the two check verbs and a hand-off to the phone.
///
/// An inventory item has no check state: it shows its stock, expiry and link
/// instead, and the hand-off is its only action.
class ItemDetailPage extends StatelessWidget {
  final ListItem item;
  final ChecklistsController controller;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final houseId = controller.houseId;
    final scheme = Theme.of(context).colorScheme;
    const neutral = kDetailInk;
    final inSession = controller.mode == ChecklistMode.session;

    final category = controller.categoryOf(item);
    final store = controller.storeOf(item);
    final storeTint = parseHexColor(store?.color) ?? neutral;
    final resolved = resolveItemPrice(
      item.prices,
      controller.session?.activeStoreId,
    );
    final price = resolved == null
        ? null
        : formatPrice(
            priceType: resolved.priceType,
            priceMin: resolved.priceMin,
            priceMax: resolved.priceMax,
            priceCurrency: resolved.priceCurrency,
          );
    final removed = controller.removed.any((i) => i.id == item.id);
    final inventory = controller.listOf(item)?.kind == ListKind.inventory;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      // Route (a) turns off the system dismiss app-wide, so a pushed route
      // that does not carry this strip has no way back at all.
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: WearScrollIndicator(
          child: ListView(
            // Prose, so it takes the band rather than following the bezel the way
            // a row does: a line held to the widest part of the glass is shaved
            // everywhere else on it.
            padding: WearMetrics.bandInsets(context),
            children: [
              if (item.imageFileId != null && houseId != null) ...[
                _Thumbnail(item: item, houseId: houseId),
                const SizedBox(height: 12),
              ],
              Text(
                item.name,
                textAlign: TextAlign.center,
                textDirection: detectTextDirection(item.name),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((item.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description!,
                  textAlign: TextAlign.center,
                  textDirection: detectTextDirection(item.description!),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
              const SizedBox(height: 14),
              if (inventory) ..._stockFacts(context),
              if (item.quantity != null && !inventory)
                WearFact(
                  label: m.settings.chipNames.quantity,
                  value: EntityChip(textColor: neutral, label: item.quantity!),
                ),
              if (category != null)
                WearFact(
                  label: m.settings.chipNames.category,
                  value: EntityChip(
                    textColor: parseHexColor(category.color) ?? neutral,
                    label: category.name,
                    leading: Icon(
                      categoryIcon(category.icon),
                      size: 12,
                      color: parseHexColor(category.color) ?? neutral,
                    ),
                  ),
                ),
              if (store != null)
                WearFact(
                  label: m.settings.chipNames.store,
                  value: EntityChip(
                    textColor: storeTint,
                    label: store.name,
                    leading: Icon(
                      storeIcon(store.icon),
                      size: 12,
                      color: storeTint,
                    ),
                  ),
                ),
              if (price != null)
                WearFact(
                  label: m.settings.chipNames.price,
                  value: EntityChip(textColor: neutral, label: price),
                ),
              // A schedule, not a flag: "recurring" alone tells you nothing you
              // could act on, so the row carries what core already knows how to
              // say about the rule.
              if (!inventory) ...[
                WearFact(
                  label: m.wear.repeats,
                  value: EntityChip(
                    textColor: item.rrule != null ? scheme.primary : neutral,
                    label: item.rrule != null
                        ? formatRrule(item.rrule!)
                        : m.settings.chipNames.oneTime,
                    leading: Icon(
                      item.rrule != null
                          ? Icons.repeat
                          : Icons.looks_one_outlined,
                      size: 12,
                      color: item.rrule != null ? scheme.primary : neutral,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                WearDetailButton(
                  icon: item.done ? Icons.remove_done : Icons.check,
                  label: item.done ? m.wear.markUndone : m.wear.markDone,
                  color: scheme.primary,
                  onTap: () {
                    if (inSession) {
                      item.done
                          ? controller.uncheckItem(item)
                          : controller.checkItem(item);
                    } else {
                      controller.setDone(item, !item.done);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
              if (inSession) ...[
                const SizedBox(height: 8),
                WearDetailButton(
                  icon: removed ? Icons.undo : Icons.block,
                  label: removed
                      ? m.shopping.restore
                      : m.shopping.removeFromTrip,
                  color: const Color(0xFF8A8A92),
                  onTap: () {
                    removed
                        ? controller.unskipItem(item)
                        : controller.skipItem(item);
                    Navigator.of(context).pop();
                  },
                ),
              ],
              const SizedBox(height: 8),
              if (houseId != null)
                OpenOnPhoneButton(
                  url: ListLink.itemUri(
                    houseId,
                    item.listId,
                    item.id,
                  ).toString(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ItemDetailPage {
  /// The stock in full, where the row only had room for one chip: the amount,
  /// every status chip (Good until among them), the status and expiry lines,
  /// and how it reaches a shopping list.
  List<Widget> _stockFacts(BuildContext context) {
    const neutral = kDetailInk;
    final level = item.stockMode == StockMode.level;
    final restock = (item.quantity ?? '').trim();
    final levelName = stockLevelName(item.stockLevel ?? StockLevel.full);
    final amount = level
        ? (restock.isEmpty ? levelName : '$levelName · $restock')
        : stockAmountLabel(item);
    final line = stockStatusLine(
      item.stockFields,
      controller.listOf(item)?.expiryLeadDays ?? defaultExpiryLeadDays,
    );
    final lineTone = line.tone;
    final expiry = expirySummary(item);
    final chips = stockStatusChips(item);
    return [
      WearFact(
        label: m.stock.card.title,
        value: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EntityChip(textColor: Colors.white, label: amount),
            for (final chip in chips)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: EntityChip(
                  textColor: chip.tone == null
                      ? neutral
                      : stockToneInk(context, chip.tone!),
                  label: chip.label,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              line.text,
              textDirection: detectTextDirection(line.text),
              style: TextStyle(
                fontSize: 12,
                color: lineTone == null
                    ? Colors.white70
                    : stockToneInk(context, lineTone),
              ),
            ),
          ],
        ),
      ),
      if (expiry != null)
        WearFact(
          label: m.stock.expiry.title,
          value: Text(
            expiry,
            textDirection: detectTextDirection(expiry),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      WearFact(
        label: m.stock.links.caption,
        value: Text(
          stockLinkTooltip(item),
          textDirection: detectTextDirection(stockLinkTooltip(item)),
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    ];
  }
}

/// The item's photo, over what the page has to say about it.
///
/// Square and well short of the full width: it sits at the top of a scroll,
/// which on a round screen is the narrowest the glass gets, and a first
/// screenful that is all photo has buried the facts the wearer came for. A tap
/// gives it the whole screen, where the label on a bottle is finally readable.
class _Thumbnail extends StatelessWidget {
  final ListItem item;
  final int houseId;

  const _Thumbnail({required this.item, required this.houseId});

  static double _side(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.55;

  Widget _image(BuildContext context, int size, BoxFit fit) => ItemImage(
    item: item,
    houseId: houseId,
    size: size,
    fit: fit,
    unavailable: const ImageUnavailable(),
  );

  void _open(BuildContext context) {
    Navigator.of(context).push(
      wearRoute<void>(
        ImageRoute(
          image: (context, size) => _image(context, size, BoxFit.contain),
          cached: (context) =>
              WearPreviewSize.forWidth(context, _side(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final side = _side(context);
    return Center(
      child: GestureDetector(
        onTap: () => _open(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WearSurface.panelRadius),
          child: SizedBox.square(
            dimension: side,
            child: _image(
              context,
              WearPreviewSize.forWidth(context, side),
              BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
