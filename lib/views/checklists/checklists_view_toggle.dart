import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

class ChecklistsViewToggle extends StatelessWidget {
  final String view;
  final ValueChanged<String> onChanged;

  const ChecklistsViewToggle({
    super.key,
    required this.view,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _ViewToggleBtn(
            icon: Icons.format_list_bulleted,
            active: view == 'list',
            onTap: () => onChanged('list'),
            tooltip: m.checklists.viewList,
          ),
          _ViewToggleBtn(
            icon: Icons.grid_view,
            active: view == 'cards',
            onTap: () => onChanged('cards'),
            tooltip: m.checklists.viewCards,
          ),
        ],
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;

  const _ViewToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: active ? cs.onPrimary : cs.onSurfaceVariant,
            size: 16,
          ),
        ),
      ),
    );
  }
}
