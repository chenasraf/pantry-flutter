import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/shopping_undo.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// Asks before a finished trip is undone. Resolves to true only when the
/// shopper confirms.
Future<bool> confirmUndoTrip(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(m.shopping.undoTripTitle),
      content: Text(m.shopping.undoTripBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(m.shopping.undoTrip),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Lists the items an undo left alone, each with why.
Future<void> showUndoSkipped(
  BuildContext context,
  List<ShoppingUndoSkip> skipped,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(m.shopping.undoSkippedTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.shopping.undoSkippedBody),
            const SizedBox(height: 12),
            for (final skip in skipped) _SkippedLine(skip: skip),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(m.common.closeDialog),
        ),
      ],
    ),
  );
}

class _SkippedLine extends StatelessWidget {
  final ShoppingUndoSkip skip;

  const _SkippedLine({required this.skip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = skip.itemName ?? m.shopping.undoSkippedUnnamed;
    final reason = switch (skip.reason) {
      ShoppingUndoSkipReason.changed => m.shopping.undoSkippedChanged,
      ShoppingUndoSkipReason.gone => m.shopping.undoSkippedGone,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            textDirection: detectTextDirection(name),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
