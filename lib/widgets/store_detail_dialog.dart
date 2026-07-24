import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/utils/opening_hours.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/create_store_dialog.dart';

/// Opens the read-only store details dialog. If the user taps Edit and saves,
/// the updated [Store] is returned; otherwise the returned value is null.
Future<Store?> showStoreDetails(BuildContext context, Store store) {
  return showDialog<Store>(
    context: context,
    builder: (_) => StoreDetailDialog(store: store),
  );
}

class StoreDetailDialog extends StatelessWidget {
  final Store store;

  const StoreDetailDialog({super.key, required this.store});

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(store.color) ?? theme.colorScheme.primary;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(40),
            child: Icon(storeIcon(store.icon), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              store.name,
              textDirection: detectTextDirection(store.name),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: store.hasNoDetails
            ? Text(
                m.stores.noDetails,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _textRow(context, m.stores.location, store.location),
                  _hoursRow(context),
                  _textRow(context, m.stores.contact, store.contact),
                  _textRow(context, m.stores.responsible, store.responsible),
                  _textRow(context, m.stores.notes, store.notes),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(m.common.closeDialog),
        ),
        FilledButton(
          onPressed: () async {
            final updated = await showDialog<Store>(
              context: context,
              builder: (_) =>
                  CreateStoreDialog(houseId: store.houseId, existing: store),
            );
            if (updated != null && context.mounted) {
              Navigator.pop(context, updated);
            }
          },
          child: Text(m.stores.editAction),
        ),
      ],
    );
  }

  Widget _textRow(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value.trim(), textDirection: detectTextDirection(value)),
        ],
      ),
    );
  }

  Widget _hoursRow(BuildContext context) {
    final hours = store.openingHours;
    if (hours == null || hours.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final grouped = OpeningHoursDisplay.groupByDay(context, hours);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.stores.openingHours,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in grouped)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      OpeningHoursDisplay.weekdayName(context, entry.key),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value
                          .map(
                            (i) =>
                                '${OpeningHoursDisplay.formatTime(context, i.start)}–'
                                '${OpeningHoursDisplay.formatTime(context, i.end)}',
                          )
                          .join(', '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
