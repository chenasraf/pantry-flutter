import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/nav_section.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class NavOrderView extends StatefulWidget {
  const NavOrderView({super.key});

  @override
  State<NavOrderView> createState() => _NavOrderViewState();
}

class _NavOrderViewState extends State<NavOrderView> {
  late List<NavSection> _order;

  @override
  void initState() {
    super.initState();
    _order = List.of(PrefsService.instance.navOrder);
  }

  String _label(NavSection s) => switch (s) {
    NavSection.checklists => m.nav.checklists,
    NavSection.photoBoard => m.nav.photoBoard,
    NavSection.notesWall => m.nav.notesWall,
  };

  IconData _icon(NavSection s) => switch (s) {
    NavSection.checklists => Icons.assignment_turned_in,
    NavSection.photoBoard => Icons.photo,
    NavSection.notesWall => Icons.insert_drive_file,
  };

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final item = _order.removeAt(oldIndex);
      _order.insert(adjusted, item);
    });
    await context.read<PrefsService>().setNavOrder(_order);
  }

  Future<void> _resetToDefault() async {
    setState(() => _order = List.of(kDefaultNavOrder));
    await context.read<PrefsService>().setNavOrder(_order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.navOrderTitle),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: Text(m.settings.navOrderReset),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
            child: Text(
              m.settings.navOrderBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _order.length,
              onReorder: _onReorder,
              itemBuilder: (context, i) {
                final s = _order[i];
                final isFirst = i == 0;
                return ListTile(
                  key: ValueKey(s.id),
                  leading: Icon(_icon(s)),
                  title: Text(_label(s)),
                  subtitle: isFirst
                      ? Text(
                          m.settings.navOrderDefaultHint,
                          style: TextStyle(color: theme.colorScheme.primary),
                        )
                      : null,
                  trailing: ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
