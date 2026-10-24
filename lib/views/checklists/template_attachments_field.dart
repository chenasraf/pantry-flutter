import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';

import 'checklists_controller.dart';

/// On a checklist or inventory: the templates whose items its add box
/// suggests. Templates attached to every list show in the hint, not as chips,
/// since they can't be detached here.
class ListTemplatesField extends StatelessWidget {
  final ChecklistsController controller;
  final List<int> templateIds;
  final List<int> everyListTemplateIds;
  final ValueChanged<List<int>> onChanged;

  const ListTemplatesField({
    super.key,
    required this.controller,
    required this.templateIds,
    required this.everyListTemplateIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      for (final t in controller.sortedListsOfKind(ListKind.template))
        if (t.id > 0) t,
    ];
    final everyListNames = [
      for (final t in templates)
        if (everyListTemplateIds.contains(t.id)) t.name,
    ].join(', ');
    return _AttachmentSection(
      label: m.templates.attachedLabel,
      hint: everyListNames.isEmpty
          ? m.templates.attachedHint
          : m.templates.attachedEveryListHint(everyListNames),
      placeholder: m.templates.attachedPlaceholder,
      options: [
        for (final t in templates)
          if (!everyListTemplateIds.contains(t.id)) (id: t.id, label: t.name),
      ],
      selected: templateIds,
      onChanged: onChanged,
    );
  }
}

/// On a template: the checklists and inventories whose add box suggests its
/// items, or every one of them.
class TemplateListsField extends StatelessWidget {
  final ChecklistsController controller;
  final TemplateLists value;
  final ValueChanged<TemplateLists> onChanged;

  const TemplateListsField({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Templates never attach to templates. Each option names its kind, since
    // a checklist and an inventory can share a name.
    final options = [
      for (final kind in [ListKind.checklist, ListKind.inventory])
        for (final l in controller.sortedListsOfKind(kind))
          if (l.id > 0)
            (
              id: l.id,
              label: m.templates.listWithKind(l.name, kind.strings.name),
            ),
    ];
    return _AttachmentSection(
      label: m.templates.suggestInLabel,
      hint: m.templates.suggestInHint,
      placeholder: m.templates.suggestInPlaceholder,
      leading: SwitchListTile(
        contentPadding: EdgeInsetsDirectional.zero,
        title: Text(m.templates.everyList),
        value: value.everyList,
        onChanged: (on) =>
            onChanged(TemplateLists(everyList: on, listIds: value.listIds)),
      ),
      options: value.everyList ? null : options,
      selected: value.listIds,
      onChanged: (ids) =>
          onChanged(TemplateLists(everyList: value.everyList, listIds: ids)),
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final String label;
  final String hint;
  final String placeholder;
  final Widget? leading;

  /// Null hides the chips.
  final List<({int id, String label})>? options;
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _AttachmentSection({
    required this.label,
    required this.hint,
    required this.placeholder,
    this.leading,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = this.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: cs.onSurfaceVariant,
          ),
        ),
        ?leading,
        if (options != null) ...[
          const SizedBox(height: 10),
          if (options.isEmpty)
            Text(placeholder, style: TextStyle(color: cs.onSurfaceVariant))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  FilterChip(
                    label: Text(o.label),
                    selected: selected.contains(o.id),
                    onSelected: (on) => onChanged([
                      for (final id in selected)
                        if (id != o.id) id,
                      if (on) o.id,
                    ]),
                  ),
              ],
            ),
        ],
        const SizedBox(height: 8),
        Text(hint, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
