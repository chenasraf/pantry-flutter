import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../scope/wear_scope.dart';
import '../widgets/wear_mechanics.dart';

/// Every list in the current house, plus the all-lists entry — which is a
/// selectable list here, exactly as on the phone, rather than a mode.
///
/// Archived and trashed lists cannot appear: `getLists` returns active lists
/// only, and the watch never calls the other two endpoints.
class ListSwitcherPage extends StatefulWidget {
  final List<ChecklistList> lists;
  final int? selectedId;

  const ListSwitcherPage({
    super.key,
    required this.lists,
    required this.selectedId,
  });

  @override
  State<ListSwitcherPage> createState() => _ListSwitcherPageState();
}

class _ListSwitcherPageState extends State<ListSwitcherPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(int id) async {
    await WearScope.instance.selectList(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: RotaryScrollable(
          controller: _controller,
          active: true,
          child: ListView(
            controller: _controller,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 44,
            ),
            children: [
              _row(
                scheme,
                id: kAllListsId,
                name: m.checklists.allLists,
                icon: allListsIcon,
                tint: Colors.white70,
              ),
              for (final list in widget.lists)
                _row(
                  scheme,
                  id: list.id,
                  name: list.name,
                  icon: checklistIcon(list.icon),
                  tint: parseHexColor(list.color) ?? Colors.white70,
                ),
              if (widget.lists.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: Text(
                    m.wear.noLists,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    ColorScheme scheme, {
    required int id,
    required String name,
    required IconData icon,
    required Color tint,
  }) {
    final selected = id == widget.selectedId;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _select(id),
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.18)
                : const Color(0xFF17171A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(name),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, size: 14, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
