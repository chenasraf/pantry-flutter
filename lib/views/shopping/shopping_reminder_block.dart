import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/utils/text_direction.dart';

/// A non-blocking, inline block that surfaces the enabled reminders for one
/// moment (start / advance / close). Acknowledgement is **client-local only** —
/// ticking a reminder strikes it through for this render and never persists.
///
/// [reminders] must already be filtered to `enabled` and ordered by position;
/// the caller owns the filtering. [onManage] opens the reminders manager.
class ShoppingReminderBlock extends StatefulWidget {
  final List<ShoppingReminder> reminders;
  final VoidCallback? onManage;

  const ShoppingReminderBlock({
    super.key,
    required this.reminders,
    this.onManage,
  });

  @override
  State<ShoppingReminderBlock> createState() => _ShoppingReminderBlockState();
}

class _ShoppingReminderBlockState extends State<ShoppingReminderBlock> {
  final Set<int> _acked = {};

  @override
  Widget build(BuildContext context) {
    if (widget.reminders.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerHighest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_none, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.shopping.remindersTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (widget.onManage != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: m.shopping.manageReminders,
                    onPressed: widget.onManage,
                  ),
              ],
            ),
            for (final r in widget.reminders)
              _ReminderRow(
                text: r.text,
                acked: _acked.contains(r.id),
                onToggle: () => setState(() {
                  if (!_acked.remove(r.id)) _acked.add(r.id);
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String text;
  final bool acked;
  final VoidCallback onToggle;

  const _ReminderRow({
    required this.text,
    required this.acked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              acked ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: acked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                textDirection: detectTextDirection(text),
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: acked ? TextDecoration.lineThrough : null,
                  color: acked ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
