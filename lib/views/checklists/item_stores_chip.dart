import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/widgets/store_detail_dialog.dart';

/// An item's stores as one chip, so an item sold at several stores doesn't
/// fill its row: the store itself when there is one, a count otherwise.
class ItemStoresChip extends StatelessWidget {
  final List<Store> stores;

  const ItemStoresChip({super.key, required this.stores});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (stores.length == 1) {
      final store = stores.single;
      final color = parseHexColor(store.color) ?? cs.primary;
      return EntityChip(
        leading: Icon(storeIcon(store.icon), size: 12, color: color),
        label: store.name,
        textColor: color,
        background: color.withValues(alpha: 0.13),
        onTap: () => showStoreDetails(context, store),
      );
    }
    return EntityChip(
      leading: Icon(storeIcon(null), size: 12, color: cs.onSurfaceVariant),
      label: m.stores.count(stores.length),
      textColor: cs.onSurfaceVariant,
      background: cs.onSurface.withValues(alpha: 0.06),
      onTap: () => _showStores(context),
    );
  }

  Future<void> _showStores(BuildContext context) async {
    final picked = PlatformInfo.isDesktop
        ? await showDialog<Store>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text(m.stores.itemStoresTitle),
              children: [
                for (final s in stores)
                  _StoreRow(store: s, onTap: () => Navigator.pop(ctx, s)),
              ],
            ),
          )
        : await showModalBottomSheet<Store>(
            context: context,
            showDragHandle: true,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 8),
                    child: Text(
                      m.stores.itemStoresTitle,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final s in stores)
                          _StoreRow(
                            store: s,
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
    if (picked != null && context.mounted) {
      await showStoreDetails(context, picked);
    }
  }
}

class _StoreRow extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const _StoreRow({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        parseHexColor(store.color) ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.16),
        child: Icon(storeIcon(store.icon), size: 18, color: color),
      ),
      title: Text(store.name),
      onTap: onTap,
    );
  }
}
