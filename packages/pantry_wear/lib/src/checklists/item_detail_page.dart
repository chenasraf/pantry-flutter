import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../services/wear_host_service.dart';
import '../widgets/wear_mechanics.dart';
import 'checklists_controller.dart';

/// Read-only. The watch writes check-state and nothing else, so the actions
/// here are the two check verbs and a hand-off to the phone.
class ItemDetailPage extends StatefulWidget {
  final ListItem item;
  final ChecklistsController controller;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  /// The outcome of the last hand-off, shown in place of the button's own
  /// label — the watch has nowhere to put a toast that isn't over the content.
  String? _handoff;
  Timer? _handoffTimer;

  @override
  void dispose() {
    _handoffTimer?.cancel();
    super.dispose();
  }

  Future<void> _openOnPhone() async {
    final item = widget.item;
    final houseId = widget.controller.houseId;
    if (houseId == null) return;
    final opened = await WearHostService.instance.openOnPhone(
      'pantry://item/$houseId/${item.listId}/${item.id}',
    );
    if (!mounted) return;
    setState(() {
      _handoff = opened ? m.wear.openedOnPhone : m.wear.openOnPhoneFailed;
    });
    _handoffTimer?.cancel();
    _handoffTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _handoff = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    const neutral = Color(0xFFB6B6BE);
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      // Route (a) turns off the system dismiss app-wide, so a pushed route
      // that does not carry this strip has no way back at all.
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: ListView(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 11,
            vertical: 46,
          ),
          children: [
            Text(
              item.name,
              textAlign: TextAlign.center,
              textDirection: detectTextDirection(item.name),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
            if (item.quantity != null)
              _fact(
                m.settings.chipNames.quantity,
                value: EntityChip(textColor: neutral, label: item.quantity!),
              ),
            if (category != null)
              _fact(
                m.settings.chipNames.category,
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
              _fact(
                m.settings.chipNames.store,
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
              _fact(
                m.settings.chipNames.price,
                value: EntityChip(textColor: neutral, label: price),
              ),
            // A schedule, not a flag: "recurring" alone tells you nothing you
            // could act on, so the row carries what core already knows how to
            // say about the rule.
            _fact(
              m.wear.repeats,
              value: EntityChip(
                textColor: item.rrule != null ? scheme.primary : neutral,
                label: item.rrule != null
                    ? formatRrule(item.rrule!)
                    : m.settings.chipNames.oneTime,
                leading: Icon(
                  item.rrule != null ? Icons.repeat : Icons.looks_one_outlined,
                  size: 12,
                  color: item.rrule != null ? scheme.primary : neutral,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _button(
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
            if (inSession) ...[
              const SizedBox(height: 8),
              _button(
                icon: removed ? Icons.undo : Icons.block,
                label: removed ? m.shopping.restore : m.shopping.removeFromTrip,
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
            _button(
              icon: Icons.phone_android,
              label: _handoff ?? m.wear.openOnPhone,
              color: const Color(0xFF8A8A92),
              onTap: _openOnPhone,
            ),
          ],
        ),
      ),
    );
  }

  /// Label over value rather than beside it. A watch is too narrow to put a
  /// caption and an arbitrary-length value on one line — a recurrence summary
  /// alone can run to "Every week on Monday, Thursday" — so the value gets the
  /// full width and wraps into it.
  Widget _fact(String label, {required Widget value}) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.7,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Align(alignment: AlignmentDirectional.centerStart, child: value),
      ],
    ),
  );

  Widget _button({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                textDirection: detectTextDirection(label),
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
