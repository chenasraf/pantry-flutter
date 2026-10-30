import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/list_template.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/settings/settings_tiles.dart';

/// Whether template items this member draws fill their empty details from the
/// list's item defaults, overriding each list's own switch. A per-house pref,
/// so it reads and writes the house in view; it stays hidden until the
/// server answers, since a guess would show the wrong choice.
class FillFromItemDefaultsTile extends StatefulWidget {
  final int houseId;

  const FillFromItemDefaultsTile({super.key, required this.houseId});

  @override
  State<FillFromItemDefaultsTile> createState() =>
      _FillFromItemDefaultsTileState();
}

class _FillFromItemDefaultsTileState extends State<FillFromItemDefaultsTile> {
  FillFromItemDefaults? _value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await ChecklistService.instance.getFillFromItemDefaultsPref(
        widget.houseId,
      );
      if (mounted) setState(() => _value = value);
    } catch (e) {
      debugPrint('[FillFromItemDefaultsTile] Failed to load: $e');
    }
  }

  Future<void> _set(FillFromItemDefaults? value) async {
    final previous = _value;
    if (value == null || value == previous) return;
    setState(() => _value = value);
    try {
      await ChecklistService.instance.setFillFromItemDefaultsPref(
        widget.houseId,
        value,
      );
    } catch (e) {
      debugPrint('[FillFromItemDefaultsTile] Failed to save: $e');
      showAppToast(message: m.templates.fillPrefFailed, kind: ToastKind.error);
      if (mounted) setState(() => _value = previous);
    }
  }

  static String _label(FillFromItemDefaults value) => switch (value) {
    FillFromItemDefaults.list => m.templates.fillPrefNames.list,
    FillFromItemDefaults.always => m.templates.fillPrefNames.always,
    FillFromItemDefaults.never => m.templates.fillPrefNames.never,
  };

  @override
  Widget build(BuildContext context) {
    final value = _value;
    if (value == null) return const SizedBox.shrink();
    return DropdownSettingTile<FillFromItemDefaults>(
      icon: Icons.library_add_check_outlined,
      title: m.templates.fillPrefLabel,
      subtitle: m.templates.fillPrefHint,
      value: value,
      options: FillFromItemDefaults.values,
      labelOf: _label,
      onChanged: _set,
    );
  }
}
