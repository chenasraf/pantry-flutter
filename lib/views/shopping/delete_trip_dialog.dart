import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';

/// Asks before a finished trip is permanently deleted. Resolves to true only
/// when the shopper confirms.
Future<bool> confirmDeleteTrip(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(m.shopping.deleteTripTitle),
      content: Text(m.shopping.deleteTripBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(m.common.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}
