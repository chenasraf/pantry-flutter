import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/theme/app_theme.dart';

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
    return Container(
      decoration: AppSurfaces.of(context).chip(),
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
    final surfaces = AppSurfaces.of(context);
    // Inset within the track, so its corners follow the track's at a smaller
    // radius.
    final radius = BorderRadius.circular(SurfaceRadius.chip - 2);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 30,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? surfaces.accent : Colors.transparent,
            borderRadius: radius,
          ),
          child: Icon(
            icon,
            color: active ? surfaces.onAccent : cs.onSurfaceVariant,
            size: 16,
          ),
        ),
      ),
    );
  }
}
