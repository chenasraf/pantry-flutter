import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';

import 'checklists_controller.dart';
import 'form_components.dart';

/// Open the settings of inventory [list]: a dialog on desktop, a sheet on a
/// phone.
Future<void> showInventorySettings(
  BuildContext context,
  ChecklistsController controller,
  ChecklistList list,
) {
  final view = InventorySettingsView(controller: controller, list: list);
  if (PlatformInfo.isDesktopHost) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: view,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: view,
    ),
  );
}

class InventorySettingsView extends StatefulWidget {
  const InventorySettingsView({
    super.key,
    required this.controller,
    required this.list,
  });

  final ChecklistsController controller;
  final ChecklistList list;

  @override
  State<InventorySettingsView> createState() => _InventorySettingsViewState();
}

class _InventorySettingsViewState extends State<InventorySettingsView> {
  late final TextEditingController _name = TextEditingController(
    text: widget.list.name,
  );
  late final TextEditingController _days = TextEditingController(
    text: '${widget.list.expiryLeadDays ?? defaultExpiryLeadDays}',
  );

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  int? get _leadDays {
    final value = int.tryParse(_days.text.trim());
    if (value == null || value < 0 || value > 365) return null;
    return value;
  }

  bool get _valid => _name.text.trim().isNotEmpty && _leadDays != null;

  void _save() {
    if (!_valid) return;
    widget.controller.saveInventorySettings(
      widget.list,
      name: _name.text,
      expiryLeadDays: _leadDays!,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    // The sentence is translated whole; the number field sits where the
    // translation puts the marker.
    const marker = '\u0000';
    final sentence = m.stock.settings.warnBefore(marker).split(marker);
    final before = sentence.first;
    final after = sentence.length > 1 ? sentence.sublist(1).join() : '';

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(m.stock.settings.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          LabeledFieldCard(
            label: m.stock.settings.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  textDirection: detectTextDirection(_name.text),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Text(m.stock.settings.nameHint, style: hintStyle),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LabeledFieldCard(
            label: m.stock.settings.expiryWarning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (before.trim().isNotEmpty) Text(before),
                    SizedBox(
                      width: 56,
                      child: Semantics(
                        label: m.stock.settings.daysBefore,
                        child: TextField(
                          controller: _days,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    if (after.trim().isNotEmpty) Text(after),
                  ],
                ),
                const SizedBox(height: 6),
                Text(m.stock.settings.warnHint, style: hintStyle),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(m.stock.settings.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _valid ? _save : null,
                child: Text(m.stock.settings.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
