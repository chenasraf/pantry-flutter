import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/text_direction.dart';
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
        resetDone: _resetDone,
      );
      if (!mounted) return;
      widget.onDuplicated();
    } catch (_) {
      if (mounted) {
        showAppToast(
          message: m.checklists.duplicateListFailed,
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
                  m.checklists.duplicateListTitle,
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
            decoration: InputDecoration(
              labelText: m.checklists.listName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.copy_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    m.checklists.duplicateList,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
