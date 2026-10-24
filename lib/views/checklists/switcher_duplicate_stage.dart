import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

class DuplicateListStage extends StatefulWidget {
  final ChecklistsController controller;
  final ChecklistList source;
  final VoidCallback onBack;
  final VoidCallback onDuplicated;

  const DuplicateListStage({
    super.key,
    required this.controller,
    required this.source,
    required this.onBack,
    required this.onDuplicated,
  });

  @override
  State<DuplicateListStage> createState() => _DuplicateListStageState();
}

class _DuplicateListStageState extends State<DuplicateListStage> {
  late final TextEditingController _nameCtrl;
  late TextDirection _nameDir;
  bool _resetDone = true;
  bool _saving = false;
  late ListKind _as = widget.source.kind;

  /// Done state only carries from a checklist into a checklist.
  bool get _offersResetDone =>
      widget.source.kind.isChecklist && _as.isChecklist;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: m.checklists.duplicateListName(widget.source.name),
    );
    _nameDir = detectTextDirection(_nameCtrl.text);
    _nameCtrl.addListener(() {
      final dir = detectTextDirection(_nameCtrl.text);
      if (dir != _nameDir) setState(() => _nameDir = dir);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.duplicateList(
        widget.source,
        name: name,
        resetDone: _offersResetDone && _resetDone,
        as: _as,
      );
      if (!mounted) return;
      widget.onDuplicated();
    } catch (_) {
      if (mounted) {
        showAppToast(
          message: ServerFeature.listKinds
              ? widget.source.kind.strings.duplicateFailed
              : m.checklists.duplicateListFailed,
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
    final kinds = widget.controller.duplicateKindsFor(widget.source);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Text(
                  ServerFeature.listKinds
                      ? widget.source.kind.strings.duplicateTitle
                      : m.checklists.duplicateListTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textDirection: _nameDir,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: m.checklists.listName),
          ),
          const SizedBox(height: 8),
          if (kinds.length > 1) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8, bottom: 4),
              child: Text(
                m.listKinds.duplicateAs,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            RadioGroup<ListKind>(
              groupValue: _as,
              onChanged: (v) => setState(() => _as = v ?? _as),
              child: Column(
                children: [
                  for (final kind in kinds)
                    RadioListTile<ListKind>(
                      value: kind,
                      title: Text(kind.strings.name),
                      dense: true,
                      contentPadding: EdgeInsetsDirectional.zero,
                    ),
                ],
              ),
            ),
          ],
          if (_offersResetDone)
            CheckboxListTile(
              value: _resetDone,
              onChanged: (v) => setState(() => _resetDone = v ?? true),
              title: Text(m.checklists.duplicateListResetDone),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsetsDirectional.zero,
            ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _saving ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: surfaces.primaryButton(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: surfaces.onAccent,
                      ),
                    )
                  else
                    Icon(
                      Icons.copy_outlined,
                      color: surfaces.onAccent,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    m.checklists.duplicateList,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: surfaces.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
