import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/rrule.dart';

class RepeatButton extends StatelessWidget {
  final String? rrule;
  final VoidCallback onTap;

  const RepeatButton({super.key, required this.rrule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = rrule != null && rrule!.isNotEmpty;
    final summary = hasValue ? formatRrule(rrule!) : m.recurrence.notSet;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.event_repeat,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '${m.checklists.itemForm.repeat}: ',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
